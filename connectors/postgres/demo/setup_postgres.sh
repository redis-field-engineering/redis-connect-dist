#!/bin/bash

version="$1"
[[ -z "$version" ]] && { echo "Error: Missing docker version tag e.g. latest, 12.5"; exit 1; }

# delete the existing postgres:$version container if it exist
sudo docker kill postgres-$version-$(hostname);sudo docker rm postgres-$version-$(hostname);

echo "Creating postgres-$version-$(hostname) docker container."
sudo docker run --name postgres-$version-$(hostname) -e POSTGRES_DB=RedisLabsCDC -e POSTGRES_USER=rediscdc -e POSTGRES_PASSWORD=Redis@123 -p 5432:5432 -d postgres:$version -c wal_level=logical -c max_wal_senders=1 -c max_replication_slots=1

sleep 30s

echo "Creating RedisLabsCDC database and emp table."
#run the setup script to create the DB and the table in the DB
sudo docker cp postgres_cdc.sql postgres-$version-$(hostname):postgres_cdc.sql
sudo docker exec -it postgres-$version-$(hostname) bash -c 'psql -U"$POSTGRES_USER" -d"$POSTGRES_DB" < postgres_cdc.sql'
echo ""
