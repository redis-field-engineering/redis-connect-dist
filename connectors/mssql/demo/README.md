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
redislabs/redis-connect-sqlserver:pre-release-alpine
```

</p>
</details>

<details><summary>Expected output:</summary>
<p>

```bash
Unable to find image 'redislabs/redis-connect-sqlserver:pre-release-alpine' locally
pre-release-alpine: Pulling from redislabs/redis-connect-sqlserver
a0d0a0d46f8b: Already exists
e1fc1d22fcb4: Pull complete
3f5fde473eac: Pull complete
a95f82a482cf: Pull complete
e06557015f22: Pull complete
dc1a00dd4c05: Pull complete
c13b3b271b47: Pull complete
4d4fa8f69dc1: Pull complete
Digest: sha256:fc3c53af40ea709a4b4129a869275577b9abe29c8febe7cb2ff864e3dbbe1c32
Status: Downloaded newer image for redislabs/redis-connect-sqlserver:pre-release-alpine
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

<details><summary><b>Stage pre configured loader job</b></summary>
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
redislabs/redis-connect-sqlserver:pre-release-alpine stage
```

</p>
</details>

<details><summary>Expected output:</summary>
<p>

```bash
-------------------------------
Staging Redis Connect redis-connect-sqlserver v0.7.0.133 job using Java 11.0.13 on virag-cdc started by root in /opt/redislabs/redis-connect-sqlserver/bin
Loading Redis Connect redis-connect-sqlserver Configurations from /opt/redislabs/redis-connect-sqlserver/config/samples/loader
20:57:15,320 |-INFO in ch.qos.logback.classic.LoggerContext[default] - Found resource [/opt/redislabs/redis-connect-sqlserver/config/logback.xml] at [file:/opt/redislabs/redis-connect-sqlserver/config/logback.xml]
....
....
20:57:15.558 [main] INFO  startup - ##################################################################
20:57:15.560 [main] INFO  startup -
20:57:15.560 [main] INFO  startup - REDIS CONNECT SETUP CLEAN - Deletes metadata related to Redis Connect from Job Management Database

20:57:15.560 [main] INFO  startup -
20:57:15.560 [main] INFO  startup - ##################################################################
20:57:16.289 [main] INFO  startup - Instance: 29@virag-cdc will attempt to delete (clean) all the metadata related to Redis Connect
20:57:17.083 [main] INFO  startup - Instance: 29@virag-cdc successfully established Redis connection for INIT service
20:57:17.090 [main] INFO  startup - Instance: 29@virag-cdc successfully completed flush (clean) of all the metadata related to Redis Connect
20:57:17,628 |-INFO in ch.qos.logback.classic.LoggerContext[default] - Found resource [/opt/redislabs/redis-connect-sqlserver/config/logback.xml] at [file:/opt/redislabs/redis-connect-sqlserver/config/logback.xml]
....
....
20:57:17.873 [main] INFO  startup - ##################################################################
20:57:17.874 [main] INFO  startup -
20:57:17.875 [main] INFO  startup - REDIS CONNECT SETUP CREATE - Seed metadata related to Redis Connect to Job Management Database
20:57:17.875 [main] INFO  startup -
20:57:17.875 [main] INFO  startup - ##################################################################
20:57:18.582 [main] INFO  startup - Instance: 99@virag-cdc will attempt Job Management Database (Redis) with all the configurations and scripts, if applicable, needed to execute jobs
20:57:19.321 [main] INFO  startup - Instance: 99@virag-cdc successfully established Redis connection for INIT service
20:57:19.324 [main] INFO  startup - Instance: 99@virag-cdc successfully created Job Claim Assignment Stream and Consumer Group
20:57:19.338 [main] INFO  startup - Instance: 99@virag-cdc successfully seeded Job related metadata
20:57:19.338 [main] INFO  startup - Instance: 99@virag-cdc successfully seeded Metrics related metadata
20:57:19.338 [main] INFO  startup - Instance: 99@virag-cdc successfully staged Job Management Database (Redis) with all the configurations and scripts, if applicable, needed to execute jobs
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
redislabs/redis-connect-sqlserver:pre-release-alpine start
```

</p>
</details>

<details><summary>Expected output:</summary>
<p>

```bash
-------------------------------
Starting Redis Connect redis-connect-sqlserver v0.7.0.133 instance using Java 11.0.13 on virag-cdc started by root in /opt/redislabs/redis-connect-sqlserver/bin
Loading Redis Connect redis-connect-sqlserver Configurations from /opt/redislabs/redis-connect-sqlserver/config/samples/loader
23:11:11,963 |-INFO in ch.qos.logback.classic.LoggerContext[default] - Found resource [/opt/redislabs/redis-connect-sqlserver/config/logback.xml] at [file:/opt/redislabs/redis-connect-sqlserver/config/logback.xml]
....
....
23:15:11.429 [main] INFO  startup -
23:15:11.432 [main] INFO  startup -  /$$$$$$$                  /$$ /$$                  /$$$$$$                                                      /$$
23:15:11.433 [main] INFO  startup - | $$__  $$                | $$|__/                 /$$__  $$                                                    | $$
23:15:11.433 [main] INFO  startup - | $$  \ $$  /$$$$$$   /$$$$$$$ /$$  /$$$$$$$      | $$  \__/  /$$$$$$  /$$$$$$$  /$$$$$$$   /$$$$$$   /$$$$$$$ /$$$$$$
23:15:11.433 [main] INFO  startup - | $$$$$$$/ /$$__  $$ /$$__  $$| $$ /$$_____/      | $$       /$$__  $$| $$__  $$| $$__  $$ /$$__  $$ /$$_____/|_  $$_/
23:15:11.434 [main] INFO  startup - | $$__  $$| $$$$$$$$| $$  | $$| $$|  $$$$$$       | $$      | $$  \ $$| $$  \ $$| $$  \ $$| $$$$$$$$| $$        | $$
23:15:11.434 [main] INFO  startup - | $$  \ $$| $$_____/| $$  | $$| $$ \____  $$      | $$    $$| $$  | $$| $$  | $$| $$  | $$| $$_____/| $$        | $$ /$$
23:15:11.434 [main] INFO  startup - | $$  | $$|  $$$$$$$|  $$$$$$$| $$ /$$$$$$$/      |  $$$$$$/|  $$$$$$/| $$  | $$| $$  | $$|  $$$$$$$|  $$$$$$$  |  $$$$/
23:15:11.434 [main] INFO  startup - |__/  |__/ \_______/ \_______/|__/|_______/        \______/  \______/ |__/  |__/|__/  |__/ \_______/ \_______/   \___/
23:15:11.434 [main] INFO  startup -
23:15:11.434 [main] INFO  startup - ##################################################################
23:15:11.434 [main] INFO  startup -
23:15:11.434 [main] INFO  startup - Initializing Redis Connect Instance
23:15:11.434 [main] INFO  startup -
23:15:11.434 [main] INFO  startup - ##################################################################
23:15:11.439 [main] INFO  startup - Manifest Details connect-core         : Build : 0.8.0.148 : Build-Time : 2021-11-01T14:59:42Z
23:15:11.442 [main] INFO  startup - Manifest Details connect-redis-core   : Build : 0.8.0.142 : Build-Time : 2021-11-01T14:59:42Z
23:15:11.446 [main] INFO  startup - Manifest Details connector-rdb        : Build : 0.8.0.147 : Build-Time : 2021-11-01T14:59:42Z
23:15:17.834 [main] INFO  startup - Instance: 29@virag-cdc successfully established Redis connection for JobManager service
23:15:17.939 [main] INFO  startup - Instance: 29@virag-cdc successfully established PUB/SUB Redis connection
23:15:17.959 [main] INFO  startup - Instance: 29@virag-cdc successfully established PUB/SUB Redis connection
23:15:17.967 [main] INFO  startup - Instance: 29@virag-cdc successfully started JobManager service
23:15:17.985 [main] INFO  startup - Instance: 29@virag-cdc successfully established Redis connection for JobReaper service
23:15:17.985 [main] INFO  startup - Instance: 29@virag-cdc successfully started JobReaper service
23:15:18.003 [main] INFO  startup - Instance: 29@virag-cdc successfully established Redis connection for JobClaimer service
23:15:18.003 [main] INFO  startup - Instance: 29@virag-cdc successfully started JobClaimer service
23:15:18.008 [main] INFO  startup - Instance: 29@virag-cdc successfully subscribed to Channel: REDIS.CONNECT.JOB.CLAIM.TRANSITION.EVENTS
23:15:18.008 [main] INFO  startup - Instance: 29@virag-cdc did not enable embedded REST API server
23:15:27.995 [JobManager-1] INFO  startup - Instance: 29@virag-cdc successfully established Redis connection for HeartbeatManager service
23:15:27.997 [JobManager-1] INFO  startup - Instance: 29@virag-cdc was successfully elected Redis Connect cluster leader
23:15:38.385 [JobManager-1] INFO  startup - Instance: 29@virag-cdc successfully started job execution for JobId: {connect}:job:initial_load
23:15:38.386 [JobManager-1] INFO  startup - Instance: 29@virag-cdc has successfully claimed ownership of JobId: {connect}:job:initial_load
23:15:38.386 [JobManager-1] INFO  startup - Instance: 29@virag-cdc has claimed 1 job(s) from its 2 max allowable capacity
23:15:38.398 [JobManager-1] INFO  startup - JobId: {connect}:job:initial_load claim request with ID: 1635808503423-0 has been fully processed and all metadata has been updated
....
....
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
redislabs/redis-connect-sqlserver:pre-release-alpine stage
```

</p>
</details>

<details><summary>Expected output:</summary>
<p>

```bash
-------------------------------
Staging Redis Connect redis-connect-sqlserver v0.7.0.133 job using Java 11.0.13 on virag-cdc started by root in /opt/redislabs/redis-connect-sqlserver/bin
Loading Redis Connect redis-connect-sqlserver Configurations from /opt/redislabs/redis-connect-sqlserver/config/samples/sqlserver
00:43:35,730 |-INFO in ch.qos.logback.classic.LoggerContext[default] - Found resource [/opt/redislabs/redis-connect-sqlserver/config/logback.xml] at [file:/opt/redislabs/redis-connect-sqlserver/config/logback.xml]
....
....
00:43:35.997 [main] INFO  startup - ##################################################################
00:43:35.999 [main] INFO  startup -
00:43:35.999 [main] INFO  startup - REDIS CONNECT SETUP CLEAN - Deletes metadata related to Redis Connect from Job Management Database

00:43:35.999 [main] INFO  startup -
00:43:35.999 [main] INFO  startup - ##################################################################
00:43:36.750 [main] INFO  startup - Instance: 31@virag-cdc will attempt to delete (clean) all the metadata related to Redis Connect
00:43:37.545 [main] INFO  startup - Instance: 31@virag-cdc successfully established Redis connection for INIT service
00:43:37.561 [main] INFO  startup - Instance: 31@virag-cdc successfully completed flush (clean) of all the metadata related to Redis Connect
....
....
00:43:38.363 [main] INFO  startup - ##################################################################
00:43:38.364 [main] INFO  startup -
00:43:38.365 [main] INFO  startup - REDIS CONNECT SETUP CREATE - Seed metadata related to Redis Connect to Job Management Database
00:43:38.365 [main] INFO  startup -
00:43:38.365 [main] INFO  startup - ##################################################################
00:43:39.093 [main] INFO  startup - Instance: 104@virag-cdc will attempt Job Management Database (Redis) with all the configurations and scripts, if applicable, needed to execute jobs
00:43:39.860 [main] INFO  startup - Instance: 104@virag-cdc successfully established Redis connection for INIT service
00:43:39.862 [main] INFO  startup - Instance: 104@virag-cdc successfully created Job Claim Assignment Stream and Consumer Group
00:43:39.878 [main] INFO  startup - Instance: 104@virag-cdc successfully seeded Job related metadata
....
....
-------------------------------
```

</p>
</details>

<details><summary><b>Start pre configured cdc job</b></summary>
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
redislabs/redis-connect-sqlserver:pre-release-alpine start
```

</p>
</details>

<details><summary>Expected output:</summary>
<p>

```bash
-------------------------------
Starting Redis Connect redis-connect-sqlserver v0.7.0.133 instance using Java 11.0.13 on virag-cdc started by root in /opt/redislabs/redis-connect-sqlserver/bin
Loading Redis Connect redis-connect-sqlserver Configurations from /opt/redislabs/redis-connect-sqlserver/config/samples/sqlserver
00:44:43,241 |-INFO in ch.qos.logback.classic.LoggerContext[default] - Found resource [/opt/redislabs/redis-connect-sqlserver/config/logback.xml] at [file:/opt/redislabs/redis-connect-sqlserver/config/logback.xml]
....
....
00:44:43.551 [main] INFO  startup -
00:44:43.554 [main] INFO  startup -  /$$$$$$$                  /$$ /$$                  /$$$$$$                                                      /$$
00:44:43.554 [main] INFO  startup - | $$__  $$                | $$|__/                 /$$__  $$                                                    | $$
00:44:43.555 [main] INFO  startup - | $$  \ $$  /$$$$$$   /$$$$$$$ /$$  /$$$$$$$      | $$  \__/  /$$$$$$  /$$$$$$$  /$$$$$$$   /$$$$$$   /$$$$$$$ /$$$$$$
00:44:43.555 [main] INFO  startup - | $$$$$$$/ /$$__  $$ /$$__  $$| $$ /$$_____/      | $$       /$$__  $$| $$__  $$| $$__  $$ /$$__  $$ /$$_____/|_  $$_/
00:44:43.555 [main] INFO  startup - | $$__  $$| $$$$$$$$| $$  | $$| $$|  $$$$$$       | $$      | $$  \ $$| $$  \ $$| $$  \ $$| $$$$$$$$| $$        | $$
00:44:43.555 [main] INFO  startup - | $$  \ $$| $$_____/| $$  | $$| $$ \____  $$      | $$    $$| $$  | $$| $$  | $$| $$  | $$| $$_____/| $$        | $$ /$$
00:44:43.555 [main] INFO  startup - | $$  | $$|  $$$$$$$|  $$$$$$$| $$ /$$$$$$$/      |  $$$$$$/|  $$$$$$/| $$  | $$| $$  | $$|  $$$$$$$|  $$$$$$$  |  $$$$/
00:44:43.556 [main] INFO  startup - |__/  |__/ \_______/ \_______/|__/|_______/        \______/  \______/ |__/  |__/|__/  |__/ \_______/ \_______/   \___/
00:44:43.556 [main] INFO  startup -
00:44:43.556 [main] INFO  startup - ##################################################################
00:44:43.556 [main] INFO  startup -
00:44:43.556 [main] INFO  startup - Initializing Redis Connect Instance
00:44:43.556 [main] INFO  startup -
00:44:43.556 [main] INFO  startup - ##################################################################
00:44:43.563 [main] INFO  startup - Manifest Details connect-core         : Build : 0.8.0.148 : Build-Time : 2021-11-01T14:59:42Z
00:44:43.567 [main] INFO  startup - Manifest Details connect-redis-core   : Build : 0.8.0.142 : Build-Time : 2021-11-01T14:59:42Z
00:44:43.570 [main] INFO  startup - Manifest Details connector-rdb        : Build : 0.8.0.147 : Build-Time : 2021-11-01T14:59:42Z
00:44:49.991 [main] INFO  startup - Instance: 30@virag-cdc successfully established Redis connection for JobManager service
00:44:50.101 [main] INFO  startup - Instance: 30@virag-cdc successfully established PUB/SUB Redis connection
00:44:50.119 [main] INFO  startup - Instance: 30@virag-cdc successfully established PUB/SUB Redis connection
00:44:50.127 [main] INFO  startup - Instance: 30@virag-cdc successfully started JobManager service
00:44:50.145 [main] INFO  startup - Instance: 30@virag-cdc successfully established Redis connection for JobReaper service
00:44:50.146 [main] INFO  startup - Instance: 30@virag-cdc successfully started JobReaper service
00:44:50.165 [main] INFO  startup - Instance: 30@virag-cdc successfully established Redis connection for JobClaimer service
00:44:50.165 [main] INFO  startup - Instance: 30@virag-cdc successfully started JobClaimer service
00:44:50.170 [main] INFO  startup - Instance: 30@virag-cdc successfully subscribed to Channel: REDIS.CONNECT.JOB.CLAIM.TRANSITION.EVENTS
00:44:50.170 [main] INFO  startup - Instance: 30@virag-cdc did not enable embedded REST API server
00:45:00.155 [JobManager-1] INFO  startup - Instance: 30@virag-cdc successfully established Redis connection for HeartbeatManager service
00:45:00.156 [JobManager-1] INFO  startup - Instance: 30@virag-cdc was successfully elected Redis Connect cluster leader
00:45:10.234 [JobManager-1] INFO  startup - Getting instance of EventHandler for : REDIS_HASH_WRITER
00:45:10.267 [JobManager-1] INFO  startup - Instance: 30@virag-cdc successfully established Redis connection for RedisConnectorEventHandler service
00:45:10.271 [JobManager-1] INFO  startup - Getting instance of EventHandler for : REDIS_HASH_CHECKPOINT_WRITER
00:45:10.271 [JobManager-1] WARN  startup - metricsKey not set - Metrics collection will be disabled
00:45:10.291 [JobManager-1] INFO  startup - Instance: 30@virag-cdc successfully established Redis connection for RedisCheckpointReader service
00:45:10.305 [JobManager-1] INFO  redisconnect - Reading Mapper Config from : /opt/redislabs/redis-connect-sqlserver/config/samples/sqlserver/mappers
00:45:10.320 [JobManager-1] INFO  redisconnect - Loaded Config for : dbo.emp
....
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

Review the Custom Stage Demo then use the pre-built CustomStage function by passing it as an external library then follow the same [Initial Loader Steps](#initial-loader-steps) and [CDC Steps](#cdc-steps).

Add the `CustomStage` `handlerId` in JobConfig.yml as explained in the Custom Stage Demo i.e.
```yml
  stages:
    CustomStage:
      handlerId: TO_UPPER_CASE
```
<details><summary><b>Stage pre configured loader job with Custom Stage</b></summary>
<p>

```bash
docker run \
-it --rm --privileged=true \
--name redis-connect-sqlserver \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-sqlserver/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-sqlserver/config/samples/loader \
-e REDISCONNECT_SOURCE_USERNAME=redisconnect \
-e REDISCONNECT_SOURCE_PASSWORD=Redis@123 \
-e REDISCONNECT_JAVA_OPTIONS="-Xms256m -Xmx256m" \
-v $(pwd)/config:/opt/redislabs/redis-connect-sqlserver/config \
-v $(pwd)/extlib:/opt/redislabs/redis-connect-sqlserver/extlib \
--net host \
redislabs/redis-connect-sqlserver:pre-release-alpine stage
```

</p>
</details>

<details><summary><b>Start pre configured loader job with Custom Stage</b></summary>
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
-v $(pwd)/extlib:/opt/redislabs/redis-connect-sqlserver/extlib \
--net host \
redislabs/redis-connect-sqlserver:pre-release-alpine start
```

</p>
</details>

Validate the output after CustomStage run and make sure that `fname` and `lname` values in Redis has been updated to UPPER CASE.
