#!/bin/bash

version="${1:-12.3}"
db_port="${2:-5432}"
cleanup="${3:-yes}"

container_name="postgres-$version-$(hostname)-$db_port"

# delete the existing container if it exist
if [ "${cleanup}" = "yes" ]; then
  echo "Stopping and removing ${container_name} docker container from $(hostname)."
  docker container stop "${container_name}"; docker container rm "${container_name}";
else
  echo "Skipping removing ${container_name} docker container from $(hostname)."
fi

echo "done"