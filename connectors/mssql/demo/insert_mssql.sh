#!/bin/bash
  
sudo docker cp insert.sql mssql2017-$(hostname):insert.sql
sudo docker exec -it mssql2017-$(hostname) /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "Redis@123" -d RedisLabsCDC -i insert.sql
echo ""
