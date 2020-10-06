#!/bin/bash
echo ""
# Test the cluster 
rm create_demodb.sh
sudo docker exec -it re-node1 bash -c "/opt/redislabs/bin/rladmin status"
export db=$(sudo docker exec -it re-node1 bash -c "rladmin info db | grep RedisCDC-Target-db")
db=$(echo $db | awk '{print $1}' | awk -F: '{print $2}')
echo "Recreating database $db with RedisGears Module."
tee -a create_demodb.sh <<EOF
curl -X DELETE https://localhost:9443/v1/bdbs/$db -H 'Content-Type: application/json' -u demo@redislabs.com:redislabs -k
sleep 15
curl -v -k -L -u demo@redislabs.com:redislabs --location-trusted -H Content-type:application/json -d '{ "name": "RedisCDC-Target-db", "port": 12000, "memory_size": 1000000000, "type" : "redis", "replication": false, "module_list": [ {"module_args": "PARTITIONS AUTO", "module_id": "f181a538611833224950c3d157bd89f9", "module_name": "search", "semantic_version": "2.2.0"}, {"module_args": "CreateVenv 1 DownloadDeps 0", "module_id": "984757126a4d53a6779bfee6095564cb", "module_name": "rg", "semantic_version": "1.0.1"} ] }' https://localhost:9443/v1/bdbs
EOF
sudo docker cp create_demodb.sh re-node1:/opt/create_demodb.sh
sudo docker exec --user root -it re-node1 bash -c "chmod 777 /opt/create_demodb.sh"
sudo docker exec -it re-node1 bash -c "/opt/create_demodb.sh"
echo ""

echo "Database port mappings per node. We are using mDNS so use the IP and exposed port to connect to the databases."
echo "node1:"
sudo docker port re-node1 | grep "12000"
echo "node2:"
sudo docker port re-node2 | grep "12000" 
echo "node3:"
sudo docker port re-node3 | grep "12000" 
echo "Creating idx:emp index for search.."
sleep 10
sudo docker exec -it re-node1 bash -c "/opt/redislabs/bin/redis-cli -p 12000 ft.create idx:emp on hash prefix 1 'emp:' schema EmpNum numeric sortable FName text sortable LName text Job tag sortable Manager numeric HireDate text Salary numeric Commission numeric Department numeric"
sudo docker exec -it re-node1 bash -c "/opt/redislabs/bin/redis-cli -p 12000 ft.info idx:emp"
echo "Creating idx:cust index for search.."
sudo docker exec -it re-node1 bash -c "/opt/redislabs/bin/redis-cli -p 12000 FT.CREATE idx:cust on hash prefix 2 'customer:' 'customer1:' SCHEMA CustomerSince text LastName text CustomerId text Age numeric Email text Address text FirstName text"
sudo docker exec -it re-node1 bash -c "/opt/redislabs/bin/redis-cli -p 12000 ft.info idx:cust"
sudo docker exec -it re-node1 bash -c "redis-cli -p 12000 RG.PYEXECUTE 'GearsBuilder().run()'"
echo "------- RLADMIN status -------"
sudo docker exec -it re-node1 bash -c "rladmin info db"
echo ""
echo "Now open the browser and access Redis Enterprise Admin UI at https://127.0.0.1:18443 with username=demo@redislabs.com and password=redislabs."
echo "To connect using RedisInsight or redis-cli, please use the exposed port from the node where master shard for the database resides."
echo "DISCLAIMER: This is best for local development or functional testing. Please see, https://docs.redislabs.com/latest/rs/getting-started/getting-started-docker"
