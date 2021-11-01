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

echo "Creating databases..."
rm create_demodb.sh
tee -a create_demodb.sh <<EOF
curl -v -k -L -u demo@redis.com:redislabs --location-trusted -H "Content-type:application/json" -d '{ "name": "RedisConnect-Target-db", "port": 12000, "memory_size": 1000000000, "type" : "redis", "replication": false, "module_list": [ {"module_args": "PARTITIONS AUTO", "module_id": "9f8e4b44fbd28838190dbee7935e964d", "module_name": "search", "semantic_version": "2.0.11"}, {"module_args": "", "module_id": "4942f870bcd96678dd92cd55ae5d2801", "module_name": "ReJSON", "semantic_version": "1.0.8"} ] }' https://localhost:9443/v1/bdbs
curl -v -k -L -u demo@redis.com:redislabs --location-trusted -H "Content-type:application/json" -d '{"name": "RedisConnect-JobConfig-Metrics-db", "type":"redis", "replication": false, "memory_size":1000000000, "port":12001, "module_list": [{"module_args": "", "module_id": "6715acd18978c330bb2fb3f4193f070c", "module_name": "timeseries", "semantic_version": "1.4.10"}]}' https://localhost:9443/v1/bdbs
EOF
sleep 20
sudo docker cp create_demodb.sh re-node1:/opt/create_demodb.sh
sudo docker exec --user root -it re-node1 bash -c "chmod 777 /opt/create_demodb.sh"
sudo docker exec -it re-node1 bash -c "/opt/create_demodb.sh"
echo ""

echo "Creating idx:emp index for search.."
sleep 10
sudo docker exec -it re-node1 bash -c "/opt/redislabs/bin/redis-cli -p 12000 ft.create idx:emp on hash prefix 1 'emp:' schema EmpNum numeric sortable FName text sortable LName text Job tag sortable Manager numeric HireDate text Salary numeric Commission numeric Department numeric"
sudo docker exec -it re-node1 bash -c "/opt/redislabs/bin/redis-cli -p 12000 ft.info idx:emp"
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
