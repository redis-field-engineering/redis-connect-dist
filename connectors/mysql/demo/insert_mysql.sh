#!/bin/bash
  
sudo docker cp insert.sql mysql-5.7.33-$(hostname):insert.sql
sudo docker exec -it mysql-5.7.33-$(hostname) bash -c 'mysql -h"localhost" -P3306 -uroot -pRedis@123 < insert.sql'
echo ""
