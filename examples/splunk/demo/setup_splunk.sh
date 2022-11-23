#!/bin/bash

# Stop and remove container and network
sudo docker stop redisconnect-splunk;
sudo docker stop redisconnect-splunk-uf1;
sudo docker network rm splunknet1 2>/dev/null

# Create dedicated network to be used for forward purposes later
sudo docker network create splunknet1 --subnet=172.24.0.0/16 --gateway=172.24.0.1

# Start Splunk Enterprise
sudo docker run -d --network splunknet1 --name redisconnect-splunk1 --hostname redisconnect-splunk1 --rm -p 18081:8000 -p 18089:8089 -p 18088:8088 -p 31000:31000 -e "SPLUNK_START_ARGS=--accept-license" -e "SPLUNK_PASSWORD=Redis123" -it splunk/splunk:8.1.2
#sudo docker run -d --network splunknet2 --name redisconnect-splunk2 --hostname redisconnect-splunk2 --rm -p 28081:8000 -p 28089:8089 -p 28088:8088 -e "SPLUNK_START_ARGS=--accept-license" -e "SPLUNK_PASSWORD=Redis123" -it splunk/splunk:8.1.2

# Start Universal Forwarder
sudo docker run -d --network splunknet1 --name redisconnect-splunk-uf1 --hostname redisconnect-splunk-uf1 --rm -p 9998:9997 -e "SPLUNK_START_ARGS=--accept-license" -e "SPLUNK_PASSWORD=Redis123" -e "SPLUNK_STANDALONE_URL=redisconnect-splunk1" -it splunk/universalforwarder:8.1.2

attempt=0
while [ $attempt -le 100 ]; do
    attempt=$(( $attempt + 1 ))
    echo "$(date) - Waiting for redisconnect-splunk1 to be up (attempt: $attempt)..."
    result=$(docker logs redisconnect-splunk1)
    if grep -q 'Ansible playbook complete' <<< $result ; then
      echo "$(date) - redisconnect-splunk1 is up!"
      break
    fi
    sleep 5
done

# Connect the networks
#sudo docker network connect splunknet2 redisconnect-splunk1
#sudo docker network connect splunknet1 redisconnect-splunk2

#echo "log test $(date)" >> splunk-s2s-test.log
#docker cp splunk-s2s-test.log redisconnect-splunk-uf1:/opt/splunkforwarder/splunk-s2s-test.log

#sudo docker exec -it redisconnect-splunk-uf1 bash -c "sudo ./bin/splunk add monitor -source /opt/splunkforwarder/splunk-s2s-test.log -auth admin:Redis123"

#docker cp outputs.conf redisconnect-splunk-uf1:/opt/splunkforwarder/etc/system/local/
#sudo docker exec -it redisconnect-splunk bash -c "sudo ./bin/splunk restart"

