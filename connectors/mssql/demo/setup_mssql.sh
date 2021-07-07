#!/bin/bash

version="$1"
db_port=1433
db_pwd="Redis@123"
[[ -z "$version" ]] && { echo "Error: Missing docker version tag e.g. 2017-latest, 2019-latest"; exit 1; }

# delete the existing mssql2017 container if it exist
sudo docker kill mssql-$version-$(hostname);sudo docker rm mssql-$version-$(hostname);

echo "Creating mssql-$version-$(hostname) docker container."
sudo docker run --name mssql-$version-$(hostname) \
	-e "ACCEPT_EULA=Y" \
	-e SA_PASSWORD=$db_pwd \
	-e "MSSQL_AGENT_ENABLED=true" \
	-e "MSSQL_MEMORY_LIMIT_MB=2GB" \
	-p $db_port:1433 \
	-d mcr.microsoft.com/mssql/server:$version

sleep 30s

echo "Creating RedisConnect database and emp table."
#run the setup script to create the DB and the table in the DB
sudo docker cp mssql_cdc.sql mssql-$version-$(hostname):mssql_cdc.sql
sudo docker exec -it mssql-$version-$(hostname) bash -c '/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -i mssql_cdc.sql'
echo ""
