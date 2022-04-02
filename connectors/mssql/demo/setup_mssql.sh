#!/bin/bash

version="$1"
db_port="$2"
db_pwd="Redis@123"
[[ -z "$version" ]] && { echo "Error: Missing docker version tag e.g. 2017-latest, 2019-latest"; exit 1; }
[[ -z "$db_port" ]] && { echo "Error: Missing database port e.g. 1433"; exit 1; }

container_name="mysql-$version-$(hostname)-$db_port"
# delete the existing mssql container if it exist
sudo docker kill $container_name;sudo docker rm $container_name;

echo "Creating $container_name docker container."
sudo docker run --name $container_name \
	-e "ACCEPT_EULA=Y" \
	-e SA_PASSWORD=$db_pwd \
	-e "MSSQL_AGENT_ENABLED=true" \
	-e "MSSQL_MEMORY_LIMIT_MB=2GB" \
	-p $db_port:1433 \
	-d mcr.microsoft.com/mssql/server:$version

sleep 30s

echo "Creating RedisConnect database and emp table."
#run the setup script to create the DB and the table in the DB
sudo docker cp mssql_cdc.sql $container_name:mssql_cdc.sql
sudo docker exec -it $container_name bash -c '/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -i mssql_cdc.sql'
echo ""
