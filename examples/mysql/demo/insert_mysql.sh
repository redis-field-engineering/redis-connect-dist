#!/bin/bash
  
sudo docker cp insert.sql $(docker ps -a --format "table {{.Names}}" | grep mysql):insert.sql
sudo docker exec -it $(docker ps -a --format "table {{.Names}}" | grep mysql) bash -c 'mysql -h"localhost" -P3306 -uroot -pRedis@123 RedisConnect < insert.sql'
echo ""
