#!/bin/bash
  
sudo docker cp delete.sql mssql2017-$(hostname):delete.sql
sudo docker exec -it mssql2017-$(hostname) /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "Redis@123" -d RedisLabsCDC -i delete.sql
echo ""
