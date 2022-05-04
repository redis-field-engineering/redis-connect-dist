#!/bin/bash

sudo docker cp delete.sql mysql-latest-$(hostname):delete.sql
sudo docker exec -it mysql-latest-$(hostname) bash -c 'mysql -h"localhost" -P3306 -uroot -pRedis@123 RedisConnect < delete.sql'
echo ""
