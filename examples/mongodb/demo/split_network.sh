#!/bin/bash

sudo docker network disconnect network2 re-node1-cluster1
sudo docker network disconnect network3 re-node1-cluster1
sudo docker network disconnect network1 re-node1-cluster2
sudo docker network disconnect network3 re-node1-cluster2
sudo docker network disconnect network1 re-node1-cluster3
sudo docker network disconnect network2 re-node1-cluster3
