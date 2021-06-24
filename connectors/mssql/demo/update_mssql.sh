#!/bin/bash
  
sudo docker cp update.sql mssql2017-$(hostname):update.sql
sudo docker exec -it mssql2017-$(hostname) /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "Redis@123" -d RedisConnect -i update.sql
echo ""
