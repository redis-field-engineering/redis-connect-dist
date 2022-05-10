#!/bin/bash

sudo docker cp insert.sql $(docker ps -a --format "table {{.Names}}" | grep mssql):insert.sql
sudo docker exec -it $(docker ps -a --format "table {{.Names}}" | grep mssql) /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "Redis@123" -d RedisConnect -i insert.sql
echo ""
