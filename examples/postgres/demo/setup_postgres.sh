#!/bin/bash

version="${1:-12.3}"
db_port="${2:-5432}"
db_name="RedisConnect"
db_user="redisconnect"
db_pwd="Redis@123"

container_name="postgres-$version-$(hostname)-$db_port"

echo "Creating $container_name docker container."
IS_RUNNING=$(docker ps --filter name="${container_name}" --format '{{.ID}}')
if [ -n "${IS_RUNNING}" ]; then
    echo "${container_name} is running. Stopping ${container_name} and removing container..."
    docker container stop "${container_name}"
    docker container rm "${container_name}"
else
    IS_STOPPED=$(docker ps -a --filter name="${container_name}" --format '{{.ID}}')
    if [ -n "${IS_STOPPED}" ]; then
        echo "${container_name} is stopped. Removing container..."
        docker container rm "${container_name}"
    fi
fi

docker run --name "${container_name}" \
	-e POSTGRES_DB=$db_name \
	-e POSTGRES_USER=$db_user \
	-e POSTGRES_PASSWORD=$db_pwd \
	-p "${db_port}":5432 \
	-d postgres:"${version}" \
	-c wal_level=logical \
	-c max_wal_senders=10 \
	-c max_replication_slots=10 \
	-c max_connections=500 \
	-c shared_buffers=1GB \
	-c track_commit_timestamp=on

sleep 30

echo "Creating $db_name database and emp table."
#run the setup script to create the DB and the table in the DB
docker cp postgres_cdc.sql "${container_name}":postgres_cdc.sql
docker cp ./emp.csv "${container_name}":/tmp/emp.csv
docker cp load_table.sql "${container_name}":load_table.sql
docker exec "${container_name}" bash -c 'psql -U"$POSTGRES_USER" -d"$POSTGRES_DB" < postgres_cdc.sql'

echo "done"