#!/bin/bash

# delete the existing postgres:latest container if it exist
sudo docker kill postgres-latest-$(hostname);sudo docker rm postgres-latest-$(hostname);

echo "Creating postgres-latest-$(hostname) docker container."
sudo docker run --name postgres-latest-$(hostname) -p 5432:5432 -e POSTGRES_DB=RedisLabsCDC -e POSTGRES_USER=rediscdc -e POSTGRES_PASSWORD=Redis@123 -d postgres:latest

sleep 30s

echo "Creating RedisLabsCDC database and emp table."
#run the setup script to create the DB and the table in the DB
sudo docker cp postgres_cdc.sql postgres-latest-$(hostname):postgres_cdc.sql
sudo docker exec -it postgres-latest-$(hostname) bash -c 'psql -U"$POSTGRES_USER" -d"$POSTGRES_DB" < postgres_cdc.sql'
echo ""
