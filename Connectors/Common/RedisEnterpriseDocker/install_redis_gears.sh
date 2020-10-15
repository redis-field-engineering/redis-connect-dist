#!/bin/bash
echo ""
# Test the cluster 
sudo docker exec -it re-node1 bash -c "/opt/redislabs/bin/rladmin info cluster"
# Install wget to download RedisGears components
echo "Installing RedisGears and it's prerequisites..."
sudo docker exec --user root -it re-node1 bash -c "apt-get install -y wget"
sudo docker exec --user root -it re-node2 bash -c "apt-get install -y wget"
sudo docker exec --user root -it re-node3 bash -c "apt-get install -y wget"
rm install_gears.sh
tee -a install_gears.sh <<EOF
wget http://redismodules.s3.amazonaws.com/redisgears/redisgears.linux-bionic-x64.1.0.2.zip
wget http://redismodules.s3.amazonaws.com/redisgears/redisgears-dependencies.linux-bionic-x64.1.0.2.tgz
wget http://redismodules.s3.amazonaws.com/rgsync/rgsync-1.0.1.linux-bionic-x64.zip

mkdir -p /var/opt/redislabs/modules/rg/10002/deps/
tar -xvf redisgears-dependencies.linux-bionic-x64.1.0.2.tgz -C /var/opt/redislabs/modules/rg/10002/deps
chown -R redislabs /var/opt/redislabs/modules/rg
EOF
sudo docker cp install_gears.sh re-node1:/opt/install_gears.sh
sudo docker exec --user root -it re-node1 bash -c "chmod 777 /opt/install_gears.sh"
sudo docker exec --user root -it re-node1 bash -c "/opt/install_gears.sh"
sudo docker cp install_gears.sh re-node2:/opt/install_gears.sh
sudo docker exec --user root -it re-node2 bash -c "chmod 777 /opt/install_gears.sh"
sudo docker exec --user root -it re-node2 bash -c "/opt/install_gears.sh"
sudo docker cp install_gears.sh re-node3:/opt/install_gears.sh
sudo docker exec --user root -it re-node3 bash -c "chmod 777 /opt/install_gears.sh"
sudo docker exec --user root -it re-node3 bash -c "/opt/install_gears.sh"

echo "Uploading RedisGears module..."
rm upload_rg.sh
tee -a upload_rg.sh <<EOF
curl -v -k -u demo@redislabs.com:redislabs -F "module=@./redisgears.linux-bionic-x64.1.0.2.zip" https://localhost:9443/v1/modules
EOF
sudo docker cp upload_rg.sh re-node1:/opt/upload_rg.sh
sudo docker exec --user root -it re-node1 bash -c "chmod 777 /opt/upload_rg.sh"
sudo docker exec --user root -it re-node1 bash -c "/opt/upload_rg.sh"

echo "------- RLADMIN status -------"
sudo docker exec -it re-node1 bash -c "rladmin status"
echo ""
echo "Now open the browser and access Redis Enterprise Admin UI at https://127.0.0.1:18443 with username=demo@redislabs.com and password=redislabs."
echo "To connect using RedisInsight or redis-cli, please use the exposed port from the node where master shard for the database resides."
echo "DISCLAIMER: This is best for local development or functional testing. Please see, https://docs.redislabs.com/latest/rs/getting-started/getting-started-docker"
