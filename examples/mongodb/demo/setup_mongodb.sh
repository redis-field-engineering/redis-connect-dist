#!/bin/bash

version="${1:-6.0.6}"
db_port="${2:-27017}"

db_user="redisconnect"
db_password="Redis123"
db_name="sample_training"
collection="companies"

container_name="mongodb-$version-$(hostname)-$db_port"

echo "Creating $container_name docker container."
IS_RUNNING=$(docker ps --filter name="${container_name}" --format '{{.ID}}')
if [ -n "${IS_RUNNING}" ]; then
    echo "${container_name} is running. Stopping ${container_name} and removing container..."
    docker container stop "${container_name}"
    docker container rm "${container_name}"
    docker network rm "${network}"
else
    IS_STOPPED=$(docker ps -a --filter name="${container_name}" --format '{{.ID}}')
    if [ -n "${IS_STOPPED}" ]; then
        echo "${container_name} is stopped. Removing container..."
        docker container rm "${container_name}"
        docker network rm "${network}"
    fi
fi

docker run \
  -d \
  -p "${db_port}":27017 \
  -e MONGO_INITDB_DATABASE=sample_training \
  -e MONGO_INITDB_ROOT_USERNAME="${db_user}" \
  -e MONGO_INITDB_ROOT_PASSWORD="${db_password}" \
  -v $(pwd)/keyfile:/data/keyfile \
  --name "${container_name}" \
  mongo:"${version}" mongod --replSet rs --keyFile /data/keyfile/mongo-keyfile --bind_ip_all

sleep 10

docker exec "${container_name}" mongosh --eval "rs.initiate({
 "_id:" \"rs\",
 "members" : [
   {_id: 0, host: \"127.0.0.1\"}
 ]
}, { force: true })" -u "${db_user}" -p "${db_password}"

sleep 25

echo "Creating user and importing sample_airbnb.listingsAndReviews collection.."
docker cp sample_training.companies.json "${container_name}":/tmp/sample_training.companies.json
docker exec "${container_name}" mongoimport -d "${db_name}" -c "${collection}" --file /tmp/sample_training.companies.json --jsonArray -u "${db_user}" -p "${db_password}" --authenticationDatabase admin

echo "done"