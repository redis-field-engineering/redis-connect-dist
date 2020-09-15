#!/bin/bash
sudo docker kill re-node1;sudo docker rm re-node1;
sudo docker kill re-node2;sudo docker rm re-node2;
sudo docker kill re-node3;sudo docker rm re-node3;
# Start 3 docker containers. Each container is a node in the same network
echo "Starting Redis Enterprise as Docker containers..."
sudo docker run -d --cap-add sys_resource -h re-node1 --name re-node1 -p 18443:8443 -p 19443:9443 -p 14000-14005:12000-12005 -p 18070:8070 redislabs/redis:latest
sudo docker run -d --cap-add sys_resource -h re-node2 --name re-node2 -p 28443:8443 -p 29443:9443 -p 12010-12015:12000-12005 -p 28070:8070 redislabs/redis:latest
sudo docker run -d --cap-add sys_resource -h re-node3 --name re-node3 -p 38443:8443 -p 39443:9443 -p 12020-12025:12000-12005 -p 38070:8070 redislabs/redis:latest
# Create Redis Enterprise cluster
echo "Waiting for the servers to start..."
sleep 60
echo "Creating Redis Enterprise cluster and joining nodes..."
sudo docker exec -it --privileged re-node1 "/opt/redislabs/bin/rladmin" cluster create name cluster1.local username demo@redislabs.com password redislabs
sudo docker exec -it --privileged re-node2 "/opt/redislabs/bin/rladmin" cluster join nodes $(sudo docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' re-node1) username demo@redislabs.com password redislabs
sudo docker exec -it --privileged re-node3 "/opt/redislabs/bin/rladmin" cluster join nodes $(sudo docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' re-node1) username demo@redislabs.com password redislabs
# Test the cluster 
sudo docker exec -it re-node1 bash -c "/opt/redislabs/bin/rladmin status"
# Create a demo database
echo "Creating demo-db database..."
rm create_demodb.sh
tee -a create_demodb.sh <<EOF
curl -v -k -u demo@redislabs.com:redislabs -X POST https://localhost:9443/v1/bdbs -H Content-type:application/json -d '{ "name": "srcConnection", "port": 12000, "memory_size": 100000000, "type" : "redis", "replication": false}'
curl -v -k -u demo@redislabs.com:redislabs -X POST https://localhost:9443/v1/bdbs -H Content-type:application/json -d '{ "name": "jobConfigConnection", "port": 12001, "memory_size": 100000000, "type" : "redis", "replication": false}'
curl -k -L -u demo@redislabs.com:redislabs --location-trusted -X POST https://localhost:9443/v1/bdbs -H "Content-type:application/json" -d '{"name": "metricsConnection", "type":"redis", "memory_size":100000000, "port":12002, "module_list": [{"module_args": "", "module_id": "f3b681f2c740cf9af3bffd5eef302166", "module_name": "timeseries", "semantic_version": "1.2.7"}]}'
EOF
sudo docker cp create_demodb.sh re-node1:/opt/create_demodb.sh
sudo docker exec --user root -it re-node1 bash -c "chmod 777 /opt/create_demodb.sh"
sudo docker exec --user root -it re-node1 bash -c "/opt/create_demodb.sh"
#sudo docker exec -it re-node1 bash -c "redis-cli -h redis-12000.cluster1.local -p 12000 PING"
sudo docker exec -it re-node1 bash -c "rladmin status"
sudo docker port re-node1 | grep 12000
sudo docker port re-node2 | grep 12001
sudo docker port re-node3 | grep 12002
echo "Now open the browser and access Redis Enterprise Admin UI at https://127.0.0.1:18443 with username=demo@redislabs.com and password=redislabs."
