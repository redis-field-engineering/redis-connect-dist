#!/bin/bash

sudo docker cp update.sql mysql-latest-$(hostname):update.sql
sudo docker exec -it mysql-latest-$(hostname) bash -c 'mysql -h"localhost" -P3306 -uroot -pRedis@123 RedisConnect < update.sql'
echo ""
