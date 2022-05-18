#!/bin/bash

sudo docker cp delete.sql $(docker ps -a --format "table {{.Names}}" | grep mysql):delete.sql
sudo docker exec -it $(docker ps -a --format "table {{.Names}}" | grep mysql) bash -c 'mysql -h"localhost" -P3306 -uroot -pRedis@123 RedisConnect < delete.sql'
echo ""
