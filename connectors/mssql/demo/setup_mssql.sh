#!/bin/bash

version="$1"
[[ -z "$version" ]] && { echo "Error: Missing docker version tag e.g. 2017-latest, 2019-latest"; exit 1; }

# delete the existing mssql2017 container if it exist
sudo docker kill mssql-$version-$(hostname);sudo docker rm mssql-$version-$(hostname);

echo "Creating mssql-$version-$(hostname) docker container."
sudo docker run -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=Redis@123" -e "MSSQL_AGENT_ENABLED=true" -p 1433:1433 --name mssql-$version-$(hostname) -d mcr.microsoft.com/mssql/server:$version

sleep 30s

echo "Creating RedisLabsCDC database and emp table."
#run the setup script to create the DB and the table in the DB
sudo docker cp mssql_cdc.sql mssql-$version-$(hostname):mssql_cdc.sql
sudo docker exec -it mssql-$version-$(hostname) /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "Redis@123" -i mssql_cdc.sql
echo ""
