#!/bin/bash

# Please build the oracle container image prior to running this setup script. See here, https://github.com/oracle/docker-images
# https://github.com/oracle/docker-images/blob/main/OracleDatabase/SingleInstance/README.md
# ./buildContainerImage.sh -i -e -v 12.2.0.1
# OR
# Use a pre-built image

version="$1"
[[ -z "$version" ]] && { echo "Error: Missing docker version tag e.g. 12.2.0.1-ee, 19.3.0-ee"; exit 1; }

# delete the existing container if it exist
sudo docker kill oracle-$version-$(hostname);sudo docker rm oracle-$version-$(hostname);

# create volume and setup necessary permissions
sudo rm -rf $(pwd)/oradata
sudo mkdir -p $(pwd)/oradata/recovery_area
sudo chgrp 54321 $(pwd)/oradata
sudo chown 54321 $(pwd)/oradata
sudo chgrp 54321 $(pwd)/oradata/recovery_area
sudo chown 54321 $(pwd)/oradata/recovery_area

echo "Creating oracle-$version-$(hostname) docker container."
sudo docker run --name oracle-$version-$(hostname) \
	-d --rm \
	-p 1521:1521 \
	-p 5500:5500 \
	-e ORACLE_PWD=Redis123 \
	-v $(pwd)/oradata:/opt/oracle/oradata \
	oracle/database:$version
