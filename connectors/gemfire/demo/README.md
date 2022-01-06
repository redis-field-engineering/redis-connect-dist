# Prerequisites
Docker compatible [*nix OS](https://en.wikipedia.org/wiki/Unix-like) and [Docker](https://docs.docker.com/get-docker) installed.
<br>Please have 8 vCPU*, 8 GB RAM and 50 GB storage for this demo to function properly. Adjust the resources based on your requirements. For HA, at least have 2 Redis Connect Connector instances deployed on separate hosts.</br>
<br>Execute the following commands (copy & paste) to download and setup Redis Connect Gemfire Connector and demo scripts.
i.e.</br>

```bash
wget -c https://github.com/redis-field-engineering/redis-connect-dist/archive/main.zip && \
mkdir -p redis-connect-gemfire/demo && \
mkdir -p redis-connect-gemfire/k8s-docs && \
unzip main.zip "redis-connect-dist-main/connectors/gemfire/*" -d redis-connect-gemfire && \
cp -R redis-connect-gemfire/redis-connect-dist-main/connectors/gemfire/demo/* redis-connect-gemfire/demo && \
cp -R redis-connect-gemfire/redis-connect-dist-main/connectors/gemfire/k8s-docs/* redis-connect-gemfire/k8s-docs && \
rm -rf main.zip redis-connect-gemfire/redis-connect-dist-main && \
cd redis-connect-gemfire && \
chmod a+x demo/*.sh
```

Expected output:
```bash
redis-connect-gemfire$ ls
config demo
```

## Setup Gemfire (Source)
Please refer to the installation guide and [Insall and Setup Gemfire](https://gemfire.docs.pivotal.io/910/gemfire/getting_started/installation/install_intro.html).

Here is an example with the included cache config files in the `redis-connect-gemfire/config/samples/gemfire2redis` folder.

```bash
~/pivotal-gemfire-9.10.4/bin$ ./gfsh
    _________________________     __
   / _____/ ______/ ______/ /____/ /
  / /  __/ /___  /_____  / _____  / 
 / /__/ / ____/  _____/ / /    / /  
/______/_/      /______/_/    /_/    9.10.4

Monitor and Manage VMware Tanzu GemFire
Start locator
gfsh>start locator --name=locator1 --bind-address=127.0.0.1

Start server1
gfsh>start server --name=server1 --bind-address=127.0.0.1 --cache-xml-file=~/redis-connect-gemfire/config/samples/cdc/gemfire2redis/cache.xml

Start server2
gfsh>start server --name=server2 --bind-address=127.0.0.1 --cache-xml-file=~/redis-connect-gemfire/config/samples/cdc/gemfire2redis/cache1.xml

Deploy jar for the initial loader process
gfsh>deploy --jar=~/redis-connect-gemfire/lib/connector-gemfire-fn-0.8.0.jar
```

## Setup Redis Enterprise cluster, databases and RedisInsight in docker (Target)
<br>Execute [setup_re.sh](setup_re.sh)</br>
```bash
demo$ ./setup_re.sh
```
**NOTE**

The above script will create a 1-node Redis Enterprise cluster in a docker container, [Create a target database with RediSearch module](https://docs.redislabs.com/latest/modules/add-module-to-database/), [Create a job management and metrics database with RedisTimeSeries module](https://docs.redislabs.com/latest/modules/add-module-to-database/), [Create a RediSearch index for emp Hash](https://redislabs.com/blog/getting-started-with-redisearch-2-0/), [Start a docker instance of grafana with Redis Data Source](https://redisgrafana.github.io/) and [Start an instance of RedisInsight](https://docs.redislabs.com/latest/ri/installing/install-docker/).

## Start Redis Connect Gemfire Connector

<details><summary>Run Redis Connect Gemfire Connector docker container to see all the options</summary>
<p>

```bash
docker run \
-it --rm --privileged=true \
--name redis-connect-gemfire \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-gemfire/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-gemfire/config/samples/cdc/gemfire2redis \
-e REDISCONNECT_JAVA_OPTIONS="-Xms256m -Xmx256m" \
-v $(pwd)/config:/opt/redislabs/redis-connect-gemfire/config \
--net host \
redislabs/redis-connect-gemfire:latest
```

</p>
</details>

<details><summary>Expected output:</summary>
<p>
  
```bash
-------------------------------
Redis Connect startup script.
*******************************
Please ensure that the values of environment variables in /opt/redislabs/redis-connect-gemfire/bin/redisconnect.conf are correctly mapped before executing any of the options below
*******************************
Usage: [-h|cli|stage|start]
options:
-h: Print this help message and exit.
cli: starts redis-connect-cli.
stage: clean and stage redis database with cdc or initial loader job configurations.
start: start Redis Connect instance with provided cdc or initial loader job configurations.
-------------------------------
```

</p>
</details>

-------------------------------

### Initial Loader Steps
<details><summary><b>INSERT few records into gemfire table (source)</b></summary>
<p>

```bash

```

</p>
</details>

<details><summary><b>Stage pre-configured loader job</b></summary>
<p>

```bash
docker run \
-it --rm --privileged=true \
--name redis-connect-gemfire \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-gemfire/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-gemfire/config/samples/loader \
-e REDISCONNECT_SOURCE_USERNAME= \
-e REDISCONNECT_SOURCE_PASSWORD= \
-e REDISCONNECT_JAVA_OPTIONS="-Xms256m -Xmx256m" \
-v $(pwd)/config:/opt/redislabs/redis-connect-gemfire/config \
--net host \
redislabs/redis-connect-gemfire:latest stage
```

</p>
</details>

<details><summary>Expected output:</summary>
<p>

```bash
-------------------------------
Staging Redis Connect redis-connect-gemfire v1.0.2.151 job using Java 11.0.12 on 16229e5715a1 started by root in /opt/redislabs/redis-connect-gemfire/bin
Loading Redis Connect redis-connect-gemfire Configurations from /opt/redislabs/redis-connect-gemfire/config/samples/loader
.....
.....
12:31:38.726 [main] INFO  startup - Setup Completed.
-------------------------------
```

</p>
</details>

<details><summary><b>Start pre configured loader job</b></summary>
<p>

```bash
docker run \
-it --rm --privileged=true \
--name redis-connect-gemfire \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-gemfire/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-gemfire/config/samples/loader \
-e REDISCONNECT_REST_API_ENABLED=false \
-e REDISCONNECT_REST_API_PORT=8282 \
-e REDISCONNECT_JAVA_OPTIONS="-Xms256m -Xmx1g" \
-v $(pwd)/config:/opt/redislabs/redis-connect-gemfire/config \
--net host \
redislabs/redis-connect-gemfire:latest start
```

</p>
</details>

<details><summary>Expected output:</summary>
<p>

```bash

```

</p>
</details>

<details><summary><b>Query for the above inserted record in Redis (target)</b></summary>
<p>

```bash
demo$ sudo docker exec -it re-node1 bash -c 'redis-cli -p 12000'

```

</p>
</details>

-------------------------------

### CDC Steps
<details><summary><b>Stage pre-configured cdc job</b></summary>
<p>

```bash
docker run \
-it --rm --privileged=true \
--name redis-connect-gemfire \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-gemfire/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-gemfire/config/samples/gemfire2redis \
-e REDISCONNECT_JAVA_OPTIONS="-Xms256m -Xmx256m" \
-v $(pwd)/config:/opt/redislabs/redis-connect-gemfire/config \
--net host \
redislabs/redis-connect-gemfire:latest stage
```

</p>
</details>

<details><summary>Expected output:</summary>
<p>

```bash
-------------------------------
Staging Redis Connect redis-connect-gemfire v1.0.2.151 job using Java 11.0.12 on virag-cdc started by root in /opt/redislabs/redis-connect-gemfire/bin.
Loading Redis Connect redis-connect-gemfire Configurations from /opt/redislabs/redis-connect-gemfire/config/samples/gemfire.
.....
.....
20:15:06.819 [main] INFO  startup - Setup Completed.
-------------------------------
```

</p>
</details>

<details><summary><b>Start pre-configured cdc job</b></summary>
<p>

```bash
docker run \
-it --rm --privileged=true \
--name redis-connect-gemfire \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-gemfire/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-gemfire/config/samples/gemfire2redis \
-e REDISCONNECT_REST_API_ENABLED=true \
-e REDISCONNECT_REST_API_PORT=8282 \
-e REDISCONNECT_JAVA_OPTIONS="-Xms256m -Xmx1g" \
-v $(pwd)/config:/opt/redislabs/redis-connect-gemfire/config \
--net host \
redislabs/redis-connect-gemfire:latest start
```

</p>
</details>

<details><summary>Expected output:</summary>
<p>

```bash
```

</p>
</details>

<details><summary><b>INSERT a record into gemfire table (source)</b></summary>
<p>

```bash

```

</p>
</details>

<details><summary><b>Query for the above inserted record in Redis (target)</b></summary>
<p>

```bash
demo$ sudo docker exec -it re-node1 bash -c 'redis-cli -p 12000'

```

</p>
</details>

Similarly `UPDATE` and `DELETE` records on Gemfire source and see Redis target getting updated in near real-time.

-------------------------------

### [_Custom Stage_](https://github.com/redis-field-engineering/redis-connect-custom-stage-demo)

Review the Custom Stage Demo then use the pre-built CustomStage function by passing it as an external library then follow the same [Initial Loader Steps](#initial-loader-steps) and [CDC Steps](#cdc-steps).

Add the `CustomStage` `handlerId` in JobConfig.yml as explained in the Custom Stage Demo i.e.
```yml
  stages:
    CustomStage:
      handlerId: TO_UPPER_CASE
```
<details><summary><b>Stage pre-configured loader job with Custom Stage</b></summary>
<p>

```bash
docker run \
-it --rm --privileged=true \
--name redis-connect-gemfire \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-gemfire/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-gemfire/config/samples/loader \
-e REDISCONNECT_SOURCE_USERNAME=redisconnect \
-e REDISCONNECT_SOURCE_PASSWORD=Redis@123 \
-e REDISCONNECT_JAVA_OPTIONS="-Xms256m -Xmx256m" \
-v $(pwd)/config:/opt/redislabs/redis-connect-gemfire/config \
-v $(pwd)/extlib:/opt/redislabs/redis-connect-gemfire/extlib \
--net host \
redislabs/redis-connect-gemfire:latest stage
```

</p>
</details>

<details><summary><b>Start pre-configured loader job with Custom Stage</b></summary>
<p>

```bash
docker run \
-it --rm --privileged=true \
--name redis-connect-gemfire \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-gemfire/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-gemfire/config/samples/loader \
-e REDISCONNECT_REST_API_ENABLED=false \
-e REDISCONNECT_REST_API_PORT=8282 \
-e REDISCONNECT_SOURCE_USERNAME= \
-e REDISCONNECT_SOURCE_PASSWORD= \
-e REDISCONNECT_JAVA_OPTIONS="-Xms256m -Xmx1g" \
-v $(pwd)/config:/opt/redislabs/redis-connect-gemfire/config \
-v $(pwd)/extlib:/opt/redislabs/redis-connect-gemfire/extlib \
--net host \
redislabs/redis-connect-gemfire:latest start
```

</p>
</details>

Validate the output after CustomStage run and make sure that `fname` and `lname` values in Redis has been updated to UPPER CASE.
