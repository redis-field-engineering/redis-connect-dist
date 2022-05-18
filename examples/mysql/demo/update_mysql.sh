#!/bin/bash

sudo docker cp update.sql $(docker ps -a --format "table {{.Names}}" | grep mysql):update.sql
sudo docker exec -it $(docker ps -a --format "table {{.Names}}" | grep mysql) bash -c 'mysql -h"localhost" -P3306 -uroot -pRedis@123 RedisConnect < update.sql'
echo ""
