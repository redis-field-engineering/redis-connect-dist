#!/bin/bash

version="$1"
db_port="$2"
db_name="rcdb2"
db_instance="db2inst1"
db_pwd="rcdbpwd"
[[ -z "$version" ]] && { echo "Error: Missing docker version tag e.g. latest, 11.5.7.0"; exit 1; }
[[ -z "$db_port" ]] && { echo "Error: Missing database port e.g. 50000"; exit 1; }

container_name="db2-$version-$(hostname)-$db_port"

# delete the existing container if it exist
sudo docker kill $container_name;sudo docker rm $container_name;sudo rm -rf $(pwd)/database;

echo "Creating $container_name docker container."

sudo docker run --name $container_name --privileged=true \
	-e LICENSE=accept \
	-e DB2INSTANCE=$db_instance \
	-e DB2INST1_PASSWORD=$db_pwd \
	-e DBNAME=$db_name \
	-e BLU=false \
	-e ENABLE_ORACLE_COMPATIBILITY=false \
	-e UPDATEAVAIL=NO \
	-e TO_CREATE_SAMPLEDB=false \
	-e REPODB=false \
	-e IS_OSXFS=false \
	-e PERSISTENT_HOME=true \
	-e HADR_ENABLED=false \
	-e ETCD_ENDPOINT= \
	-e ETCD_USERNAME= \
	-e ETCD_PASSWORD= \
	-p $db_port:50000 \
	-v $(pwd)/database:/database \
	-d ibmcom/db2:$version

while ! nc -vz $(sudo docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $container_name) 50000 < /dev/null
do
  echo "$(date) - still trying"
  sleep 2
done
echo "$(date) - connected successfully"

echo "Creating $db_name database on $db_instance DB2 instance."
attempt=0
while [ $attempt -le 400 ]; do
    attempt=$(( $attempt + 1 ))
    echo "$(date) - Waiting for $db_name database to be up (attempt: $attempt)..."
    result=$(docker logs $container_name)
    if grep -q 'Setup has completed' <<< $result ; then
      echo "$(date) - $container_name is up!"
      break
    fi
    sleep 5
done

echo "Creating emp table on $db_name database."
#run the setup script to create the DB and the table in the DB
sudo docker exec --user $db_instance -it $container_name bash -c '~/sqllib/bin/db2ilist'
sudo docker exec --user $db_instance -it $container_name bash -c '~/sqllib/adm/db2licm -l'
sudo docker exec --user $db_instance -it $container_name bash -c '~/sqllib/bin/db2 list database directory'
sudo docker exec --user $db_instance -it $container_name bash -c '~/sqllib/bin/db2 activate database $DBNAME'
sudo docker cp create_emp_table.sql $container_name:/var/tmp/create_emp_table.sql
sudo docker cp create_emp_table.sh $container_name:/var/tmp/create_emp_table.sh
sudo docker exec --user $db_instance -it $container_name bash -c '/var/tmp/create_emp_table.sh'
echo ""
