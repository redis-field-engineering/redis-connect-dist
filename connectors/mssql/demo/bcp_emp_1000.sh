#!/bin/bash

sudo docker cp emp_1000.csv mssql2017-$(hostname):emp_1000.csv
sudo docker exec -it mssql2017-$(hostname) bash -c "/opt/mssql-tools/bin/bcp emp in emp_1000.csv -S localhost -U sa -P "Redis@123" -d RedisLabsCDC -c -F 2 -t ','"
echo ""
