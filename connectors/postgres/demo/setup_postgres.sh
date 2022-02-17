#!/bin/bash

version="$1"
db_port="$2"
db_name="RedisConnect"
db_user="redisconnect"
db_pwd="Redis@123"
[[ -z "$version" ]] && { echo "Error: Missing docker version tag e.g. latest, 12.7"; exit 1; }
[[ -z "$db_port" ]] && { echo "Error: Missing database port e.g. 5432"; exit 1; }

container_name="postgres-$version-$(hostname)-$db_port"
# delete the existing postgres:$version container if it exist
sudo docker kill $container_name;sudo docker rm $container_name;

echo "Creating $container_name docker container."
sudo docker run --name $container_name \
	-e POSTGRES_DB=$db_name \
	-e POSTGRES_USER=$db_user \
	-e POSTGRES_PASSWORD=$db_pwd \
	-p $db_port:5432 \
	-d postgres:$version \
	-c wal_level=logical \
	-c max_wal_senders=10 \
	-c max_replication_slots=10 \
	-c track_commit_timestamp=on
	#-c wal_receiver_timeout=300s \
	#-c wal_sender_timeout=0

sleep 30s

echo "Creating RedisConnect database and emp table."
#run the setup script to create the DB and the table in the DB
sudo docker cp postgres_cdc.sql $container_name:postgres_cdc.sql
sudo docker exec -it $container_name bash -c 'psql -U"$POSTGRES_USER" -d"$POSTGRES_DB" < postgres_cdc.sql'
echo ""
