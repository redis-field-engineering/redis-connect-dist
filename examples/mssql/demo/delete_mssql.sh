#!/bin/bash
  
sudo docker cp delete.sql mssql-2017-latest-$(hostname):delete.sql
sudo docker exec -it mssql-2017-latest-$(hostname) /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "Redis@123" -d RedisConnect -i delete.sql
echo ""
