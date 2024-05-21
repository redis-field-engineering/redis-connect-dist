#!/bin/bash

version="${1:-1.15.1}"
jmx_port="${2:-1099}"
rest_port="${3:-8080}"
pulse_port="${4:-7070}"
locator_port="${5:-10334}"
cache_server_port="${6:-40404}"

platform="${7:-linux/amd64}"

container_name="gemfire-$version-$(hostname)"

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

docker run \
  --name "${container_name}" \
  --privileged=true \
  --platform "${platform}" \
  -v "$(pwd)"/scripts:/geode/scripts \
  -p "${jmx_port}":1099 \
  -p "${rest_port}":8080 \
  -p "${pulse_port}":7070 \
  -p "${locator_port}":10334 \
  -p "${cache_server_port}":40404 \
  --entrypoint sh \
  -d apachegeode/geode:"${version}" -c "/geode/scripts/forever"

sleep 60

docker cp cache.xml "${container_name}":cache.xml
docker cp gemfire-initial-load-function-0.10.1.jar "${container_name}":gemfire-initial-load-function-0.10.1.jar
docker cp extlib/gemfire-pojo-1.0.jar "${container_name}":gemfire-pojo-1.0.jar

echo "Starting locator1, server1 and deploying client function for the load job.."
docker exec --user root "${container_name}" sh -c "gfsh -e 'start locator --name=locator1 --hostname-for-clients=localhost' -e 'deploy --jar=./gemfire-pojo-1.0.jar' -e 'deploy --jar=./gemfire-initial-load-function-0.10.1.jar' -e 'start server --name=server1 --cache-xml-file=./cache.xml --hostname-for-clients=localhost' -e 'list functions'"

echo "done"