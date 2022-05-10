#!/bin/bash

sudo docker cp emp_1000.csv $(docker ps -a --format "table {{.Names}}" | grep mssql):emp_1000.csv
sudo docker exec -it $(docker ps -a --format "table {{.Names}}" | grep mssql) bash -c "/opt/mssql-tools/bin/bcp emp in emp_1000.csv -S localhost -U sa -P "Redis@123" -d RedisConnect -c -F 2 -t ','"
echo ""
