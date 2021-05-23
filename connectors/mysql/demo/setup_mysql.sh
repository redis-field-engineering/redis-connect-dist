#!/bin/bash

version="$1"
db_port=3306
[[ -z "$version" ]] && { echo "Error: Missing docker version tag e.g. latest, 5.7.33"; exit 1; }

# delete the existing mysql:latest container if it exist
sudo docker kill mysql-$version-$(hostname);sudo docker rm mysql-$version-$(hostname);

echo "Creating mysql-$version-$(hostname) docker container."
sudo docker run --name mysql-$version-$(hostname) \
	-v $(pwd):/etc/mysql/conf.d \
	-p $db_port:3306 \
	-e MYSQL_ROOT_PASSWORD=Redis@123 \
	-d mysql:$version

sleep 30s

echo "Creating RedisLabsCDC database and emp table."
#run the setup script to create the DB and the table in the DB
sudo docker cp mysql_cdc.sql mysql-$version-$(hostname):mysql_cdc.sql
sudo docker exec -it mysql-$version-$(hostname) bash -c 'mysql -h"localhost" -P3306 -uroot -p"$MYSQL_ROOT_PASSWORD" < mysql_cdc.sql'
echo ""
