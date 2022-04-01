#!/bin/bash

version="$1"
db_port="$2"
[[ -z "$version" ]] && { echo "Error: Missing docker version tag e.g. latest, 5.7.33"; exit 1; }
[[ -z "$db_port" ]] && { echo "Error: Missing database port e.g. 3306"; exit 1; }

container_name="mysql-$version-$(hostname)-$db_port"
# delete the existing mysql:latest container if it exist
sudo docker kill $container_name;sudo docker rm $container_name;

echo "Creating $container_name docker container."
sudo docker run --name $container_name \
	-v $(pwd):/etc/mysql/conf.d \
	-p $db_port:3306 \
	-e MYSQL_ROOT_PASSWORD=Redis@123 \
	-d mysql:$version

sleep 30s

echo "Creating RedisConnect database and emp table."
#run the setup script to create the DB and the table in the DB
sudo docker cp mysql_cdc.sql $container_name:mysql_cdc.sql
sudo docker exec -it $container_name bash -c 'mysql -h"localhost" -P3306 -uroot -p"$MYSQL_ROOT_PASSWORD" < mysql_cdc.sql'
echo ""
