#!/bin/bash

version="$1"
[[ -z "$version" ]] && { echo "Error: Missing docker version tag e.g. 12.2.0.1-ee, 19.3.0-ee"; exit 1; }

echo "Setting up LogMiner and loading sample HR schema.."
sudo docker cp setup_logminer.sh oracle-$version-$(hostname):/tmp/setup_logminer.sh
sudo docker exec -it oracle-$version-$(hostname) bash -c "/tmp/setup_logminer.sh"
sudo docker cp setup_hr.sh oracle-$version-$(hostname):/tmp/setup_hr.sh
sudo docker exec -it oracle-$version-$(hostname) bash -c "/tmp/setup_hr.sh"
