#!/bin/bash

sudo docker stop rp1 rp2 rp3 redisinsight grafana
sudo docker rm rp1 rp2 rp3 redisinsight grafana
sudo docker network rm network1 2>/dev/null
sudo docker network rm network2 2>/dev/null
sudo docker network rm network3 2>/dev/null
