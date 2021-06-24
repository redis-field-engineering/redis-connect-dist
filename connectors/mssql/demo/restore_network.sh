#!/bin/bash

sudo docker network connect network2 rp1
sudo docker network connect network3 rp1
sudo docker network connect network1 rp2
sudo docker network connect network3 rp2
sudo docker network connect network1 rp3
sudo docker network connect network2 rp3
