#!/bin/bash

sudo docker cp delete.sql $(docker ps -a --format "table {{.Names}}" | grep mssql):delete.sql
sudo docker exec -it $(docker ps -a --format "table {{.Names}}" | grep mssql) /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "Redis@123" -d RedisConnect -i delete.sql
echo ""
