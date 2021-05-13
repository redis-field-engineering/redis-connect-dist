#!/bin/bash

# delete the existing mysql:latest container if it exist
sudo docker kill mysql-latest-$(hostname);sudo docker rm mysql-latest-$(hostname);

echo "Creating mysql-latest-$(hostname) docker container."
sudo docker run --name mysql-latest-$(hostname) -v $(pwd)/mysql:/etc/mysql/conf.d -p 3306:3306 -e MYSQL_ROOT_PASSWORD=Redis@123 -d mysql:latest

sleep 30s

echo "Creating RedisLabsCDC database and emp table."
#run the setup script to create the DB and the table in the DB
sudo docker cp mysql_cdc.sql mysql-latest-$(hostname):mysql_cdc.sql
sudo docker exec -it mysql-latest-$(hostname) bash -c 'mysql -h"localhost" -P"3306" -uroot -p"$MYSQL_ROOT_PASSWORD" < mysql_cdc.sql'
echo ""
