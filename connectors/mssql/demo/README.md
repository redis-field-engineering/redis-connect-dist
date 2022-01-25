# Prerequisites

Docker compatible [*nix OS](https://en.wikipedia.org/wiki/Unix-like) and [Docker](https://docs.docker.com/get-docker) installed.
<br>Please have 8 vCPU*, 8GB RAM and 50GB storage for this demo to function properly. Adjust the resources based on your requirements. For HA, at least have 2 Redis Connect Connector instances deployed on separate hosts.</br>
<br>Execute the following commands (copy & paste) to download and setup Redis Connect MSSQL Connector and demo scripts.
i.e.</br>

```bash
wget -c https://github.com/redis-field-engineering/redis-connect-dist/archive/main.zip && \
mkdir -p redis-connect-sqlserver/demo && \
mkdir -p redis-connect-sqlserver/k8s-docs && \
unzip main.zip "redis-connect-dist-main/connectors/mssql/*" -d redis-connect-sqlserver && \
cp -R redis-connect-sqlserver/redis-connect-dist-main/connectors/mssql/demo/* redis-connect-sqlserver/demo && \
cp -R redis-connect-sqlserver/redis-connect-dist-main/connectors/mssql/k8s-docs/* redis-connect-sqlserver/k8s-docs && \
rm -rf main.zip redis-connect-sqlserver/redis-connect-dist-main && \
cd redis-connect-sqlserver && \
chmod a+x demo/*.sh
```

Expected output:
```bash
redis-connect-sqlserver$ ls
config demo
```

## Setup MSSQL 2017 database in docker (Source)

<br>Execute [setup_mssql.sh](setup_mssql.sh)</br>
```bash
redis-connect-sqlserver$ cd demo
demo$ ./setup_mssql.sh 2017-latest
```

<details><summary>Validate MS SQL Server database is running as expected:</summary>
<p>

```bash
demo$ docker ps -a | grep mssql
8734c894f926        mcr.microsoft.com/mssql/server:2017-latest   "/opt/mssql/bin/nonr…"   2 days ago          Up 2 days           0.0.0.0:1433->1433/tcp                                                                                                                                                                                                                                                                                          mssql-2017-latest-virag-cdc

demo$ docker exec -it mssql-2017-latest-virag-cdc /opt/mssql-tools/bin/sqlcmd -S 127.0.0.1 -U sa -P Redis@123 -y80 -Y 40 -Q 'use RedisConnect;exec sys.sp_cdc_help_change_data_capture;'
Changed database context to 'RedisConnect'.
source_schema                            source_table                             capture_instance                         object_id   source_object_id start_lsn              end_lsn                supports_net_changes has_drop_pending role_name                                index_name                               filegroup_name                           create_date             index_column_list                                                                captured_column_list
---------------------------------------- ---------------------------------------- ---------------------------------------- ----------- ---------------- ---------------------- ---------------------- -------------------- ---------------- ---------------------------------------- ---------------------------------------- ---------------------------------------- ----------------------- -------------------------------------------------------------------------------- --------------------------------------------------------------------------------
dbo                                      emp                                      cdcauditing_emp                           1269579561       1237579447 0x0000002400000B100060 NULL                                      1             NULL NULL                                     PK__emp__AF4C318A4ABE3B75                NULL                                     2021-05-17 15:16:27.013 [empno]                                                                          [empno], [fname], [lname], [job], [mgr], [hiredate], [sal], [comm], [dept]
```
</p>
</details>

---
**NOTE**

The above script will start a [MSSQL 2017 docker](https://hub.docker.com/layers/microsoft/mssql-server-linux/2017-latest/images/sha256-314918ddaedfedc0345d3191546d800bd7f28bae180541c9b8b45776d322c8c2?context=explore) instance, create RedisConnect database, enable cdc on the database, create emp table and enable cdc on the table.

---

## Setup Redis Enterprise cluster, databases and RedisInsight in docker (Target)
<br>Execute [setup_re.sh](setup_re.sh)</br>
```bash
demo$ ./setup_re.sh
```
<details><summary>Validate Redis databases and RedisInsight is running as expected:</summary>
<p>

```bash
demo$ docker ps -a | grep redislabs
8c008000ff5c        redislabs/redisinsight:latest              "bash ./docker-entry…"   2 hours ago         Up 2 hours          0.0.0.0:18001->8001/tcp                                                                                                                                                                                                                                                                                         redisinsight
8fe702a340a9        redislabs/redis:latest                     "/opt/start.sh"          2 hours ago         Up 2 hours          53/tcp, 5353/tcp, 8001/tcp, 8080/tcp, 10000-11999/tcp, 12006-19999/tcp, 0.0.0.0:18070->8070/tcp, 0.0.0.0:18443->8443/tcp, 0.0.0.0:19443->9443/tcp, 0.0.0.0:14000->12000/tcp, 0.0.0.0:14001->12001/tcp, 0.0.0.0:14002->12002/tcp, 0.0.0.0:14003->12003/tcp, 0.0.0.0:14004->12004/tcp, 0.0.0.0:14005->12005/tcp   re-node1

demo$ docker exec -it re-node1 bash -c "rladmin status"
CLUSTER NODES:
NODE:ID    ROLE     ADDRESS        EXTERNAL_ADDRESS       HOSTNAME    SHARDS   CORES         FREE_RAM              PROVISIONAL_RAM       VERSION     STATUS
*node:1    master   172.17.0.2                            re-node1    2/100    16            51.17GB/58.87GB       38.71GB/48.28GB       6.2.8-39    OK

DATABASES:
DB:ID       NAME                                   TYPE  MODULE  STATUS  SHARDS  PLACEMENT  REPLICATION  PERSISTENCE  ENDPOINT
db:1        RedisConnect-Target-db                 redis yes     active  1       dense      disabled     disabled     redis-12000.re-cluster.local:12000
db:2        RedisConnect-JobConfig-Metrics-db      redis yes     active  1       dense      disabled     disabled     redis-12001.re-cluster.local:12001

ENDPOINTS:
DB:ID        NAME                                                                       ID                          NODE           ROLE           SSL
db:1         RedisConnect-Target-db                                                     endpoint:1:1                node:1         single         No
db:2         RedisConnect-JobConfig-Metrics-db                                          endpoint:2:1                node:1         single         No

SHARDS:
DB:ID         NAME                                                        ID            NODE        ROLE        SLOTS         USED_MEMORY          STATUS
db:1          RedisConnect-Target-db                                      redis:1       node:1      master      0-16383       2.3MB                OK
db:2          RedisConnect-JobConfig-Metrics-db                           redis:2       node:1      master      0-16383       1.99MB               OK

demo$ docker exec -it re-node1 bash -c "redis-cli -p 12000 FT._LIST"
1) "idx:emp"
```
</p>
</details>

---
**NOTE**

The above script will create a 1-node Redis Enterprise cluster in a docker container, [Create a target database with RediSearch module](https://docs.redislabs.com/latest/modules/add-module-to-database/), [Create a job management and metrics database with RedisTimeSeries module](https://docs.redislabs.com/latest/modules/add-module-to-database/), [Create a RediSearch index for emp Hash](https://redislabs.com/blog/getting-started-with-redisearch-2-0/) and [Start an instance of RedisInsight](https://docs.redislabs.com/latest/ri/installing/install-docker/).

---

## Start Redis Connect SQL Server Connector

<details><summary>Run Redis Connect SQL Server Connector docker container to see all the options</summary>
<p>

```bash
docker run \
-it --rm --privileged=true \
--name redis-connect-sqlserver \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-sqlserver/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-sqlserver/config/samples/sqlserver \
-e REDISCONNECT_SOURCE_USERNAME=sa \
-e REDISCONNECT_SOURCE_PASSWORD=Redis@123 \
-e REDISCONNECT_JAVA_OPTIONS="-Xms256m -Xmx256m" \
-v $(pwd)/config:/opt/redislabs/redis-connect-sqlserver/config \
--net host \
redislabs/redis-connect-sqlserver:latest
```

</p>
</details>

<details><summary>Expected output:</summary>
<p>

```bash
Unable to find image 'redislabs/redis-connect-sqlserver:latest' locally
latest: Pulling from redislabs/redis-connect-sqlserver
97518928ae5f: Already exists
26772c6968c6: Already exists
48655185183c: Pull complete
2c0f578e2555: Pull complete
4f4fb700ef54: Pull complete
832d0ea768ff: Pull complete
944f0df34b56: Pull complete
91a83d83d274: Pull complete
9ab9bfb1b56c: Pull complete
6392eb76e411: Pull complete
b1fe6707141f: Pull complete
Digest: sha256:e772b62eba3434336d81986dc65d028401ab77ece369364262ac05de20c6337c
Status: Downloaded newer image for redislabs/redis-connect-sqlserver:latest
-------------------------------
Redis Connect startup script.
*******************************
Please ensure that the values of environment variables in /opt/redislabs/redis-connect-sqlserver/bin/redisconnect.conf are correctly mapped before executing any of the options below
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
<details><summary><b>INSERT few records into SQL Server table (source) using the insert.sql or create a more realistic load using https://github.com/redis-field-engineering/redis-connect-crud-loader</b></summary>
<p>

```bash
demo$ ./insert_mssql.sh
```
OR
```bash
redis-connect-crud-loader/bin$ ./start.sh crudloader
```

</p>
</details>

<details><summary><b>Stage pre-configured loader job</b></summary>
<p>

```bash
docker run \
-it --rm --privileged=true \
--name redis-connect-sqlserver \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-sqlserver/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-sqlserver/config/samples/loader \
-e REDISCONNECT_SOURCE_USERNAME=sa \
-e REDISCONNECT_SOURCE_PASSWORD=Redis@123 \
-e REDISCONNECT_JAVA_OPTIONS="-Xms256m -Xmx256m" \
-v $(pwd)/config:/opt/redislabs/redis-connect-sqlserver/config \
--net host \
redislabs/redis-connect-sqlserver:latest stage
```

</p>
</details>

<details><summary>Expected output:</summary>
<p>

```bash
-------------------------------
Staging Redis Connect redis-connect-sqlserver v0.8.0.139 job using Java 11.0.14 on virag-cdc started by root in /opt/redislabs/redis-connect-sqlserver/bin
Loading Redis Connect redis-connect-sqlserver Configurations from /opt/redislabs/redis-connect-sqlserver/config/samples/loader
20:48:36,060 |-INFO in ch.qos.logback.classic.LoggerContext[default] - Found resource [/opt/redislabs/redis-connect-sqlserver/config/logback.xml] at [file:/opt/redislabs/redis-connect-sqlserver/config/logback.xml]
....
20:48:36.349 [main] INFO  redis-connect-manager - ##################################################################
20:48:36.353 [main] INFO  redis-connect-manager -
20:48:36.353 [main] INFO  redis-connect-manager - REDIS CONNECT SETUP CLEAN - Deletes metadata related to Redis Connect from Job Management Database

20:48:36.354 [main] INFO  redis-connect-manager -
20:48:36.354 [main] INFO  redis-connect-manager - ##################################################################
20:48:37.156 [main] INFO  redis-connect-manager - Instance: 30@virag-cdc will attempt to delete (clean) all the metadata related to Redis Connect
20:48:38.017 [main] INFO  redis-connect-manager - Instance: 30@virag-cdc successfully established Redis connection for INIT service
20:48:38.036 [main] INFO  redis-connect-manager - Instance: 30@virag-cdc successfully completed flush (clean) of all the metadata related to Redis Connect
20:48:38,555 |-INFO in ch.qos.logback.classic.LoggerContext[default] - Found resource [/opt/redislabs/redis-connect-sqlserver/config/logback.xml] at [file:/opt/redislabs/redis-connect-sqlserver/config/logback.xml]
....
20:48:38.839 [main] INFO  redis-connect-manager - ##################################################################
20:48:38.842 [main] INFO  redis-connect-manager -
20:48:38.843 [main] INFO  redis-connect-manager - REDIS CONNECT SETUP CREATE - Seed metadata related to Redis Connect to Job Management Database
20:48:38.843 [main] INFO  redis-connect-manager -
20:48:38.843 [main] INFO  redis-connect-manager - ##################################################################
20:48:39.690 [main] INFO  redis-connect-manager - Instance: 98@virag-cdc will attempt Job Management Database (Redis) with all the configurations and scripts, if applicable, needed to execute jobs
20:48:40.615 [main] INFO  redis-connect-manager - Instance: 98@virag-cdc successfully established Redis connection for INIT service
20:48:40.619 [main] INFO  redis-connect-manager - Instance: 98@virag-cdc successfully created Job Claim Assignment Stream and Consumer Group
20:48:40.637 [main] INFO  redis-connect-manager - Instance: 98@virag-cdc successfully seeded Job related metadata
20:48:40.637 [main] INFO  redis-connect-manager - Instance: 98@virag-cdc successfully seeded Metrics related metadata
20:48:40.638 [main] INFO  redis-connect-manager - Instance: 98@virag-cdc successfully staged Job Management Database (Redis) with all the configurations and scripts, if applicable, needed to execute jobs
-------------------------------
```

</p>
</details>

<details><summary><b>Start pre configured loader job</b></summary>
<p>

```bash
docker run \
-it --rm --privileged=true \
--name redis-connect-sqlserver \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-sqlserver/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-sqlserver/config/samples/loader \
-e REDISCONNECT_REST_API_ENABLED=false \
-e REDISCONNECT_REST_API_PORT=8282 \
-e REDISCONNECT_SOURCE_USERNAME=sa \
-e REDISCONNECT_SOURCE_PASSWORD=Redis@123 \
-e REDISCONNECT_JAVA_OPTIONS="-Xms256m -Xmx1g" \
-v $(pwd)/config:/opt/redislabs/redis-connect-sqlserver/config \
--net host \
redislabs/redis-connect-sqlserver:latest start
```

</p>
</details>

<details><summary>Expected output:</summary>
<p>

```bash
Starting Redis Connect redis-connect-sqlserver v0.8.0.139 instance using Java 11.0.14 on virag-cdc started by root in /opt/redislabs/redis-connect-sqlserver/bin
Loading Redis Connect redis-connect-sqlserver Configurations from /opt/redislabs/redis-connect-sqlserver/config/samples/loader
20:50:42,924 |-INFO in ch.qos.logback.classic.LoggerContext[default] - Found resource [/opt/redislabs/redis-connect-sqlserver/config/logback.xml] at [file:/opt/redislabs/redis-connect-sqlserver/config/logback.xml]
....
20:50:43.280 [main] INFO  redis-connect-manager -
  /#######                  /## /##          	  /######                                                      /##
 | ##__  ##                | ## |__/          	 /##__  ##                                                    | ##
 | ##  \ ##  /######   /####### /##  /#######	| ##  \__/  /######  /#######  /#######   /######   /####### /######
 | #######/ /##__  ## /##__  ##| ## /##_____/	| ##       /##__  ##| ##__  ##| ##__  ## /##__  ## /##_____/|_  ##_/
 | ##__  ##| ########| ##  | ##| ##|  ###### 	| ##      | ##  \ ##| ##  \ ##| ##  \ ##| ########| ##        | ##
 | ##  \ ##| ##_____/| ##  | ##| ## \____  ##	| ##    ##| ##  | ##| ##  | ##| ##  | ##| ##_____/| ##        | ## /##
 | ##  | ##|  #######|  #######| ## /#######/	|  ######/|  ######/| ##  | ##| ##  | ##|  #######|  #######  |  ####/
 |__/  |__/ \_______/ \_______/|__/|_______/ 	 \______/  \______/ |__/  |__/|__/  |__/ \_______/ \_______/   \___/
Powered by Redis Enterprise
20:50:43.285 [main] INFO  redis-connect-manager -
20:50:43.285 [main] INFO  redis-connect-manager - ----------------------------------------------------------------------------------------------------------------------------
20:50:43.285 [main] INFO  redis-connect-manager -
20:50:43.285 [main] INFO  redis-connect-manager - Initializing Redis Connect Instance
20:50:43.285 [main] INFO  redis-connect-manager -
20:50:43.285 [main] INFO  redis-connect-manager - ----------------------------------------------------------------------------------------------------------------------------
20:50:50.006 [main] INFO  redis-connect-manager - Instance: 30@virag-cdc successfully established Redis connection for JobManager service
20:50:50.126 [main] INFO  redis-connect-manager - Instance: 30@virag-cdc successfully established PUB/SUB Redis connection
20:50:50.147 [main] INFO  redis-connect-manager - Instance: 30@virag-cdc successfully established PUB/SUB Redis connection
20:50:50.296 [main] INFO  redis-connect-manager - Instance: 30@virag-cdc successfully started JobManager service
20:50:50.318 [main] INFO  redis-connect-manager - Instance: 30@virag-cdc successfully established Redis connection for JobReaper service
20:50:50.319 [main] INFO  redis-connect-manager - Instance: 30@virag-cdc successfully started JobReaper service
20:50:50.344 [main] INFO  redis-connect-manager - Instance: 30@virag-cdc successfully established Redis connection for JobClaimer service
20:50:50.345 [main] INFO  redis-connect-manager - Instance: 30@virag-cdc successfully started JobClaimer service
20:50:50.351 [main] INFO  redis-connect-manager - Instance: 30@virag-cdc successfully subscribed to Channel: REDIS.CONNECT.JOB.CLAIM.TRANSITION.EVENTS
20:50:50.351 [main] INFO  redis-connect-manager - Instance: 30@virag-cdc did not enable embedded REST API server
20:51:10.837 [JobManager-2] INFO  redis-connect-manager - Instance: 30@virag-cdc successfully started job execution for JobId: {connect}:job:initial_load
20:51:10.861 [JobManager-2] INFO  redis-connect-manager - Instance: 30@virag-cdc successfully established Redis connection for HeartbeatManager service
20:51:10.862 [JobManager-2] INFO  redis-connect-manager - Instance: 30@virag-cdc has successfully claimed ownership of JobId: {connect}:job:initial_load
20:51:10.862 [JobManager-2] INFO  redis-connect-manager - Instance: 30@virag-cdc has claimed 1 job(s) from its 2 max allowable capacity
20:51:10.865 [JobManager-1] INFO  redis-connect-heartbeat - Instance: 30@virag-cdc successfully refreshed Heartbeat: {connect}:heartbeat:job:initial_load with value: 30@virag-cdc to new Lease: 30000
20:51:10.874 [JobManager-2] INFO  redis-connect-manager - JobId: {connect}:job:initial_load claim request with ID: 1643057320627-0 has been fully processed and all metadata has been updated
20:51:10.877 [JobManager-2] INFO  redis-connect-manager - Instance: 30@virag-cdc published Job Claim Transition Event to Channel: REDIS.CONNECT.JOB.CLAIM.TRANSITION.EVENTS Message: {"jobId":"{connect}:job:initial_load","instanceName":"30@virag-cdc","transitionEvent":"CLAIMED","serviceName":"JobClaimer"}
20:51:10.878 [lettuce-nioEventLoop-4-3] INFO  redis-connect-manager - Instance: 30@virag-cdc consumed Job Claim Transition Event on Channel: REDIS.CONNECT.JOB.CLAIM.TRANSITION.EVENTS Message: {"jobId":"{connect}:job:initial_load","instanceName":"30@virag-cdc","transitionEvent":"CLAIMED","serviceName":"JobClaimer"}
20:51:20.894 [EventProducer-1] WARN  redis-connect-manager - Instance: 30@virag-cdc did not find entry in its executor threads local cache during stop process for JobId: {connect}:job:initial_load
20:51:20.895 [EventProducer-1] INFO  redis-connect-manager - Instance: 30@virag-cdc successfully cancelled heartbeat for JobId: {connect}:job:initial_load
20:51:20.895 [EventProducer-1] INFO  redis-connect-manager - Instance: 30@virag-cdc successfully stopped replication pipeline for JobId: {connect}:job:initial_load
20:51:20.895 [EventProducer-1] INFO  redis-connect-manager - Instance: 30@virag-cdc now owns 0 job(s) from its 2 max allowable capacity
20:51:20.895 [EventProducer-1] INFO  redis-connect-manager - Instance: 30@virag-cdc successfully stopped JobId: {connect}:job:initial_load and added it to {connect}:jobs:stopped
20:51:40.396 [JobManager-1] INFO  redis-connect-manager - Instance: 30@virag-cdc successfully established Redis connection for RedisCheckpointReader service
20:51:40.476 [JobManager-1] INFO  redis-connect-manager - Instance: 30@virag-cdc successfully established Redis connection for RedisConnectorEventHandler service
20:51:40.480 [JobManager-1] WARN  redis-connect - metricsKey not set - Metrics collection will be disabled
20:51:40.488 [JobManager-1] INFO  redis-connect-manager - Reading Mapper Config from : /opt/redislabs/redis-connect-sqlserver/config/samples/loader/mappers
20:51:40.506 [JobManager-1] INFO  redis-connect-manager - Loaded Config for : dbo.emp
20:51:40.646 [JobManager-1] INFO  redis-connect-manager - Instance: 30@virag-cdc successfully started job execution for JobId: {connect}:task:partition:initial_load:1
20:51:40.652 [EventProducer-2] WARN  redis-connect - Instance: 30@virag-cdc attempted to execute JobId: {connect}:task:partition:initial_load:1 although the job owner is Instance: UNASSIGNED. This attempt was bypassed. If this does not resolve after a few iterations, manual analysis is recommended
20:51:40.661 [EventProducer-2] INFO  redis-connect - Instance: 30@virag-cdc completed JobId: {connect}:task:partition:initial_load:1 from StartRecord: 1 to EndRecord: 1
20:51:40.669 [JobManager-1] INFO  redis-connect-manager - Instance: 30@virag-cdc successfully established Redis connection for HeartbeatManager service
20:51:40.669 [JobManager-1] INFO  redis-connect-manager - Instance: 30@virag-cdc has successfully claimed ownership of JobId: {connect}:task:partition:initial_load:1
20:51:40.669 [JobManager-1] INFO  redis-connect-manager - Instance: 30@virag-cdc has claimed 1 job(s) from its 2 max allowable capacity
20:51:40.670 [JobManager-2] INFO  redis-connect-heartbeat - Instance: 30@virag-cdc successfully refreshed Heartbeat: {connect}:heartbeat:job:{connect}:task:partition:initial_load:1 with value: 30@virag-cdc to new Lease: 30000
20:51:40.674 [JobManager-1] INFO  redis-connect-manager - JobId: {connect}:task:partition:initial_load:1 claim request with ID: 1643057470876-0 has been fully processed and all metadata has been updated
20:51:40.676 [JobManager-1] INFO  redis-connect-manager - Instance: 30@virag-cdc published Job Claim Transition Event to Channel: REDIS.CONNECT.JOB.CLAIM.TRANSITION.EVENTS Message: {"jobId":"{connect}:task:partition:initial_load:1","instanceName":"30@virag-cdc","transitionEvent":"CLAIMED","serviceName":"JobClaimer"}
20:51:40.676 [lettuce-nioEventLoop-4-3] INFO  redis-connect-manager - Instance: 30@virag-cdc consumed Job Claim Transition Event on Channel: REDIS.CONNECT.JOB.CLAIM.TRANSITION.EVENTS Message: {"jobId":"{connect}:task:partition:initial_load:1","instanceName":"30@virag-cdc","transitionEvent":"CLAIMED","serviceName":"JobClaimer"}
20:51:50.670 [EventProducer-2] INFO  redis-connect-manager - Instance: 30@virag-cdc successfully cancelled heartbeat for JobId: {connect}:task:partition:initial_load:1
20:51:50.671 [EventProducer-2] INFO  redis-connect-manager - Instance: 30@virag-cdc successfully stopped replication pipeline for JobId: {connect}:task:partition:initial_load:1
20:51:50.671 [EventProducer-2] INFO  redis-connect-manager - Instance: 30@virag-cdc now owns 0 job(s) from its 2 max allowable capacity
20:51:50.671 [EventProducer-2] INFO  redis-connect-manager - Instance: 30@virag-cdc successfully removed JobId: {connect}:task:partition:initial_load:1
```

</p>
</details>

<details><summary><b>Query for the above inserted record in Redis (target)</b></summary>
<p>

```bash
demo$ sudo docker exec -it re-node1 bash -c 'redis-cli -p 12000 ft.search idx:emp "*"'
```

</p>
</details>

-------------------------------

### CDC Steps
<details><summary><b>Stage pre configured cdc job</b></summary>
<p>

```bash
docker run \
-it --rm --privileged=true \
--name redis-connect-sqlserver \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-sqlserver/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-sqlserver/config/samples/sqlserver \
-e REDISCONNECT_SOURCE_USERNAME=sa \
-e REDISCONNECT_SOURCE_PASSWORD=Redis@123 \
-e REDISCONNECT_JAVA_OPTIONS="-Xms256m -Xmx256m" \
-v $(pwd)/config:/opt/redislabs/redis-connect-sqlserver/config \
--net host \
redislabs/redis-connect-sqlserver:latest stage
```

</p>
</details>

<details><summary>Expected output:</summary>
<p>

```bash
-------------------------------
Staging Redis Connect redis-connect-sqlserver v0.8.0.139 job using Java 11.0.14 on virag-cdc started by root in /opt/redislabs/redis-connect-sqlserver/bin
Loading Redis Connect redis-connect-sqlserver Configurations from /opt/redislabs/redis-connect-sqlserver/config/samples/sqlserver
20:54:55,004 |-INFO in ch.qos.logback.classic.LoggerContext[default] - Found resource [/opt/redislabs/redis-connect-sqlserver/config/logback.xml] at [file:/opt/redislabs/redis-connect-sqlserver/config/logback.xml]
....
20:54:55.305 [main] INFO  redis-connect-manager - ##################################################################
20:54:55.308 [main] INFO  redis-connect-manager -
20:54:55.309 [main] INFO  redis-connect-manager - REDIS CONNECT SETUP CLEAN - Deletes metadata related to Redis Connect from Job Management Database

20:54:55.309 [main] INFO  redis-connect-manager -
20:54:55.309 [main] INFO  redis-connect-manager - ##################################################################
20:54:56.179 [main] INFO  redis-connect-manager - Instance: 30@virag-cdc will attempt to delete (clean) all the metadata related to Redis Connect
20:54:57.119 [main] INFO  redis-connect-manager - Instance: 30@virag-cdc successfully established Redis connection for INIT service
20:54:57.140 [main] INFO  redis-connect-manager - Instance: 30@virag-cdc successfully completed flush (clean) of all the metadata related to Redis Connect
20:54:57,604 |-INFO in ch.qos.logback.classic.LoggerContext[default] - Found resource [/opt/redislabs/redis-connect-sqlserver/config/logback.xml] at [file:/opt/redislabs/redis-connect-sqlserver/config/logback.xml]
....
20:54:57.896 [main] INFO  redis-connect-manager - ##################################################################
20:54:57.899 [main] INFO  redis-connect-manager -
20:54:57.900 [main] INFO  redis-connect-manager - REDIS CONNECT SETUP CREATE - Seed metadata related to Redis Connect to Job Management Database
20:54:57.900 [main] INFO  redis-connect-manager -
20:54:57.900 [main] INFO  redis-connect-manager - ##################################################################
20:54:58.739 [main] INFO  redis-connect-manager - Instance: 96@virag-cdc will attempt Job Management Database (Redis) with all the configurations and scripts, if applicable, needed to execute jobs
20:54:59.630 [main] INFO  redis-connect-manager - Instance: 96@virag-cdc successfully established Redis connection for INIT service
20:54:59.633 [main] INFO  redis-connect-manager - Instance: 96@virag-cdc successfully created Job Claim Assignment Stream and Consumer Group
20:54:59.652 [main] INFO  redis-connect-manager - Instance: 96@virag-cdc successfully seeded Job related metadata
20:54:59.818 [main] ERROR redis-connect-manager - Key - dbo:emp:C:Throughput already exists
20:54:59.820 [main] ERROR redis-connect-manager - Key - dbo:emp:U:Throughput already exists
20:54:59.821 [main] ERROR redis-connect-manager - Key - dbo:emp:D:Throughput already exists
20:54:59.822 [main] ERROR redis-connect-manager - Key - dbo:emp:Latency already exists
20:54:59.835 [main] INFO  redis-connect-manager - Instance: 96@virag-cdc successfully seeded Metrics related metadata
20:54:59.835 [main] INFO  redis-connect-manager - Instance: 96@virag-cdc successfully staged Job Management Database (Redis) with all the configurations and scripts, if applicable, needed to execute jobs
-------------------------------
```

</p>
</details>

<details><summary><b>Start pre-configured cdc job</b></summary>
<p>

```bash
docker run \
-it --rm --privileged=true \
--name redis-connect-sqlserver \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-sqlserver/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-sqlserver/config/samples/sqlserver \
-e REDISCONNECT_REST_API_ENABLED=true \
-e REDISCONNECT_REST_API_PORT=8282 \
-e REDISCONNECT_SOURCE_USERNAME=sa \
-e REDISCONNECT_SOURCE_PASSWORD=Redis@123 \
-e REDISCONNECT_JAVA_OPTIONS="-Xms256m -Xmx1g" \
-v $(pwd)/config:/opt/redislabs/redis-connect-sqlserver/config \
--net host \
redislabs/redis-connect-sqlserver:latest start
```

</p>
</details>

<details><summary>Expected output:</summary>
<p>

```bash
-------------------------------
Starting Redis Connect redis-connect-sqlserver v0.8.0.139 instance using Java 11.0.14 on virag-cdc started by root in /opt/redislabs/redis-connect-sqlserver/bin
Loading Redis Connect redis-connect-sqlserver Configurations from /opt/redislabs/redis-connect-sqlserver/config/samples/sqlserver
20:56:37,980 |-INFO in ch.qos.logback.classic.LoggerContext[default] - Found resource [/opt/redislabs/redis-connect-sqlserver/config/logback.xml] at [file:/opt/redislabs/redis-connect-sqlserver/config/logback.xml]
....
20:56:38.328 [main] INFO  redis-connect-manager -
  /#######                  /## /##          	  /######                                                      /##
 | ##__  ##                | ## |__/          	 /##__  ##                                                    | ##
 | ##  \ ##  /######   /####### /##  /#######	| ##  \__/  /######  /#######  /#######   /######   /####### /######
 | #######/ /##__  ## /##__  ##| ## /##_____/	| ##       /##__  ##| ##__  ##| ##__  ## /##__  ## /##_____/|_  ##_/
 | ##__  ##| ########| ##  | ##| ##|  ###### 	| ##      | ##  \ ##| ##  \ ##| ##  \ ##| ########| ##        | ##
 | ##  \ ##| ##_____/| ##  | ##| ## \____  ##	| ##    ##| ##  | ##| ##  | ##| ##  | ##| ##_____/| ##        | ## /##
 | ##  | ##|  #######|  #######| ## /#######/	|  ######/|  ######/| ##  | ##| ##  | ##|  #######|  #######  |  ####/
 |__/  |__/ \_______/ \_______/|__/|_______/ 	 \______/  \______/ |__/  |__/|__/  |__/ \_______/ \_______/   \___/
Powered by Redis Enterprise
20:56:38.332 [main] INFO  redis-connect-manager -
20:56:38.333 [main] INFO  redis-connect-manager - ----------------------------------------------------------------------------------------------------------------------------
20:56:38.333 [main] INFO  redis-connect-manager -
20:56:38.333 [main] INFO  redis-connect-manager - Initializing Redis Connect Instance
20:56:38.333 [main] INFO  redis-connect-manager -
20:56:38.333 [main] INFO  redis-connect-manager - ----------------------------------------------------------------------------------------------------------------------------
20:57:05.526 [JobManager-1] INFO  redis-connect-manager - Reading Mapper Config from : /opt/redislabs/redis-connect-sqlserver/config/samples/sqlserver/mappers
20:57:05.543 [JobManager-1] INFO  redis-connect-manager - Loaded Config for : dbo.emp
20:57:06.238 [pool-3-thread-1] INFO  io.debezium.jdbc.JdbcConnection - Connection gracefully closed
20:57:06.251 [JobManager-1] INFO  i.d.connector.common.BaseSourceTask - Starting SqlServerConnectorTask with configuration:
20:57:06.252 [JobManager-1] INFO  i.d.connector.common.BaseSourceTask -    database.history.redis.url = targetConnection
20:57:06.252 [JobManager-1] INFO  i.d.connector.common.BaseSourceTask -    slot.name = redisconnect
20:57:06.252 [JobManager-1] INFO  i.d.connector.common.BaseSourceTask -    publication.name = redisconnect_publication
20:57:06.252 [JobManager-1] INFO  i.d.connector.common.BaseSourceTask -    include.schema.changes = false
20:57:06.252 [JobManager-1] INFO  i.d.connector.common.BaseSourceTask -    heartbeat.action.query =
20:57:06.252 [JobManager-1] INFO  i.d.connector.common.BaseSourceTask -    decimal.handling.mode = double
20:57:06.253 [JobManager-1] INFO  i.d.connector.common.BaseSourceTask -    heartbeat.topics.prefix = __redisconnect-heartbeat
20:57:06.253 [JobManager-1] INFO  i.d.connector.common.BaseSourceTask -    publication.autocreate.mode = all_tables
20:57:06.253 [JobManager-1] INFO  i.d.connector.common.BaseSourceTask -    database.history.file.filename =
20:57:06.253 [JobManager-1] INFO  i.d.connector.common.BaseSourceTask -    database.user = sa
20:57:06.253 [JobManager-1] INFO  i.d.connector.common.BaseSourceTask -    database.dbname = RedisConnect
20:57:06.253 [JobManager-1] INFO  i.d.connector.common.BaseSourceTask -    database.server.id = 1
20:57:06.253 [JobManager-1] INFO  i.d.connector.common.BaseSourceTask -    database.server.name = RedisConnect
20:57:06.253 [JobManager-1] INFO  i.d.connector.common.BaseSourceTask -    heartbeat.interval.ms = 0
20:57:06.253 [JobManager-1] INFO  i.d.connector.common.BaseSourceTask -    snapshot.isolation.mode = read_uncommitted
20:57:06.253 [JobManager-1] INFO  i.d.connector.common.BaseSourceTask -    plugin.name = pgoutput
20:57:06.253 [JobManager-1] INFO  i.d.connector.common.BaseSourceTask -    database.port = 1433
20:57:06.253 [JobManager-1] INFO  i.d.connector.common.BaseSourceTask -    database.history.redis.key = mysql-database-history
20:57:06.253 [JobManager-1] INFO  i.d.connector.common.BaseSourceTask -    column.exclude.list =
20:57:06.253 [JobManager-1] INFO  i.d.connector.common.BaseSourceTask -    database.hostname = 127.0.0.1
20:57:06.253 [JobManager-1] INFO  i.d.connector.common.BaseSourceTask -    database.password = ********
20:57:06.253 [JobManager-1] INFO  i.d.connector.common.BaseSourceTask -    name = RDB_EVENT_PRODUCER
20:57:06.253 [JobManager-1] INFO  i.d.connector.common.BaseSourceTask -    table.include.list = dbo.emp
20:57:06.253 [JobManager-1] INFO  i.d.connector.common.BaseSourceTask -    include.query = true
20:57:06.253 [JobManager-1] INFO  i.d.connector.common.BaseSourceTask -    database.history = com.redis.connect.pipeline.debezium.NoOpDatabaseHistory
20:57:06.253 [JobManager-1] INFO  i.d.connector.common.BaseSourceTask -    snapshot.mode = initial
20:57:06.254 [JobManager-1] INFO  i.d.connector.common.BaseSourceTask -    schemas.enable = false
20:57:06.294 [JobManager-1] INFO  i.d.connector.common.BaseSourceTask - No previous offsets found
20:57:06.312 [JobManager-1] INFO  io.debezium.util.Threads - Requested thread factory for connector SqlServerConnector, id = RedisConnect named = change-event-source-coordinator
20:57:06.316 [JobManager-1] INFO  io.debezium.util.Threads - Creating thread debezium-sqlserverconnector-RedisConnect-change-event-source-coordinator
20:57:06.317 [JobManager-1] INFO  redis-connect-manager - Instance: 31@virag-cdc successfully started job execution for JobId: {connect}:job:RedisConnect-emp
20:57:06.359 [JobManager-1] INFO  redis-connect-manager - Instance: 31@virag-cdc successfully established Redis connection for HeartbeatManager service
20:57:06.359 [JobManager-1] INFO  redis-connect-manager - Instance: 31@virag-cdc has successfully claimed ownership of JobId: {connect}:job:RedisConnect-emp
20:57:06.359 [JobManager-1] INFO  redis-connect-manager - Instance: 31@virag-cdc has claimed 1 job(s) from its 2 max allowable capacity
20:57:06.362 [JobManager-2] INFO  redis-connect-heartbeat - Instance: 31@virag-cdc successfully refreshed Heartbeat: {connect}:heartbeat:job:RedisConnect-emp with value: 31@virag-cdc to new Lease: 30000
20:57:06.375 [JobManager-1] INFO  redis-connect-manager - JobId: {connect}:job:RedisConnect-emp claim request with ID: 1643057699643-0 has been fully processed and all metadata has been updated
20:57:06.380 [JobManager-1] INFO  redis-connect-manager - Instance: 31@virag-cdc published Job Claim Transition Event to Channel: REDIS.CONNECT.JOB.CLAIM.TRANSITION.EVENTS Message: {"jobId":"{connect}:job:RedisConnect-emp","instanceName":"31@virag-cdc","transitionEvent":"CLAIMED","serviceName":"JobClaimer"}
20:57:06.380 [lettuce-nioEventLoop-4-3] INFO  redis-connect-manager - Instance: 31@virag-cdc consumed Job Claim Transition Event on Channel: REDIS.CONNECT.JOB.CLAIM.TRANSITION.EVENTS Message: {"jobId":"{connect}:job:RedisConnect-emp","instanceName":"31@virag-cdc","transitionEvent":"CLAIMED","serviceName":"JobClaimer"}
20:57:06.424 [debezium-sqlserverconnector-RedisConnect-change-event-source-coordinator] INFO  i.d.p.ChangeEventSourceCoordinator - Metrics registered
20:57:06.424 [debezium-sqlserverconnector-RedisConnect-change-event-source-coordinator] INFO  i.d.p.ChangeEventSourceCoordinator - Context created
20:57:06.431 [debezium-sqlserverconnector-RedisConnect-change-event-source-coordinator] INFO  i.d.c.s.SqlServerSnapshotChangeEventSource - No previous offset has been found
20:57:06.431 [debezium-sqlserverconnector-RedisConnect-change-event-source-coordinator] INFO  i.d.c.s.SqlServerSnapshotChangeEventSource - According to the connector configuration both schema and data will be snapshotted
20:57:06.432 [debezium-sqlserverconnector-RedisConnect-change-event-source-coordinator] INFO  i.d.r.RelationalSnapshotChangeEventSource - Snapshot step 1 - Preparing
20:57:06.451 [debezium-sqlserverconnector-RedisConnect-change-event-source-coordinator] INFO  i.d.r.RelationalSnapshotChangeEventSource - Snapshot step 2 - Determining captured tables
20:57:06.460 [debezium-sqlserverconnector-RedisConnect-change-event-source-coordinator] INFO  i.d.r.RelationalSnapshotChangeEventSource - Snapshot step 3 - Locking captured tables [RedisConnect.dbo.emp]
20:57:06.461 [debezium-sqlserverconnector-RedisConnect-change-event-source-coordinator] INFO  i.d.c.s.SqlServerSnapshotChangeEventSource - Schema locking was disabled in connector configuration
20:57:06.461 [debezium-sqlserverconnector-RedisConnect-change-event-source-coordinator] INFO  i.d.r.RelationalSnapshotChangeEventSource - Snapshot step 4 - Determining snapshot offset
20:57:06.471 [debezium-sqlserverconnector-RedisConnect-change-event-source-coordinator] INFO  i.d.r.RelationalSnapshotChangeEventSource - Snapshot step 5 - Reading structure of captured tables
20:57:06.472 [debezium-sqlserverconnector-RedisConnect-change-event-source-coordinator] INFO  i.d.c.s.SqlServerSnapshotChangeEventSource - Reading structure of schema 'RedisConnect'
20:57:06.505 [debezium-sqlserverconnector-RedisConnect-change-event-source-coordinator] INFO  i.d.r.RelationalSnapshotChangeEventSource - Snapshot step 6 - Persisting schema history
20:57:06.523 [debezium-sqlserverconnector-RedisConnect-change-event-source-coordinator] INFO  i.d.r.RelationalSnapshotChangeEventSource - Snapshot step 7 - Snapshotting data
20:57:06.524 [debezium-sqlserverconnector-RedisConnect-change-event-source-coordinator] INFO  i.d.r.RelationalSnapshotChangeEventSource - Snapshotting contents of 1 tables while still in transaction
20:57:06.524 [debezium-sqlserverconnector-RedisConnect-change-event-source-coordinator] INFO  i.d.r.RelationalSnapshotChangeEventSource - Exporting data from table 'RedisConnect.dbo.emp' (1 of 1 tables)
20:57:06.526 [debezium-sqlserverconnector-RedisConnect-change-event-source-coordinator] INFO  i.d.r.RelationalSnapshotChangeEventSource - 	 For table 'RedisConnect.dbo.emp' using select statement: 'SELECT [empno], [fname], [lname], [job], [mgr], [hiredate], [sal], [comm], [dept] FROM [RedisConnect].[dbo].[emp]'
20:57:06.541 [debezium-sqlserverconnector-RedisConnect-change-event-source-coordinator] INFO  i.d.r.RelationalSnapshotChangeEventSource - 	 Finished exporting 1 records for table 'RedisConnect.dbo.emp'; total duration '00:00:00.017'
20:57:06.544 [debezium-sqlserverconnector-RedisConnect-change-event-source-coordinator] INFO  i.d.p.s.AbstractSnapshotChangeEventSource - Snapshot - Final stage
20:57:06.545 [debezium-sqlserverconnector-RedisConnect-change-event-source-coordinator] INFO  i.d.c.s.SqlServerSnapshotChangeEventSource - Removing locking timeout
20:57:06.547 [debezium-sqlserverconnector-RedisConnect-change-event-source-coordinator] INFO  i.d.p.ChangeEventSourceCoordinator - Snapshot ended with SnapshotResult [status=COMPLETED, offset=SqlServerOffsetContext [sourceInfoSchema=Schema{io.debezium.connector.sqlserver.Source:STRUCT}, sourceInfo=SourceInfo [serverName=RedisConnect, changeLsn=NULL, commitLsn=00000038:000074f8:0001, eventSerialNo=null, snapshot=FALSE, sourceTime=2022-01-24T20:57:06.530Z], snapshotCompleted=true, eventSerialNo=1]]
20:57:06.552 [debezium-sqlserverconnector-RedisConnect-change-event-source-coordinator] INFO  i.d.p.m.StreamingChangeEventSourceMetrics - Connected metrics set to 'true'
20:57:06.554 [debezium-sqlserverconnector-RedisConnect-change-event-source-coordinator] INFO  i.d.c.s.SqlServerChangeEventSourceCoordinator - Starting streaming
....
```

</p>
</details>

<details><summary><b>INSERT a record into SQL Server table (source) using the command line or provided script, insert_mssql.sh in the demo directory</b></summary>
<p>

```bash
sudo docker exec -it mssql-2017-latest-$(hostname) bash -c '/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "Redis@123" -d RedisConnect'

1> insert into dbo.emp values(1002, 'Virag', 'Tripathi', 'SA', 1, '2018-08-06 00:00:00.000', '2000', '10', 1)
2> go

(1 rows affected)
1> quit
```

</p>
</details>

<details><summary><b>Query for the above inserted record in Redis (target)</b></summary>
<p>

```bash
sudo docker exec -it re-node1 bash -c 'redis-cli -p 12000 ft.search idx:emp "@EmployeeNumber:[1000 1002]"'
```

</p>
</details>

Similarly `UPDATE` and `DELETE` records on SQL Server source using queries on the command line or provided scripts [update_mssql.sh](update_mssql.sh) and [delete_mssql.sh](delete_mssql.sh) and see Redis target getting updated in near real-time.

-------------------------------

### [_Custom Stage_](https://github.com/redis-field-engineering/redis-connect-custom-stage-demo)

Review the Custom Stage Demo then use the pre-built CustomStage function by passing it as an external library and follow [Initial Loader Steps](#initial-loader-steps) or [CDC Steps](#cdc-steps).

* Add the `CustomStage` `handlerId` in JobConfig.yml as explained in the Custom Stage Demo i.e.
```yml
  stages:
    CustomStage:
      handlerId: TO_UPPER_CASE
```
* Please make sure the columns that are going to be used for this custom stage has the same value at the source and target i.e. it is not mapped to another name in Redis. For this example `fname` and `lname` are the default values for `col1` and `col2` and if you want to change this then pass a different column names to `REDISCONNECT_JAVA_OPTIONS` e.g. `-Dcol1=fname -Dcol2=job`

<details><summary><b>Stage pre-configured loader job with Custom Stage</b></summary>
<p>

```bash
docker run \
-it --rm --privileged=true \
--name redis-connect-sqlserver \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-sqlserver/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-sqlserver/config/samples/sqlserver \
-e REDISCONNECT_REST_API_ENABLED=true \
-e REDISCONNECT_REST_API_PORT=8282 \
-e REDISCONNECT_SOURCE_USERNAME=sa \
-e REDISCONNECT_SOURCE_PASSWORD=Redis@123 \
-e REDISCONNECT_JAVA_OPTIONS="-Xms256m -Xmx1g" \
-v $(pwd)/config:/opt/redislabs/redis-connect-sqlserver/config \
-v $(pwd)/extlib:/opt/redislabs/redis-connect-sqlserver/extlib \
--net host \
redislabs/redis-connect-sqlserver:latest stage
```

</p>
</details>

<details><summary><b>Start pre-configured loader job with Custom Stage</b></summary>
<p>

```bash
docker run \
-it --rm --privileged=true \
--name redis-connect-sqlserver \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-sqlserver/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-sqlserver/config/samples/sqlserver \
-e REDISCONNECT_REST_API_ENABLED=true \
-e REDISCONNECT_REST_API_PORT=8282 \
-e REDISCONNECT_SOURCE_USERNAME=sa \
-e REDISCONNECT_SOURCE_PASSWORD=Redis@123 \
-e REDISCONNECT_JAVA_OPTIONS="-Xms256m -Xmx1g" \
-v $(pwd)/config:/opt/redislabs/redis-connect-sqlserver/config \
-v $(pwd)/extlib:/opt/redislabs/redis-connect-sqlserver/extlib \
--net host \
redislabs/redis-connect-sqlserver:latest start
```

</p>
</details>

<details><summary>Expected output:</summary>
<p>

```bash
....
CustomStageDemo::onEvent Processor, jobId: {connect}:job:RedisConnect-emp, table: emp, operationType: C
Original Virag : Virag
Original Tripathi : Tripathi
Updated Virag : VIRAG
Updated Tripathi : TRIPATHI
....
```

</p>
</details>

Validate the output after CustomStage run and make sure that `fname` and `lname` values in Redis has been updated to UPPER CASE.
