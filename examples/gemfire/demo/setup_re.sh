#!/bin/bash

version="${1:-latest}"
platform="${2:-linux/amd64}"

container_name="re-node1-$version-$(hostname)"

# Start 1 docker container since we can't do HA with vanilla docker instance. Use docker swarm, RE on VM's or RE K8s operator to achieve HA, clustering etc.

echo "Starting Redis Enterprise as Docker containers..."
IS_RUNNING=$(docker ps --filter name="${container_name}" --format '{{.ID}}')
if [ -n "${IS_RUNNING}" ]; then
    echo "${container_name} is running. Stopping ${container_name} and removing container..."
    docker container stop "${container_name}"
    docker container rm "${container_name}"
else
    IS_STOPPED=$(docker ps -a --filter name="${container_name}" --format '{{.ID}}')
    if [ -n "${IS_STOPPED}" ]; then
        echo "${container_name} is stopped. Removing container..."
        docker container rm "${container_name}"
    fi
fi
docker run -d \
  --init \
  --platform "${platform}" \
  --cap-add sys_resource \
  --name "${container_name}" \
	-h "${container_name}" \
	-p 18443:8443 \
	-p 19443:9443 \
	-p 14000-14001:12000-12001 \
	-p 18070:8070 \
	redislabs/redis:"${version}"

while ! nc -vz localhost 18443 < /dev/null
do
  echo "$(date) - still trying"
  sleep 2
done
echo "$(date) - connected to admin ui port successfully"

while ! nc -vz localhost 19443 < /dev/null
do
  echo "$(date) - still trying"
  sleep 2
done
echo "$(date) - connected to rest api port successfully"

while ! nc -vz localhost 18070 < /dev/null
do
  echo "$(date) - still trying"
  sleep 2
done
echo "$(date) - connected to metrics exporter port successfully"

# Create Redis Enterprise cluster
echo "Waiting for the servers to start..."
sleep 120
echo "Creating Redis Enterprise cluster..."

tee -a ./create_cluster.sh <<EOF
/opt/redislabs/bin/rladmin cluster create name redis-connect-test-cluster.local username demo@redis.com password redislabs
EOF

chmod 777 create_cluster.sh
docker cp create_cluster.sh "${container_name}":/opt/create_cluster.sh
docker exec --user root "${container_name}" bash -c "/opt/create_cluster.sh > create_cluster.out"
sleep 60
docker cp "${container_name}":/opt/create_cluster.out .

if [ "$(grep -c "ok" ./create_cluster.out)" -eq 1 ]; then
  cat ./create_cluster.out
else
  echo "The output file does not contain the expected output"
fi

# Test the cluster. cluster info and nodes
curl -s -u demo@redis.com:redislabs -k https://localhost:19443/v1/bootstrap
curl -s -u demo@redis.com:redislabs -k https://localhost:19443/v1/nodes

# Get the module info to be used for database creation
tee -a ./list_modules.sh <<EOF
curl -s -k -L -u demo@redis.com:redislabs --location-trusted -H "Content-Type: application/json" -X GET https://localhost:9443/v1/modules | python -c 'import sys, json; modules = json.load(sys.stdin);
modulelist = open("./module_list.txt", "a")
for i in modules:
     lines = i["display_name"], " ", i["module_name"], " ", i["uid"], " ", i["semantic_version"], "\n"
     modulelist.writelines(lines)
modulelist.close()'
EOF

# Get the module info to be used for database creation
while [[ "$(curl -o ./modules -w ''%{http_code}'' -u demo@redis.com:redislabs -k https://localhost:19443/v1/modules)" != "200" ]]; do sleep 5; done
echo "Modules.." && cat ./modules

json_module_name=$(cat ./modules | grep -oE '"module_name":"[^"]*|"semantic_version":"[^"]*' | grep -iA1 json | cut -d '"' -f 4 | head -1)
json_semantic_version=$(cat ./modules | grep -oE '"module_name":"[^"]*|"semantic_version":"[^"]*' | grep -iA1 json | cut -d '"' -f 4 | tail -1)
search_module_name=$(cat ./modules | grep -oE '"module_name":"[^"]*|"semantic_version":"[^"]*' | grep -iA1 search | cut -d '"' -f 4 | head -1)
search_semantic_version=$(cat ./modules | grep -oE '"module_name":"[^"]*|"semantic_version":"[^"]*' | grep -iA1 search | cut -d '"' -f 4 | tail -1)
timeseries_module_name=$(cat ./modules | grep -oE '"module_name":"[^"]*|"semantic_version":"[^"]*' | grep -iA1 timeseries | cut -d '"' -f 4 | head -1)
timeseries_semantic_version=$(cat ./modules | grep -oE '"module_name":"[^"]*|"semantic_version":"[^"]*' | grep -iA1 timeseries | cut -d '"' -f 4 | tail -1)

echo "Creating databases..."
echo Creating Redis Target database with "${search_module_name}" version "${search_semantic_version}" and "${json_module_name}" version "${json_semantic_version}"
curl -s -k -L -u demo@redis.com:redislabs --location-trusted -H "Content-type:application/json" -d '{ "name": "Target", "port": 12000, "memory_size": 500000000, "type" : "redis", "replication": false, "default_user": true, "module_list": [ {"module_args": "PARTITIONS AUTO", "module_name": "'"$search_module_name"'", "semantic_version": "'"$search_semantic_version"'"}, {"module_args": "", "module_name": "'"$json_module_name"'", "semantic_version": "'"$json_semantic_version"'"} ] }' https://localhost:19443/v1/bdbs

echo Creating Redis JobManager database with "${timeseries_module_name}" version "${timeseries_semantic_version}"
curl -s -k -L -u demo@redis.com:redislabs --location-trusted -H "Content-type:application/json" -d '{"name": "JobManager", "type":"redis", "replication": false, "memory_size": 250000000, "port": 12001, "default_user": true, "module_list": [{"module_args": "", "module_name": "'"$timeseries_module_name"'", "semantic_version": "'"$timeseries_semantic_version"'"} ] }' https://localhost:19443/v1/bdbs

sleep 30

echo "Database port mappings per node. We are using mDNS so use the IP and exposed port to connect to the databases."
echo "node1:"
docker port "${container_name}" | grep -e "12000|12001"

echo "------- RLADMIN status -------"
docker exec "${container_name}" bash -c "rladmin status"
echo ""
echo "You can open a browser and access Redis Enterprise Admin UI at https://127.0.0.1:18443 (replace localhost with your ip/host) with username=demo@redis.com and password=redislabs."
echo "DISCLAIMER: This is best for local development or functional testing. Please see, https://docs.redis.com/latest/rs/getting-started/getting-started-docker"

# Cleanup
rm list_modules.sh create_cluster.* module_list.txt
docker exec --user root "${container_name}" bash -c "rm /opt/list_modules.sh"
docker exec --user root "${container_name}" bash -c "rm /opt/module_list.txt"
docker exec --user root "${container_name}" bash -c "rm /opt/create_cluster.*"

echo "done"