#!/bin/bash

# Delete bridge networks if they already exist
sudo docker stop rp1 rp2 rp3 redisinsight grafana
sudo docker rm rp1 rp2 rp3 redisinsight grafana
sudo docker network rm network1 2>/dev/null
sudo docker network rm network2 2>/dev/null
sudo docker network rm network3 2>/dev/null

# Create new bridge networks
echo "Creating new subnets..."
sudo docker network create network1 --subnet=172.18.0.0/16 --gateway=172.18.0.1
sudo docker network create network2 --subnet=172.19.0.0/16 --gateway=172.19.0.1
sudo docker network create network3 --subnet=172.20.0.0/16 --gateway=172.20.0.1

# Start 3 sudo docker containers. Each container is a node in a separate network
echo "Starting Redis Enterprise as Docker containers..."
sudo docker run -d --cap-add sys_resource -h rp1 --name rp1 -p 8443:8443 -p 9443:9443 -p 12000:12000 -p 12001:12001 --network=network1 --ip=172.18.0.2 redislabs/redis:latest
sudo docker run -d --cap-add sys_resource -h rp2 --name rp2 -p 8445:8443 -p 9445:9443 -p 12002:12000 --network=network2 --ip=172.19.0.2 redislabs/redis:latest
sudo docker run -d --cap-add sys_resource -h rp3 --name rp3 -p 8447:8443 -p 9447:9443 -p 12004:12000 --network=network3 --ip=172.20.0.2 redislabs/redis:latest

# Connect the networks
sudo docker network connect network2 rp1
sudo docker network connect network3 rp1
sudo docker network connect network1 rp2
sudo docker network connect network3 rp2
sudo docker network connect network1 rp3
sudo docker network connect network2 rp3

# Create 3 Redis Enterprise clusters - one for each network
echo "Waiting for the servers to start..."

sleep 60

echo "Creating clusters"
sudo docker exec -it rp1 /opt/redislabs/bin/rladmin cluster create name cluster1.local username demo@redislabs.com password redislabs
sudo docker exec -it rp2 /opt/redislabs/bin/rladmin cluster create name cluster2.local username demo@redislabs.com password redislabs
sudo docker exec -it rp3 /opt/redislabs/bin/rladmin cluster create name cluster3.local username demo@redislabs.com password redislabs


# Create the CRDB
echo "Creating a CRDB"
echo ""
# Test the cluster
sudo docker exec -it rp1 bash -c "/opt/redislabs/bin/rladmin info cluster"

echo "Creating databases..."
rm create_demodb.sh
sudo docker cp target_crdb.json rp1:/opt/target_crdb.json
sudo docker cp config_bdb.json rp1:/opt/config_bdb.json
tee -a create_demodb.sh <<EOF
curl -v -L -u demo@redislabs.com:redislabs --location-trusted -H Content-type:application/json -d @target_crdb.json -k https://localhost:9443/v1/crdbs
curl -v -L -u demo@redislabs.com:redislabs --location-trusted -H "Content-type:application/json" -d @config_bdb.json -k https://localhost:9443/v1/bdbs
EOF
sudo docker cp create_demodb.sh rp1:/opt/create_demodb.sh
sudo docker exec --user root -it rp1 bash -c "chmod 777 /opt/create_demodb.sh"
sudo docker exec -it rp1 bash -c "/opt/create_demodb.sh"

echo "Database port mappings per node. We are using mDNS so use the IP and exposed port to connect to the databases."
echo "node1:"
sudo docker port rp1 | egrep "12000|12001"
sudo docker port rp2 | egrep "12000|12001"
sudo docker port rp3 | egrep "12000|12001"
echo "------- RLADMIN status -------"
sleep 60
sudo docker exec -it rp1 bash -c "rladmin status"
echo ""
echo "You can open a browser and access Redis Enterprise Admin UI at https://127.0.0.1:8443 (replace localhost with your ip/host) with username=demo@redislabs.com and password=redislabs."
echo "To connect using RedisInsight or redis-cli, please use the exposed port from the node where master shard for the database resides."
echo "Creating RedisInsight in docker container.."
sudo docker run -d --name redisinsight -p 18001:8001 -v redisinsight:/db redislabs/redisinsight:latest
echo "Creating Grafana with redis-datasource in docker container.."
sudo docker run -d -p 3000:3000 --name=grafana -e "GF_INSTALL_PLUGINS=redis-datasource" grafana/grafana
echo ""
echo "Creating idx:emp index for search.."
sleep 60
sudo docker exec -it rp1 bash -c "/opt/redislabs/bin/redis-cli -p 12000 ft.create idx:emp on hash prefix 1 'emp:' schema EmpNum numeric sortable FName text sortable LName text Job tag sortable Manager numeric HireDate text Salary numeric Commission numeric Department numeric"
sudo docker exec -it rp2 bash -c "/opt/redislabs/bin/redis-cli -p 12000 ft.create idx:emp on hash prefix 1 'emp:' schema EmpNum numeric sortable FName text sortable LName text Job tag sortable Manager numeric HireDate text Salary numeric Commission numeric Department numeric"
sudo docker exec -it rp3 bash -c "/opt/redislabs/bin/redis-cli -p 12000 ft.create idx:emp on hash prefix 1 'emp:' schema EmpNum numeric sortable FName text sortable LName text Job tag sortable Manager numeric HireDate text Salary numeric Commission numeric Department numeric"
echo "You can open a browser and access RedisInsight client UI at http://127.0.0.1:18001 (replace localhost with your ip/host) and add databases to monitor."
echo "Please visit, https://docs.redislabs.com/latest/ri/using-redisinsight/add-instance/ for steps to add these databases to RedisInsight."
echo "DISCLAIMER: This is best for local development or functional testing. Please see, https://docs.redislabs.com/latest/rs/getting-started/getting-started-docker"
