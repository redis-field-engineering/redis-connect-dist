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
gfsh>start server --name=server1 --bind-address=127.0.0.1 --cache-xml-file=/home/viragtripathi/redis-connect-gemfire/demo/config/samples/cdc/gemfire2redis/cache.xml

Start server2
gfsh>start server --name=server2 --bind-address=127.0.0.1 --cache-xml-file=/home/viragtripathi/redis-connect-gemfire/demo/config/samples/cdc/gemfire2redis/cache1.xml

Deploy jar for the initial loader process
gfsh>deploy --jar=/home/viragtripathi/redis-connect-gemfire/demo/extlib/connector-gemfire-fn-0.8.0.jar
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

----

### Initial Loader Steps
<details><summary><b>INSERT records into gemfire region(s) (source)</b></summary>

We are going to leverage a sample [Gemfire Producer](https://github.com/redis-field-engineering/redisconnect-gemfire-producer) for this task. Download and un-tar the latest [release](https://github.com/redis-field-engineering/redisconnect-gemfire-producer/releases) then run the sample gemfire producer

````bash
java -jar redisconnect-gemfire-producer-1.0-SNAPSHOT.jar --help
Usage: com.redis.connect.gemfire.producer.GemfireProducer [--help] [-h=<host>] [-i=<iter>] [-o=<opType>] [-p=<port>] [-r=<regionName>]
Gemfire producer load generator.
  -h, --host=<host>          Gemfire locator host (default: 127.0.0.1)
      --help                 Show this help message and exit
  -i, --iter=<iter>          Iterations to run (default: 1)
  -o, --operation=<opType>   Name of the operation i.e. I (put), U (put) and D (remove) (default: I)
  -p, --port=<port>          Gemfire locator port (default: 10334)
  -r, --region=<regionName>  Name of the region (default: session)
````

````bash
redisconnect-gemfire-producer$ java -jar redisconnect-gemfire-producer-1.0-SNAPSHOT.jar -i 100 -o I  
````

</details>

<details><summary><b>Stage pre-configured loader job</b></summary>
<p>

```bash
docker run \
-it --rm --privileged=true \
--name redis-connect-gemfire \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-gemfire/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-gemfire/config/samples/loader \
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
Staging Redis Connect redis-connect-gemfire v0.5.0.139 job using Java 11.0.13 on virag-cdc started by root in /opt/redislabs/redis-connect-gemfire/bin
Loading Redis Connect redis-connect-gemfire Configurations from /opt/redislabs/redis-connect-gemfire/config/samples/loader
04:05:17,742 |-INFO in ch.qos.logback.classic.LoggerContext[default] - Found resource [/opt/redislabs/redis-connect-gemfire/config/logback.xml] at [file:/opt/redislabs/redis-connect-gemfire/config/logback.xml]
....
04:05:17.981 [main] INFO  startup - ##################################################################
04:05:17.983 [main] INFO  startup -
04:05:17.983 [main] INFO  startup - REDIS CONNECT SETUP CLEAN - Deletes metadata related to Redis Connect from Job Management Database

04:05:17.983 [main] INFO  startup -
04:05:17.983 [main] INFO  startup - ##################################################################
....
04:05:20.212 [main] INFO  startup - ##################################################################
04:05:20.215 [main] INFO  startup -
04:05:20.215 [main] INFO  startup - REDIS CONNECT SETUP CREATE - Seed metadata related to Redis Connect to Job Management Database
04:05:20.215 [main] INFO  startup -
04:05:20.215 [main] INFO  startup - ##################################################################
....
04:05:21.567 [main] INFO  startup - Instance: 97@virag-cdc successfully established Redis connection for INIT service
04:05:21.570 [main] INFO  startup - Instance: 97@virag-cdc successfully created Job Claim Assignment Stream and Consumer Group
04:05:21.587 [main] INFO  startup - Instance: 97@virag-cdc successfully seeded Job related metadata
04:05:21.587 [main] INFO  startup - Instance: 97@virag-cdc successfully seeded Metrics related metadata
04:05:21.587 [main] INFO  startup - Instance: 97@virag-cdc successfully staged Job Management Database (Redis) with all the configurations and scripts, if applicable, needed to execute jobs
-------------------------------
```

</p>
</details>

<details><summary><b>Start pre-configured loader job</b></summary>
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
-------------------------------
Starting Redis Connect redis-connect-gemfire v0.5.0.139 instance using Java 11.0.13 on virag-cdc started by root in /opt/redislabs/redis-connect-gemfire/bin
Loading Redis Connect redis-connect-gemfire Configurations from /opt/redislabs/redis-connect-gemfire/config/samples/loader
04:06:16,684 |-INFO in ch.qos.logback.classic.LoggerContext[default] - Found resource [/opt/redislabs/redis-connect-gemfire/config/logback.xml] at [file:/opt/redislabs/redis-connect-gemfire/config/logback.xml]
....
04:06:16.959 [main] INFO  startup -
04:06:16.962 [main] INFO  startup -  /$$$$$$$                  /$$ /$$                  /$$$$$$                                                      /$$
04:06:16.962 [main] INFO  startup - | $$__  $$                | $$|__/                 /$$__  $$                                                    | $$
04:06:16.963 [main] INFO  startup - | $$  \ $$  /$$$$$$   /$$$$$$$ /$$  /$$$$$$$      | $$  \__/  /$$$$$$  /$$$$$$$  /$$$$$$$   /$$$$$$   /$$$$$$$ /$$$$$$
04:06:16.963 [main] INFO  startup - | $$$$$$$/ /$$__  $$ /$$__  $$| $$ /$$_____/      | $$       /$$__  $$| $$__  $$| $$__  $$ /$$__  $$ /$$_____/|_  $$_/
04:06:16.963 [main] INFO  startup - | $$__  $$| $$$$$$$$| $$  | $$| $$|  $$$$$$       | $$      | $$  \ $$| $$  \ $$| $$  \ $$| $$$$$$$$| $$        | $$
04:06:16.963 [main] INFO  startup - | $$  \ $$| $$_____/| $$  | $$| $$ \____  $$      | $$    $$| $$  | $$| $$  | $$| $$  | $$| $$_____/| $$        | $$ /$$
04:06:16.964 [main] INFO  startup - | $$  | $$|  $$$$$$$|  $$$$$$$| $$ /$$$$$$$/      |  $$$$$$/|  $$$$$$/| $$  | $$| $$  | $$|  $$$$$$$|  $$$$$$$  |  $$$$/
04:06:16.964 [main] INFO  startup - |__/  |__/ \_______/ \_______/|__/|_______/        \______/  \______/ |__/  |__/|__/  |__/ \_______/ \_______/   \___/
04:06:16.964 [main] INFO  startup -
04:06:16.964 [main] INFO  startup - ##################################################################
04:06:16.964 [main] INFO  startup -
04:06:16.964 [main] INFO  startup - Initializing Redis Connect Instance
04:06:16.964 [main] INFO  startup -
04:06:16.964 [main] INFO  startup - ##################################################################
....
04:06:23.290 [main] INFO  startup - Instance: 30@virag-cdc successfully established Redis connection for JobManager service
04:06:23.411 [main] INFO  startup - Instance: 30@virag-cdc successfully established PUB/SUB Redis connection
04:06:23.451 [main] INFO  startup - Instance: 30@virag-cdc successfully established PUB/SUB Redis connection
04:06:23.644 [main] INFO  startup - Instance: 30@virag-cdc successfully started JobManager service
04:06:23.683 [main] INFO  startup - Instance: 30@virag-cdc successfully established Redis connection for JobReaper service
04:06:23.684 [main] INFO  startup - Instance: 30@virag-cdc successfully started JobReaper service
04:06:23.720 [main] INFO  startup - Instance: 30@virag-cdc successfully established Redis connection for JobClaimer service
04:06:23.721 [main] INFO  startup - Instance: 30@virag-cdc successfully started JobClaimer service
04:06:23.769 [main] INFO  startup - Instance: 30@virag-cdc successfully subscribed to Channel: REDIS.CONNECT.JOB.CLAIM.TRANSITION.EVENTS
04:06:23.769 [main] INFO  startup - Instance: 30@virag-cdc did not enable embedded REST API server
04:06:33.683 [JobManager-1] INFO  startup - Instance: 30@virag-cdc successfully established Redis connection for HeartbeatManager service
04:06:33.684 [JobManager-1] INFO  startup - Instance: 30@virag-cdc was successfully elected Redis Connect cluster leader
04:06:44.814 [JobManager-1] INFO  startup - Instance: 30@virag-cdc successfully started job execution for JobId: {connect}:job:initial_load
04:06:44.814 [JobManager-1] INFO  startup - Instance: 30@virag-cdc has successfully claimed ownership of JobId: {connect}:job:initial_load
04:06:44.814 [JobManager-1] INFO  startup - Instance: 30@virag-cdc has claimed 1 job(s) from its 2 max allowable capacity
04:06:44.827 [JobManager-1] INFO  startup - JobId: {connect}:job:initial_load claim request with ID: 1641528321578-0 has been fully processed and all metadata has been updated
04:06:44.831 [JobManager-1] INFO  startup - Instance: 30@virag-cdc published Job Claim Transition Event to Channel: REDIS.CONNECT.JOB.CLAIM.TRANSITION.EVENTS Message: {"jobId":"{connect}:job:initial_load","instanceName":"30@virag-cdc","transitionEvent":"CLAIMED","serviceName":"JobClaimer"}
04:06:44.831 [lettuce-nioEventLoop-4-3] INFO  startup - Instance: 30@virag-cdc consumed Job Claim Transition Event on Channel: REDIS.CONNECT.JOB.CLAIM.TRANSITION.EVENTS Message: {"jobId":"{connect}:job:initial_load","instanceName":"30@virag-cdc","transitionEvent":"CLAIMED","serviceName":"JobClaimer"}
04:06:45.185 [EventProducer-1] WARN  startup - Instance: 30@virag-cdc did not find entry in its executor threads local cache during stop process for JobId: {connect}:job:initial_load
04:06:45.185 [EventProducer-1] WARN  startup - Instance: 30@virag-cdc could not cancel executor thread future for JobId: {connect}:job:initial_load
04:06:45.185 [EventProducer-1] INFO  startup - Instance: 30@virag-cdc successfully cancelled heartbeat for JobId: {connect}:job:initial_load
04:06:45.185 [EventProducer-1] INFO  startup - Instance: 30@virag-cdc successfully stopped replication pipeline for JobId: {connect}:job:initial_load
04:06:45.185 [EventProducer-1] INFO  startup - Instance: 30@virag-cdc now owns 0 job(s) from its 2 max allowable capacity
04:06:45.186 [EventProducer-1] INFO  startup - Instance: 30@virag-cdc successfully stopped JobId: {connect}:job:initial_load and added it to {connect}:jobs:stopped
....
04:07:13.919 [EventProducer-2] INFO  redisconnect - In Load
04:07:13.920 [JobManager-1] INFO  startup - Instance: 30@virag-cdc has claimed 1 job(s) from its 2 max allowable capacity
04:07:13.920 [EventProducer-2] INFO  redisconnect - Processing LoadSegment for Region : session , Bucket : 0
04:07:13.924 [JobManager-1] INFO  startup - JobId: session-0 claim request with ID: 1641528405159-0 has been fully processed and all metadata has been updated
....
04:07:14.099 [EventProducer-2] INFO  redisconnect - Completed Results For bucket : 22
04:07:14.106 [EventProducer-2] INFO  startup - Instance: 30@virag-cdc successfully cancelled heartbeat for JobId: session-0
04:07:14.106 [EventProducer-2] INFO  startup - Instance: 30@virag-cdc successfully stopped replication pipeline for JobId: session-0
04:07:14.106 [EventProducer-2] INFO  startup - Instance: 30@virag-cdc now owns 0 job(s) from its 2 max allowable capacity
04:07:14.106 [EventProducer-2] INFO  startup - Instance: 30@virag-cdc successfully stopped JobId: session-0 and added it to {connect}:jobs:stopped
....
04:07:43.763 [JobManager-2] INFO  startup - Instance: 30@virag-cdc successfully started job execution for JobId: session-1
04:07:43.763 [EventProducer-1] INFO  redisconnect - In Load
04:07:43.764 [EventProducer-1] INFO  redisconnect - Processing LoadSegment for Region : session , Bucket : 23
....
04:07:43.827 [EventProducer-1] INFO  redisconnect - Completed Results For bucket : 45
04:07:43.832 [EventProducer-1] WARN  startup - Instance: 30@virag-cdc could not cancel executor thread future for JobId: session-1
04:07:43.832 [EventProducer-1] INFO  startup - Instance: 30@virag-cdc successfully cancelled heartbeat for JobId: session-1
04:07:43.832 [EventProducer-1] INFO  startup - Instance: 30@virag-cdc successfully stopped replication pipeline for JobId: session-1
04:07:43.832 [EventProducer-1] INFO  startup - Instance: 30@virag-cdc now owns 0 job(s) from its 2 max allowable capacity
04:07:43.832 [EventProducer-1] INFO  startup - Instance: 30@virag-cdc successfully stopped JobId: session-1 and added it to {connect}:jobs:stopped
....
04:08:13.742 [EventProducer-2] INFO  redisconnect - In Load
04:08:13.742 [JobManager-1] INFO  startup - Instance: 30@virag-cdc has claimed 1 job(s) from its 2 max allowable capacity
04:08:13.742 [EventProducer-2] INFO  redisconnect - Processing LoadSegment for Region : session , Bucket : 46
....
04:08:13.797 [EventProducer-2] INFO  redisconnect - Completed Results For bucket : 68
04:08:13.801 [EventProducer-2] WARN  startup - Instance: 30@virag-cdc could not cancel executor thread future for JobId: session-2
04:08:13.801 [EventProducer-2] INFO  startup - Instance: 30@virag-cdc successfully cancelled heartbeat for JobId: session-2
04:08:13.802 [EventProducer-2] INFO  startup - Instance: 30@virag-cdc successfully stopped replication pipeline for JobId: session-2
04:08:13.802 [EventProducer-2] INFO  startup - Instance: 30@virag-cdc now owns 0 job(s) from its 2 max allowable capacity
04:08:13.802 [EventProducer-2] INFO  startup - Instance: 30@virag-cdc successfully stopped JobId: session-2 and added it to {connect}:jobs:stopped
....
04:08:43.733 [JobManager-1] INFO  startup - Instance: 30@virag-cdc successfully started job execution for JobId: session-3
04:08:43.733 [EventProducer-1] INFO  redisconnect - In Load
04:08:43.733 [JobManager-1] INFO  startup - Instance: 30@virag-cdc has successfully claimed ownership of JobId: session-3
04:08:43.733 [EventProducer-1] INFO  redisconnect - Processing LoadSegment for Region : session , Bucket : 69
....
04:08:43.787 [EventProducer-1] INFO  redisconnect - Completed Results For bucket : 90
04:08:43.791 [EventProducer-1] WARN  startup - Instance: 30@virag-cdc could not cancel executor thread future for JobId: session-3
04:08:43.791 [EventProducer-1] INFO  startup - Instance: 30@virag-cdc successfully cancelled heartbeat for JobId: session-3
04:08:43.791 [EventProducer-1] INFO  startup - Instance: 30@virag-cdc successfully stopped replication pipeline for JobId: session-3
04:08:43.791 [EventProducer-1] INFO  startup - Instance: 30@virag-cdc now owns 0 job(s) from its 2 max allowable capacity
04:08:43.791 [EventProducer-1] INFO  startup - Instance: 30@virag-cdc successfully stopped JobId: session-3 and added it to {connect}:jobs:stopped
....
04:09:13.735 [JobManager-1] INFO  startup - Instance: 30@virag-cdc successfully started job execution for JobId: session-4
04:09:13.735 [EventProducer-2] INFO  redisconnect - In Load
04:09:13.736 [JobManager-1] INFO  startup - Instance: 30@virag-cdc has successfully claimed ownership of JobId: session-4
04:09:13.736 [EventProducer-2] INFO  redisconnect - Processing LoadSegment for Region : session , Bucket : 91
....
04:09:13.785 [EventProducer-2] INFO  redisconnect - Processing LoadSegment for Region : session , Bucket : 112
04:09:13.786 [Function Execution Thread-1] INFO  redisconnect - Publishing data for Region : session , BucketId - 112 , Batch - 1 - num records in batch : 1
04:09:13.786 [Function Execution Thread-1] INFO  redisconnect - Total Records read for Region : session , BucketId - 112 , Total Records read : 1 ,
04:09:13.786 [EventProducer-2] INFO  redisconnect - Completed Results For bucket : 112
04:09:13.791 [EventProducer-2] WARN  startup - Instance: 30@virag-cdc could not cancel executor thread future for JobId: session-4
04:09:13.792 [EventProducer-2] INFO  startup - Instance: 30@virag-cdc successfully cancelled heartbeat for JobId: session-4
04:09:13.792 [EventProducer-2] INFO  startup - Instance: 30@virag-cdc successfully stopped replication pipeline for JobId: session-4
04:09:13.792 [EventProducer-2] INFO  startup - Instance: 30@virag-cdc now owns 0 job(s) from its 2 max allowable capacity
04:09:13.792 [EventProducer-2] INFO  startup - Instance: 30@virag-cdc successfully stopped JobId: session-4 and added it to {connect}:jobs:stopped
....
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

----

### CDC Steps
<details><summary><b>Stage pre-configured cdc job</b></summary>
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
redislabs/redis-connect-gemfire:latest stage
```

</p>
</details>

<details><summary>Expected output:</summary>
<p>

```bash
-------------------------------
Staging Redis Connect redis-connect-gemfire v0.5.0.135 job using Java 11.0.13 on virag-cdc started by root in /opt/redislabs/redis-connect-gemfire/bin
Loading Redis Connect redis-connect-gemfire Configurations from /opt/redislabs/redis-connect-gemfire/config/samples/cdc/gemfire2redis
....
17:39:43.212 [main] INFO  startup - ##################################################################
17:39:43.214 [main] INFO  startup -
17:39:43.214 [main] INFO  startup - REDIS CONNECT SETUP CLEAN - Deletes metadata related to Redis Connect from Job Management Database

17:39:43.214 [main] INFO  startup -
17:39:43.214 [main] INFO  startup - ##################################################################
....
17:39:45.566 [main] INFO  startup - ##################################################################
17:39:45.569 [main] INFO  startup -
17:39:45.569 [main] INFO  startup - REDIS CONNECT SETUP CREATE - Seed metadata related to Redis Connect to Job Management Database
17:39:45.569 [main] INFO  startup -
17:39:45.569 [main] INFO  startup - ##################################################################
....
17:39:47.250 [main] INFO  startup - Instance: 100@virag-cdc successfully seeded Metrics related metadata
17:39:47.250 [main] INFO  startup - Instance: 100@virag-cdc successfully staged Job Management Database (Redis) with all the configurations and scripts, if applicable, needed to execute jobs
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
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-gemfire/config/samples/cdc/gemfire2redis \
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
-------------------------------
Starting Redis Connect redis-connect-gemfire v0.5.0.135 instance using Java 11.0.13 on virag-cdc started by root in /opt/redislabs/redis-connect-gemfire/bin
Loading Redis Connect redis-connect-gemfire Configurations from /opt/redislabs/redis-connect-gemfire/config/samples/gemfire2redis
17:40:09,940 |-INFO in ch.qos.logback.classic.LoggerContext[default] - Found resource [/opt/redislabs/redis-connect-gemfire/config/logback.xml] at [file:/opt/redislabs/redis-connect-gemfire/config/logback.xml]
....
17:40:10.222 [main] INFO  startup -
17:40:10.225 [main] INFO  startup -  /$$$$$$$                  /$$ /$$                  /$$$$$$                                                      /$$
17:40:10.225 [main] INFO  startup - | $$__  $$                | $$|__/                 /$$__  $$                                                    | $$
17:40:10.226 [main] INFO  startup - | $$  \ $$  /$$$$$$   /$$$$$$$ /$$  /$$$$$$$      | $$  \__/  /$$$$$$  /$$$$$$$  /$$$$$$$   /$$$$$$   /$$$$$$$ /$$$$$$
17:40:10.226 [main] INFO  startup - | $$$$$$$/ /$$__  $$ /$$__  $$| $$ /$$_____/      | $$       /$$__  $$| $$__  $$| $$__  $$ /$$__  $$ /$$_____/|_  $$_/
17:40:10.226 [main] INFO  startup - | $$__  $$| $$$$$$$$| $$  | $$| $$|  $$$$$$       | $$      | $$  \ $$| $$  \ $$| $$  \ $$| $$$$$$$$| $$        | $$
17:40:10.226 [main] INFO  startup - | $$  \ $$| $$_____/| $$  | $$| $$ \____  $$      | $$    $$| $$  | $$| $$  | $$| $$  | $$| $$_____/| $$        | $$ /$$
17:40:10.227 [main] INFO  startup - | $$  | $$|  $$$$$$$|  $$$$$$$| $$ /$$$$$$$/      |  $$$$$$/|  $$$$$$/| $$  | $$| $$  | $$|  $$$$$$$|  $$$$$$$  |  $$$$/
17:40:10.227 [main] INFO  startup - |__/  |__/ \_______/ \_______/|__/|_______/        \______/  \______/ |__/  |__/|__/  |__/ \_______/ \_______/   \___/
17:40:10.227 [main] INFO  startup -
17:40:10.227 [main] INFO  startup - ##################################################################
17:40:10.227 [main] INFO  startup -
17:40:10.227 [main] INFO  startup - Initializing Redis Connect Instance
17:40:10.227 [main] INFO  startup -
17:40:10.227 [main] INFO  startup - ##################################################################
....
17:40:26.854 [JobManager-1] INFO  startup - Instance: 30@virag-cdc successfully established Redis connection for HeartbeatManager service
17:40:26.855 [JobManager-1] INFO  startup - Instance: 30@virag-cdc was successfully elected Redis Connect cluster leader
17:40:36.901 [JobManager-1] INFO  startup - Getting instance of EventHandler for : REDIS_KV_TO_STRING_WRITER
17:40:36.919 [JobManager-1] WARN  startup - metricsKey not set - Metrics collection will be disabled
17:40:36.929 [JobManager-1] INFO  startup - Instance: 30@virag-cdc successfully established Redis connection for RedisConnectorEventHandler service
17:40:36.933 [JobManager-1] INFO  startup - Getting instance of EventHandler for : REDIS_STRING_CHECKPOINT_WRITER
17:40:36.933 [JobManager-1] WARN  startup - metricsKey not set - Metrics collection will be disabled
17:40:36.943 [JobManager-1] INFO  startup - Instance: 30@virag-cdc successfully established Redis connection for RedisCheckpointReader service
17:40:38.237 [JobManager-1] INFO  startup - Client with clientId : {connect}:job:job1 connecting for the first time
17:40:38.240 [JobManager-1] INFO  startup - Instance: 30@virag-cdc successfully started job execution for JobId: {connect}:job:job1
17:40:38.241 [JobManager-1] INFO  startup - Instance: 30@virag-cdc has successfully claimed ownership of JobId: {connect}:job:job1
17:40:38.241 [JobManager-1] INFO  startup - Instance: 30@virag-cdc has claimed 1 job(s) from its 2 max allowable capacity
17:40:38.254 [JobManager-1] INFO  startup - JobId: {connect}:job:job1 claim request with ID: 1641490787024-0 has been fully processed and all metadata has been updated
17:40:38.258 [JobManager-1] INFO  startup - Instance: 30@virag-cdc published Job Claim Transition Event to Channel: REDIS.CONNECT.JOB.CLAIM.TRANSITION.EVENTS Message: {"jobId":"{connect}:job:job1","instanceName":"30@virag-cdc","transitionEvent":"CLAIMED","serviceName":"JobClaimer"}
17:40:38.258 [lettuce-nioEventLoop-4-3] INFO  startup - Instance: 30@virag-cdc consumed Job Claim Transition Event on Channel: REDIS.CONNECT.JOB.CLAIM.TRANSITION.EVENTS Message: {"jobId":"{connect}:job:job1","instanceName":"30@virag-cdc","transitionEvent":"CLAIMED","serviceName":"JobClaimer"}
```

</p>
</details>

<details><summary><b>INSERT a record into gemfire region (source)</b></summary>
<p>

```bash
gfsh> put --key='redis123' --value='Hello Redis!!' --region=/session
```

</p>
</details>

<details><summary><b>Query for the above inserted record in Redis (target)</b></summary>
<p>

```bash
demo$ sudo docker exec -it re-node1 bash -c 'redis-cli -p 12000 get redis123'
"Hello Redis!!"
```

</p>
</details>

Similarly `UPDATE` and `DELETE` records on Gemfire source and see Redis target getting updated in near real-time.

<details><summary><b>UPDATE a record into gemfire region (source)</b></summary>
<p>

```bash
gfsh> put --key='redis123' --value='Hello World!!' --region=/session
```

</p>
</details>

<details><summary><b>DELETE a record from gemfire region (source)</b></summary>
<p>

```bash
gfsh> remove --region=/session --key='redis123'
```

</p>
</details>
