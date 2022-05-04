#!/bin/bash
  
sudo docker cp insert.sql mysql-latest-$(hostname):insert.sql
sudo docker exec -it mysql-latest-$(hostname) bash -c 'mysql -h"localhost" -P3306 -uroot -pRedis@123 RedisConnect < insert.sql'
echo ""
