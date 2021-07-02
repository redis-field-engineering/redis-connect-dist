#!/bin/bash

version="$1"
db_port=50000
db_name="rcdb2"
db_user="redisconnectuser"
db_pwd="redisconnectpassword"
[[ -z "$version" ]] && { echo "Error: Missing docker version tag e.g. latest, 11.5.5.1"; exit 1; }

container_name="db2-$version-$(hostname)"

# delete the existing container if it exist
sudo docker kill $container_name;sudo docker rm $container_name;

echo "Creating $container_name docker container."

sudo docker run --name $container_name --privileged=true \
	-e DBNAME=$db_name \
	-e DB2INSTANCE=$db_name \
	-e DB2INST1_PASSWORD=$db_pwd \
	-p $db_port:50000 \
	-e LICENSE=accept \
	-v $(pwd)/database:/database \
	-d ibmcom/db2:$version \

sleep 30s

#echo "Creating RedisConnect database and emp table."
#run the setup script to create the DB and the table in the DB
#sudo docker exec --user $db_name -it $container_name bash -c '"$HOME"/sqllib/bin/db2 connect to "$db_name"'
#sudo docker exec --user $db_name -it $container_name bash -c '"$HOME"/sqllib/bin/db2ilist'
#sudo docker cp db2_cdc.sql $container_name:db2_cdc.sql
#sudo docker exec --user $db_name -it $container_name bash -c '"$HOME"/sqllib/bin/db2 -f db2_cdc.sql'
echo ""
