#!/bin/bash

sudo docker cp update.sql mysql-5.7.33-$(hostname):update.sql
sudo docker exec -it mysql-5.7.33-$(hostname) bash -c 'mysql -h"localhost" -P3306 -uroot -pRedis@123 < update.sql'
echo ""
