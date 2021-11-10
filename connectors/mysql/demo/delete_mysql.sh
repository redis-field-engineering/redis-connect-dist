#!/bin/bash

sudo docker cp delete.sql mysql-5.7.33-$(hostname):delete.sql
sudo docker exec -it mysql-5.7.33-$(hostname) bash -c 'mysql -h"localhost" -P3306 -uroot -pRedis@123 < delete.sql'
echo ""
