#!/bin/bash

# Please build the oracle container image prior to running this setup script. See here, https://github.com/oracle/docker-images
# https://github.com/oracle/docker-images/blob/main/OracleDatabase/SingleInstance/README.md
# ./buildContainerImage.sh -i -e -v 12.2.0.1
# OR
# Use a pre-built image


version="$1"
db_port="$2"
logminer="$3"
db_pwd=Redis123
[[ -z "$version" ]] && { echo "Error: Missing docker version tag e.g. 12.2.0.1-ee, 19.3.0-ee, 21.3.0-ee"; exit 1; }
[[ -z "$db_port" ]] && { echo "Error: Missing database port e.g. 1521"; exit 1; }
#[[ -z "$https_port" ]] && { echo "Error: Missing https port e.g. 5500"; exit 1; }

container_name="oracle-$version-$(hostname)-$db_port"
# delete the existing container if it exist
sudo docker kill $container_name;sudo docker rm $container_name;

# create volume and setup necessary permissions
sudo rm -rf $(pwd)/$version/oradata
sudo mkdir -p $(pwd)/$version/oradata/recovery_area
sudo chgrp -R 54321 $(pwd)/$version/oradata
sudo chown -R 54321 $(pwd)/$version/oradata

echo "Creating $container_name docker container."
sudo docker run --name $container_name \
	-p $db_port:1521 \
	-e ORACLE_PWD=$db_pwd \
	-v $(pwd)/$version/oradata:/opt/oracle/oradata \
        -d virag/oracle-$version
#	oracle/database:$version

#sudo docker wait $container_name

while ! nc -vz $(sudo docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $container_name) 1521 < /dev/null
do
  echo "$(date) - still trying"
  sleep 2
done
echo "$(date) - connected successfully"

attempt=0
while [ $attempt -le 400 ]; do
    attempt=$(( $attempt + 1 ))
    echo "$(date) - Waiting for oracle database to be up (attempt: $attempt)..."
    result=$(docker logs $container_name)
    if grep -q 'DATABASE IS READY TO USE!' <<< $result ; then
      echo "$(date) - $container_name is up!"
      break
    fi
    sleep 5
done

#Check if the logminer option is provided or not
if [ $# -eq 3 ] && [ "$3" = "logminer" ]; then
	echo "Setting up LogMiner and loading sample HR and C##RCUSER schema on $container_name.."
	sudo docker cp setup_logminer.sh $container_name:/tmp/setup_logminer.sh
	sudo docker exec -it $container_name bash -c "/tmp/setup_logminer.sh"
	sudo docker cp emp.csv $container_name:/tmp/emp.csv
	sudo docker cp emp.ctl $container_name:/tmp/emp.ctl
	sudo docker cp load_sql.sh $container_name:/tmp/load_sql.sh
	sudo docker cp load_c##rcuser_schema.sh $container_name:/tmp/load_c##rcuser_schema.sh
        sudo docker exec -it $container_name bash -c "/tmp/load_c##rcuser_schema.sh"
	sudo docker cp employees1k_insert.sql $container_name:/tmp/employees1k_insert.sql
	sudo docker cp employees10k_insert.sql $container_name:/tmp/employees10k_insert.sql
	sudo docker cp update.sql $container_name:/tmp/update.sql
	sudo docker cp delete.sql $container_name:/tmp/delete.sql
else
	echo "Skipping LogMiner setup.."
fi
