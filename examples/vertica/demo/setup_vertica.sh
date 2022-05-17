#!/bin/bash

version="$1"
db_port="$2"
db_user=redisconnect
db_pwd=Redis123
[[ -z "$version" ]] && { echo "Error: Missing docker version tag e.g. 11.1.0-0, latest"; exit 1; }
[[ -z "$db_port" ]] && { echo "Error: Missing database port e.g. 5433"; exit 1; }

container_name="vertica-$(hostname)-$db_port"
# delete the existing container if it exist
sudo docker kill $container_name;sudo docker rm $container_name;

# create volume and setup necessary permissions
sudo rm -rf $(pwd)/$container_name/data
sudo mkdir -p $(pwd)/$container_name/data
sudo chmod a+w -R $(pwd)/$container_name/data

echo "Creating $container_name docker container."
sudo docker run --name $container_name \
	-p $db_port:5433 \
	-e APP_DB_USER=$db_user \
	-e APP_DB_PASSWORD=$db_pwd \
	-e VERTICA_DB_NAME="RedisConnect" \
	-v $(pwd)/$container_name/data:/data \
        -d vertica/vertica-ce:$version

while ! nc -vz $(sudo docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $container_name) 5433 < /dev/null
do
  echo "$(date) - still trying"
  sleep 2
done
echo "$(date) - connected successfully"

attempt=0
while [ $attempt -le 400 ]; do
    attempt=$(( $attempt + 1 ))
    echo "$(date) - Waiting for vertica database to be up (attempt: $attempt)..."
    result=$(docker logs $container_name)
    if grep -q 'Vertica is now running' <<< $result ; then
      echo "$(date) - $container_name is up!"
      break
    fi
    sleep 5
done
