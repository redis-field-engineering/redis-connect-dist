#!/bin/bash

sudo docker network disconnect network2 rp1
sudo docker network disconnect network3 rp1
sudo docker network disconnect network1 rp2
sudo docker network disconnect network3 rp2
sudo docker network disconnect network1 rp3
sudo docker network disconnect network2 rp3
