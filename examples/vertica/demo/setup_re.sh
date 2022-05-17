#!/bin/bash
sudo docker kill re-node1;sudo docker rm re-node1;
sudo docker kill redisinsight;sudo docker rm redisinsight;
sudo docker kill grafana; sudo docker rm grafana;
# Uncomment this to pull the newer version of redislabs/redis docker image in case the latest tag has been upgraded
sudo docker rmi -f $(sudo docker images | grep redislabs | awk '{print $3}')
# Start 1 docker container sincce we can't do HA with vanilla docker instance. Use docker swarm, RE on VM's or RE's K8s operator to achieve HA, clustering etc.
echo "Starting Redis Enterprise as Docker containers..."
sudo docker run -d --cap-add sys_resource -h re-node1 --name re-node1 -p 18443:8443 -p 19443:9443 -p 14000-14005:12000-12005 -p 18070:8070 redislabs/redis:latest
# Create Redis Enterprise cluster
echo "Waiting for the servers to start..."
sleep 60
echo "Creating Redis Enterprise cluster..."
sudo docker exec -it --privileged re-node1 "/opt/redislabs/bin/rladmin" cluster create name re-cluster.local username demo@redis.com password redislabs
echo ""
# Test the cluster
sudo docker exec -it re-node1 bash -c "/opt/redislabs/bin/rladmin info cluster"

# Get the module info to be used for database creation
tee -a list_modules.sh <<EOF
curl -s -k -L -u demo@redis.com:redislabs --location-trusted -H "Content-Type: application/json" -X GET https://localhost:9443/v1/modules | python -c 'import sys, json; modules = json.load(sys.stdin);
modulelist = open("./module_list.txt", "a")
for i in modules:
     lines = i["display_name"], " ", i["module_name"], " ", i["uid"], " ", i["semantic_version"], "\n"
     modulelist.writelines(lines)
modulelist.close()'
EOF

sudo docker cp list_modules.sh re-node1:/opt/list_modules.sh
sudo docker exec --user root -it re-node1 bash -c "chmod 777 /opt/list_modules.sh"
sudo docker exec --user root -it re-node1 bash -c "/opt/list_modules.sh"

json_module_name=$(sudo docker exec --user root -it re-node1 bash -c "grep -i json /opt/module_list.txt | cut -d ' ' -f 2")
json_semantic_version=$(sudo docker exec --user root -it re-node1 bash -c "grep -i json /opt/module_list.txt | cut -d ' ' -f 4")
search_module_name=$(sudo docker exec --user root -it re-node1 bash -c "grep -i search /opt/module_list.txt | cut -d ' ' -f 3")
search_semantic_version=$(sudo docker exec --user root -it re-node1 bash -c "grep -i search /opt/module_list.txt | cut -d ' ' -f 5")
timeseries_module_name=$(sudo docker exec --user root -it re-node1 bash -c "grep -i timeseries /opt/module_list.txt | cut -d ' ' -f 2")
timeseries_semantic_version=$(sudo docker exec --user root -it re-node1 bash -c "grep -i timeseries /opt/module_list.txt | cut -d ' ' -f 4")

echo "Creating databases..."
tee -a create_demodb.sh <<EOF
curl -v -k -L -u demo@redis.com:redislabs --location-trusted -H "Content-type:application/json" -d '{ "name": "RedisConnect-Target-db", "port": 12000, "memory_size": 1000000000, "type" : "redis", "replication": false, "module_list": [ {"module_args": "PARTITIONS AUTO", "module_name": "$search_module_name", "semantic_version": "$search_semantic_version"}, {"module_args": "", "module_name": "$json_module_name", "semantic_version": "$json_semantic_version"} ] }' https://localhost:9443/v1/bdbs
curl -v -k -L -u demo@redis.com:redislabs --location-trusted -H "Content-type:application/json" -d '{"name": "RedisConnect-JobConfig-Metrics-db", "type":"redis", "replication": false, "memory_size":1000000000, "port":12001, "module_list": [{"module_args": "", "module_name": "$timeseries_module_name", "semantic_version": "$timeseries_semantic_version"} ] }' https://localhost:9443/v1/bdbs
EOF

sleep 20

sudo docker cp create_demodb.sh re-node1:/opt/create_demodb.sh
sudo docker exec --user root -it re-node1 bash -c "chmod 777 /opt/create_demodb.sh"
sudo docker exec --user root -it re-node1 bash -c "sed -i "s///g" /opt/create_demodb.sh"
sudo docker exec -it re-node1 bash -c "/opt/create_demodb.sh"
echo ""

echo Created RedisConnect-Target-db with
echo $search_module_name
echo $search_semantic_version
echo $json_module_name
echo $json_semantic_version
echo Created RedisConnect-JobConfig-Metrics-db with
echo $timeseries_module_name
echo $timeseries_semantic_version

echo "Creating idx:emp index for search.."
sleep 10
sudo docker exec -it re-node1 bash -c "/opt/redislabs/bin/redis-cli -p 12000 ft.create idx:emp on hash prefix 1 'employee_dimension:' schema employee_key numeric sortable"
sudo docker exec -it re-node1 bash -c "/opt/redislabs/bin/redis-cli -p 12000 ft.create idx:cust on hash prefix 1 'customer_dimension:' schema customer_key numeric sortable"
sudo docker exec -it re-node1 bash -c "/opt/redislabs/bin/redis-cli -p 12000 ft.info idx:emp"
sudo docker exec -it re-node1 bash -c "/opt/redislabs/bin/redis-cli -p 12000 ft.info idx:cust"
echo "Database port mappings per node. We are using mDNS so use the IP and exposed port to connect to the databases."
echo "node1:"
sudo docker port re-node1 | egrep "12000|12001"
echo "------- RLADMIN status -------"
sudo docker exec -it re-node1 bash -c "rladmin status"
echo ""
echo "You can open a browser and access Redis Enterprise Admin UI at https://127.0.0.1:18443 (replace localhost with your ip/host) with username=demo@redis.com and password=redislabs."
echo "To connect using RedisInsight or redis-cli, please use the exposed port from the node where master shard for the database resides."
echo "Creating RedisInsight in docker container.."
sudo docker run -d --name redisinsight -p 18001:8001 -v redisinsight:/db redislabs/redisinsight:latest
echo "Creating Grafana with redis-datasource in docker container.."
sudo docker run -d -p 3000:3000 --name=grafana -e "GF_INSTALL_PLUGINS=redis-datasource" grafana/grafana
echo "You can open a browser and access RedisInsight client UI at http://127.0.0.1:18001 (replace localhost with your ip/host) and add databases to monitor."
echo "Please visit, https://docs.redis.com/latest/ri/using-redisinsight/add-instance/ for steps to add these databases to RedisInsight."
echo "DISCLAIMER: This is best for local development or functional testing. Please see, https://docs.redis.com/latest/rs/getting-started/getting-started-docker"

# Cleanup
rm list_modules.sh
sudo docker exec --user root -it re-node1 bash -c "rm /opt/list_modules.sh"
sudo docker exec --user root -it re-node1 bash -c "rm /opt/module_list.txt"
rm create_demodb.sh
sudo docker exec --user root -it re-node1 bash -c "rm /opt/create_demodb.sh"
