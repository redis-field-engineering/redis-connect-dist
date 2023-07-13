#!/bin/bash

version="${1:-latest}"
cleanup="${2:-yes}"

container_name="re-node1-$version-$(hostname)"

# delete the existing container if it exist
if [ "${cleanup}" = "yes" ]; then
  echo "Stopping and removing ${container_name} docker container from $(hostname)."
  docker container stop "${container_name}"; docker container rm "${container_name}"; docker stop grafana; docker rm grafana; docker network rm redis-connect;
else
  echo "Skipping removing ${container_name} docker container from $(hostname)."
fi

echo "done"