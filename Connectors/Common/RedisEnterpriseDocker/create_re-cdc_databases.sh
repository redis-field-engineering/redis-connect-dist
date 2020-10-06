#!/bin/bash
sudo docker kill re-node1;sudo docker rm re-node1;
sudo docker kill re-node2;sudo docker rm re-node2;
sudo docker kill re-node3;sudo docker rm re-node3;
# Uncomment this to pull the newer version of redislabs/redis docker image in case the latest tag has been upgraded
#sudo docker rmi -f $(docker images | grep redislabs | awk '{print $3}')
# Start 3 docker containers. Each container is a node in the same network
echo "Starting Redis Enterprise as Docker containers..."
sudo docker run -d --cap-add sys_resource -h re-node1 --name re-node1 -p 18443:8443 -p 19443:9443 -p 14000-14005:12000-12005 -p 18070:8070 redislabs/redis:latest
sudo docker run -d --cap-add sys_resource -h re-node2 --name re-node2 -p 28443:8443 -p 29443:9443 -p 12010-12015:12000-12005 -p 28070:8070 redislabs/redis:latest
sudo docker run -d --cap-add sys_resource -h re-node3 --name re-node3 -p 38443:8443 -p 39443:9443 -p 12020-12025:12000-12005 -p 38070:8070 redislabs/redis:latest
# Create Redis Enterprise cluster
echo "Waiting for the servers to start..."
sleep 60
echo "Creating Redis Enterprise cluster and joining nodes..."
sudo docker exec -it --privileged re-node1 "/opt/redislabs/bin/rladmin" cluster create name re-cluster.local username demo@redislabs.com password redislabs
sudo docker exec -it --privileged re-node2 "/opt/redislabs/bin/rladmin" cluster join nodes $(sudo docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' re-node1) username demo@redislabs.com password redislabs
sudo docker exec -it --privileged re-node3 "/opt/redislabs/bin/rladmin" cluster join nodes $(sudo docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' re-node1) username demo@redislabs.com password redislabs
echo ""
# Test the cluster 
sudo docker exec -it re-node1 bash -c "/opt/redislabs/bin/rladmin info cluster"

echo "Creating databases..."
rm create_demodb.sh
tee -a create_demodb.sh <<EOF
curl -v -k -L -u demo@redislabs.com:redislabs --location-trusted -H Content-type:application/json -d '{ "name": "RedisCDC-Target-db", "port": 12000, "memory_size": 1000000000, "type" : "redis", "replication": false, "module_list": [ {"module_args": "PARTITIONS AUTO", "module_id": "f181a538611833224950c3d157bd89f9", "module_name": "search", "semantic_version": "2.2.0"} ] }' https://localhost:9443/v1/bdbs
curl -v -k -L -u demo@redislabs.com:redislabs --location-trusted -H "Content-type:application/json" -d '{"name": "RedisCDC-JobConfig-Metrics-db", "type":"redis", "replication": false, "memory_size":1000000000, "port":12001, "module_list": [{"module_args": "", "module_id": "f3b681f2c740cf9af3bffd5eef302166", "module_name": "timeseries", "semantic_version": "1.2.7"}]}' https://localhost:9443/v1/bdbs
EOF
sudo docker cp create_demodb.sh re-node1:/opt/create_demodb.sh
sudo docker exec --user root -it re-node1 bash -c "chmod 777 /opt/create_demodb.sh"
sudo docker exec -it re-node1 bash -c "/opt/create_demodb.sh"
echo ""

echo "Creating idx:emp index for search.."
sudo docker exec -it re-node1 bash -c "/opt/redislabs/bin/redis-cli -p 12000 ft.create idx:emp on hash prefix 1 'emp:' schema EmpNum numeric sortable FName text sortable LName text Job tag sortable Manager numeric HireDate text Salary numeric Commission numeric Department numeric"
sudo docker exec -it re-node1 bash -c "/opt/redislabs/bin/redis-cli -p 12000 ft.info idx:emp"
echo "Creating idx:cust index for search.."
sudo docker exec -it re-node1 bash -c "/opt/redislabs/bin/redis-cli -p 12000 FT.CREATE idx:cust on hash prefix 2 'customer:' 'customer1:' SCHEMA CustomerSince text LastName text CustomerId text Age numeric Email text Address text FirstName text"
sudo docker exec -it re-node1 bash -c "/opt/redislabs/bin/redis-cli -p 12000 ft.info idx:cust"
echo "Database port mappings per node. We are using mDNS so use the IP and exposed port to connect to the databases."
echo "node1:"
sudo docker port re-node1 | egrep "12000|12001"
echo "node2:"
sudo docker port re-node2 | egrep "12000|12001" 
echo "node3:"
sudo docker port re-node3 | egrep "12000|12001" 
echo "------- RLADMIN status -------"
sudo docker exec -it re-node1 bash -c "rladmin status"
echo ""
echo "Now open the browser and access Redis Enterprise Admin UI at https://127.0.0.1:18443 with username=demo@redislabs.com and password=redislabs."
echo "To connect using RedisInsight or redis-cli, please use the exposed port from the node where master shard for the database resides."
echo "DISCLAIMER: This is best for local development or functional testing. Please see, https://docs.redislabs.com/latest/rs/getting-started/getting-started-docker"
