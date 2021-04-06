#!/bin/bash

docker network disconnect network2 rp1
docker network disconnect network3 rp1
docker network disconnect network1 rp2
docker network disconnect network3 rp2
docker network disconnect network1 rp3
docker network disconnect network2 rp3
