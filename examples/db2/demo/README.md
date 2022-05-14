# Prerequisites
Docker compatible [*nix OS](https://en.wikipedia.org/wiki/Unix-like) and [Docker](https://docs.docker.com/get-docker) installed.
<br>Please have 8 vCPU*, 8GB RAM and 50GB storage for this demo to function properly. Adjust the resources based on your requirements. For HA, at least have 2 Redis Connect Connector instances deployed on separate hosts.</br>
<br>Execute the following commands (copy & paste) to download and setup Redis Connect and demo scripts.
i.e.</br>

```bash
wget -c https://github.com/redis-field-engineering/redis-connect-dist/archive/main.zip && \
mkdir -p redis-connect/demo && \
mkdir -p redis-connect/k8s-docs && \
unzip main.zip "redis-connect-dist-main/examples/db2/*" -d redis-connect && \
cp -R redis-connect/redis-connect-dist-main/examples/db2/demo/* redis-connect/demo && \
cp -R redis-connect/redis-connect-dist-main/examples/db2/k8s-docs/* redis-connect/k8s-docs && \
rm -rf main.zip redis-connect/redis-connect-dist-main && \
cd redis-connect && \
chmod a+x demo/*.sh && \
cd demo
```

Expected output:
```bash
demo$ ls
README.md  config  extlib  setup_re.sh  setup_db2.sh
```

## Setup Vertica database (Source)
<br>Execute [setup_vertica.sh](setup_db2.sh)</br>
```bash
demo$ ./setup_db2.sh latest 50000
```

## Setup Redis Enterprise cluster, databases and RedisInsight in docker (Target)
<br>Execute [setup_re.sh](setup_re.sh)</br>
```bash
demo$ ./setup_re.sh
```
**NOTE**

The above script will create a 1-node Redis Enterprise cluster in a docker container, [Create a target database with RediSearch module](https://docs.redislabs.com/latest/modules/add-module-to-database/), [Create a job management and metrics database with RedisTimeSeries module](https://docs.redislabs.com/latest/modules/add-module-to-database/), [Create a RediSearch index for emp Hash](https://redislabs.com/blog/getting-started-with-redisearch-2-0/), [Start a docker instance of grafana with Redis Data Source](https://redisgrafana.github.io/) and [Start an instance of RedisInsight](https://docs.redislabs.com/latest/ri/installing/install-docker/).

## Start Redis Connect

<details><summary>Review options by running Redis Connect docker container </summary>
<p>

```bash
demo$ docker run \
-it --rm --privileged=true \
--name redis-connect-$(hostname) \
-v $(pwd)/config:/opt/redislabs/redis-connect/config \
-v $(pwd)/config/samples/credentials:/opt/redislabs/redis-connect/config/samples/credentials \
--net host \
redislabs/redis-connect
```

</p>
</details>

<details><summary>Expected output:</summary>
<p>

```bash
-------------------------------
Redis Connect startup script.
*******************************
Please ensure that these environment variables are correctly mapped before executing start and cli options. They can also be found in /opt/redislabs/redis-connect/bin/redisconnect.conf
Example environment variables and volume mapping for docker based deployments
-e REDISCONNECT_JOB_MANAGER_CONFIG_PATH=/opt/redislabs/redis-connect/config/jobmanager.properties [OPTIONAL]
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect/config/logback.xml [OPTIONAL]
-e REDISCONNECT_JAVA_OPTIONS=-Xms1g -Xmx2g [OPTIONAL]
-e REDISCONNECT_EXTLIB_DIR=/opt/redislabs/redis-connect/extlib [OPTIONAL]
-v <HOST_PATH_TO_JOB_MANAGER_PROPERTIES>:/opt/redislabs/redis-connect/config
-v <HOST_PATH_TO_CREDENTIALS>:/opt/redislabs/redis-connect/config/samples/credentials
-v <HOST_PATH_TO_EXTLIB>:/opt/redislabs/redis-connect/extlib [OPTIONAL]
-p 8282:8282

Usage: [-h|cli|start]
options:
-h: Print this help message and exit.
-v: Print version.
cli: init Redis Connect CLI
start: init Redis Connect Instance (Cluster Member)
-------------------------------
```

</p>
</details>