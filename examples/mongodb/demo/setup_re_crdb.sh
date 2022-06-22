#!/bin/bash

# Delete bridge networks if they already exist
sudo docker stop re-node1-cluster1 re-node1-cluster2 re-node1-cluster3 redisinsight grafana
sudo docker rm re-node1-cluster1 re-node1-cluster2 re-node1-cluster3 redisinsight grafana
sudo docker network rm network1 2>/dev/null
sudo docker network rm network2 2>/dev/null
sudo docker network rm network3 2>/dev/null

# shellcheck disable=SC2046
sudo docker rmi -f $(sudo docker images | grep redislabs | awk '{print $3}')

# Create new bridge networks
echo "Creating new subnets..."
sudo docker network create network1 --subnet=172.18.0.0/16 --gateway=172.18.0.1
sudo docker network create network2 --subnet=172.19.0.0/16 --gateway=172.19.0.1
sudo docker network create network3 --subnet=172.20.0.0/16 --gateway=172.20.0.1

# Add entries to /etc/hosts so A-A can work without DNS setup
cluster1=$(grep cluster1.local /etc/hosts | cut -d ' ' -f 2)
if [ ! -z "$cluster1" ]
then
   echo "cluster1.local entry exists in /etc/hosts. Skipping.."
else
   echo "Adding cluster1.local entry to /etc/hosts.."
   echo "172.18.0.2 cluster1.local" | sudo tee -a /etc/hosts
fi
cluster2=$(grep cluster2.local /etc/hosts | cut -d ' ' -f 2)
if [ ! -z "$cluster2" ]
then
   echo "cluster2.local entry exists in /etc/hosts. Skipping.."
else
   echo "Adding cluster2.local entry to /etc/hosts.."
   echo "172.19.0.2 cluster2.local" | sudo tee -a /etc/hosts
fi
cluster3=$(grep cluster3.local /etc/hosts | cut -d ' ' -f 2)
if [ ! -z "$cluster3" ]
then
   echo "cluster3.local entry exists in /etc/hosts. Skipping.."
else
   echo "Adding cluster3.local entry to /etc/hosts.."
   echo "172.20.0.2 cluster3.local" | sudo tee -a /etc/hosts
fi

# Start 3 sudo docker containers. Each container is a node in a separate network
echo "Starting Redis Enterprise as Docker containers..."
sudo docker run -d --cap-add sys_resource -h re-node1-cluster1 --name re-node1-cluster1 -p 8443:8443 -p 9443:9443 -p 14000:12000 -p 14001:12001 -p 8071:8070 --network=network1 --ip=172.18.0.2 redislabs/redis:latest
sudo docker run -d --cap-add sys_resource -h re-node1-cluster2 --name re-node1-cluster2 -p 8445:8443 -p 9445:9443 -p 14002:12000 -p 8072:8070 --network=network2 --ip=172.19.0.2 redislabs/redis:latest
sudo docker run -d --cap-add sys_resource -h re-node1-cluster3 --name re-node1-cluster3 -p 8447:8443 -p 9447:9443 -p 14004:12000 -p 8073:8070 --network=network3 --ip=172.20.0.2 redislabs/redis:latest

# Connect the networks
sudo docker network connect network2 re-node1-cluster1
sudo docker network connect network3 re-node1-cluster1
sudo docker network connect network1 re-node1-cluster2
sudo docker network connect network3 re-node1-cluster2
sudo docker network connect network1 re-node1-cluster3
sudo docker network connect network2 re-node1-cluster3

# Create 3 Redis Enterprise clusters - one for each network
echo "Waiting for the servers to start..."

sleep 60

echo "Creating clusters"
sudo docker exec -it re-node1-cluster1 /opt/redislabs/bin/rladmin cluster create name cluster1.local username demo@redis.com password redislabs
sudo docker exec -it re-node1-cluster2 /opt/redislabs/bin/rladmin cluster create name cluster2.local username demo@redis.com password redislabs
sudo docker exec -it re-node1-cluster3 /opt/redislabs/bin/rladmin cluster create name cluster3.local username demo@redis.com password redislabs

# Test the cluster
sudo docker exec -it re-node1-cluster1 bash -c "/opt/redislabs/bin/rladmin info cluster"

# Get the module info to be used for database creation
tee -a list_modules.sh <<EOF
curl -s -k -L -u demo@redis.com:redislabs --location-trusted -H "Content-Type: application/json" -X GET https://localhost:9443/v1/modules | python -c 'import sys, json; modules = json.load(sys.stdin);
modulelist = open("./module_list.txt", "a")
for i in modules:
     lines = i["display_name"], " ", i["module_name"], " ", i["uid"], " ", i["semantic_version"], "\n"
     modulelist.writelines(lines)
modulelist.close()'
EOF

sudo docker cp list_modules.sh re-node1-cluster1:/opt/list_modules.sh
sudo docker exec --user root -it re-node1-cluster1 bash -c "chmod 777 /opt/list_modules.sh"
sudo docker exec --user root -it re-node1-cluster1 bash -c "/opt/list_modules.sh"

json_module_name=$(sudo docker exec --user root -it re-node1-cluster1 bash -c "grep -i json /opt/module_list.txt | cut -d ' ' -f 2 | uniq")
json_semantic_version=$(sudo docker exec --user root -it re-node1-cluster1 bash -c "grep -i json /opt/module_list.txt | cut -d ' ' -f 4 | uniq")
search_module_name=$(sudo docker exec --user root -it re-node1-cluster1 bash -c "grep -i search /opt/module_list.txt | cut -d ' ' -f 3 | uniq")
search_semantic_version=$(sudo docker exec --user root -it re-node1-cluster1 bash -c "grep -i search /opt/module_list.txt | cut -d ' ' -f 5 | uniq")
timeseries_module_name=$(sudo docker exec --user root -it re-node1-cluster1 bash -c "grep -i timeseries /opt/module_list.txt | cut -d ' ' -f 2 | uniq")
timeseries_semantic_version=$(sudo docker exec --user root -it re-node1-cluster1 bash -c "grep -i timeseries /opt/module_list.txt | cut -d ' ' -f 4 | uniq")

echo "Creating databases..."
tee -a create_demodb.sh <<EOF
curl -v -k -L -u demo@redis.com:redislabs --location-trusted -H "Content-type:application/json" -d '{ "default_db_config": { "name": "Target", "port": 12000, "memory_size": 1024000000, "type" : "redis", "replication": false, "aof_policy": "appendfsync-every-sec", "snapshot_policy": [], "shards_count": 1, "shard_key_regex": [{"regex": ".*\\\\{(?<tag>.*)\\\\}.*"}, {"regex": "(?<tag>.*)"}], "module_list": [ {"module_args": "PARTITIONS AUTO", "module_name": "$search_module_name", "semantic_version": "$search_semantic_version"} ] }, "instances": [{"cluster": {"url": "https://cluster1.local:9443","credentials": {"username": "demo@redis.com", "password": "redislabs"}, "name": "cluster1.local"}, "compression": 6}, {"cluster": {"url": "https://cluster2.local:9443", "credentials": {"username": "demo@redis.com", "password": "redislabs"}, "name": "cluster2.local"}, "compression": 6}, {"cluster": {"url": "https://cluster3.local:9443", "credentials": {"username": "demo@redis.com", "password": "redislabs"}, "name": "cluster3.local"}, "compression": 6}], "name": "Target" }' https://localhost:9443/v1/crdbs
curl -v -k -L -u demo@redis.com:redislabs --location-trusted -H "Content-type:application/json" -d '{"name": "JobManager", "type":"redis", "replication": false, "memory_size": 1024000000, "port": 12001, "module_list": [{"module_args": "", "module_name": "$timeseries_module_name", "semantic_version": "$timeseries_semantic_version"} ] }' https://localhost:9443/v1/bdbs
EOF

sleep 20

sed -i "s///g" create_demodb.sh
sudo docker cp create_demodb.sh re-node1-cluster1:/opt/create_demodb.sh
sudo docker exec --user root -it re-node1-cluster1 bash -c "chmod 777 /opt/create_demodb.sh"
sudo docker exec -it re-node1-cluster1 bash -c "/opt/create_demodb.sh"
echo ""

echo "Database port mappings per node. We are using mDNS so use the IP and exposed port to connect to the databases."
echo "node1:"
sudo docker port re-node1-cluster1 | grep -E "12000|12001"
sudo docker port re-node1-cluster2 | grep -E "12000|12001"
sudo docker port re-node1-cluster3 | grep -E "12000|12001"
echo "------- RLADMIN status -------"
sleep 60
sudo docker exec -it re-node1-cluster1 bash -c "rladmin status"
echo ""
sudo docker exec -it re-node1-cluster1 bash -c "crdb-cli coordinate crdb-list"
echo ""
echo "You can open a browser and access Redis Enterprise Admin UI at https://127.0.0.1:8443 (replace localhost with your ip/host) with username=demo@redis.com and password=redislabs."
echo "To connect using RedisInsight or redis-cli, please use the exposed port from the node where master shard for the database resides."
echo "Creating RedisInsight in docker container.."
sudo docker run -d --name redisinsight -p 18001:8001 -v redisinsight:/db redislabs/redisinsight:latest
echo "Creating Grafana with redis-datasource in docker container.."
sudo docker run -d -p 3000:3000 --name=grafana -e "GF_INSTALL_PLUGINS=redis-datasource" grafana/grafana
echo ""
echo "Creating idx_emp index for search.."
sleep 60
sudo docker exec -it re-node1-cluster1 bash -c "/opt/redislabs/bin/redis-cli -p 12000 ft.create idx_emp on hash prefix 1 'emp:' schema empno numeric sortable fname text sortable lname text job tag sortable mgr numeric hiredate text sal numeric comm numeric dept numeric"
sudo docker exec -it re-node1-cluster2 bash -c "/opt/redislabs/bin/redis-cli -p 12000 ft.create idx_emp on hash prefix 1 'emp:' schema empno numeric sortable fname text sortable lname text job tag sortable mgr numeric hiredate text sal numeric comm numeric dept numeric"
sudo docker exec -it re-node1-cluster3 bash -c "/opt/redislabs/bin/redis-cli -p 12000 ft.create idx_emp on hash prefix 1 'emp:' schema empno numeric sortable fname text sortable lname text job tag sortable mgr numeric hiredate text sal numeric comm numeric dept numeric"
echo "You can open a browser and access RedisInsight client UI at http://127.0.0.1:18001 (replace localhost with your ip/host) and add databases to monitor."
echo "Please visit, https://docs.redis.com/latest/ri/using-redisinsight/add-instance/ for steps to add these databases to RedisInsight."
echo "DISCLAIMER: This is best for local development or functional testing. Please see, https://docs.redis.com/latest/rs/getting-started/getting-started-docker"

# Cleanup
rm list_modules.sh
sudo docker exec --user root -it re-node1-cluster1 bash -c "rm /opt/list_modules.sh"
sudo docker exec --user root -it re-node1-cluster1 bash -c "rm /opt/module_list.txt"
rm create_demodb.sh
sudo docker exec --user root -it re-node1-cluster1 bash -c "rm /opt/create_demodb.sh"

