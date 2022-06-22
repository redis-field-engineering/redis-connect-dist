#!/bin/bash

sudo docker network connect network2 re-node1-cluster1
sudo docker network connect network3 re-node1-cluster1
sudo docker network connect network1 re-node1-cluster2
sudo docker network connect network3 re-node1-cluster2
sudo docker network connect network1 re-node1-cluster3
sudo docker network connect network2 re-node1-cluster3
