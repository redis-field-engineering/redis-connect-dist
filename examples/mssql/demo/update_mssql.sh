#!/bin/bash

sudo docker cp update.sql $(docker ps -a --format "table {{.Names}}" | grep mssql):update.sql
sudo docker exec -it $(docker ps -a --format "table {{.Names}}" | grep mssql) /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "Redis@123" -d RedisConnect -i update.sql
echo ""
