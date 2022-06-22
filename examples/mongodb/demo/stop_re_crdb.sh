#!/bin/bash

sudo docker stop re-node1-cluster1 re-node1-cluster2 re-node1-cluster3 redisinsight grafana
sudo docker rm re-node1-cluster1 re-node1-cluster2 re-node1-cluster3 redisinsight grafana
sudo docker network rm network1 2>/dev/null
sudo docker network rm network2 2>/dev/null
sudo docker network rm network3 2>/dev/null
