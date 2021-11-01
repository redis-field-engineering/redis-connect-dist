# Prerequisites

Docker compatible [*nix OS](https://en.wikipedia.org/wiki/Unix-like) and [Docker](https://docs.docker.com/get-docker) installed.
<br>Please have 8 vCPU*, 8GB RAM and 50GB storage for this demo to function properly. Adjust the resources based on your requirements. For HA, at least have 2 Redis Connect Connector instances deployed on separate hosts.</br>
<br>Execute the following commands (copy & paste) to download and setup Redis Connect MSSQL Connector and demo scripts.
i.e.</br>
```bash
wget -c https://github.com/redis-field-engineering/redis-connect-dist/archive/main.zip && \
mkdir -p redis-connect-sqlserver/demo && \
unzip main.zip "redis-connect-dist-main/connectors/sqlserver/demo/*" -d redis-connect-sqlserver/demo && \
cp -R redis-connect-sqlserver/demo/redis-connect-dist-main/connectors/sqlserver/demo/* redis-connect-sqlserver/demo && \
mv redis-connect-sqlserver/demo/config redis-connect-sqlserver && \
rm -rf main.zip redis-connect-sqlserver/demo/redis-connect-dist-main && \
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
rl-connector-rdb$ cd demo
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

## Setup RedisInsight
Open a web browser and navigate to http://127.0.0.1:18001/ and [add both job config & metrics and target Redis databbases](https://docs.redislabs.com/latest/ri/using-redisinsight/add-instance/) (use redisUrl's from env.yml) to RedisInsight UI. Use Redis database endpoints for job management and target databasees, use the `Internal IP` instead of `127.0.0.1` on cloud machines.

## Start Redis Connect SQL Server Connector

<details><summary>Run Redis Connect SQL Server Connector docker container to see all the options</summary>
<p>

```bash
docker run \
-it --rm --privileged=true \
--name redis-connect-sqlserver \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-sqlserver/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-sqlserver/config/samples/sqlserver \
-e REDISCONNECT_SOURCE_USERNAME=redisconnect \
-e REDISCONNECT_SOURCE_PASSWORD=Redis@123 \
-e REDISCONNECT_JAVA_OPTIONS="-Xms256m -Xmx256m" \
-v $(pwd)/../config:/opt/redislabs/redis-connect-sqlserver/config \
--net host \
redislabs/redis-connect-sqlserver:pre-release-alpine
```

</p>
</details>

<details><summary>Expected output:</summary>
<p>

```bash
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
<details><summary><b>INSERT few records into SQL Server table (source)</b></summary>
<p>

```bash
demo$ ./insert_mssql.sh
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
-v $(pwd)/../config:/opt/redislabs/redis-connect-sqlserver/config \
--net host \
redislabs/redis-connect-sqlserver:pre-release-alpine stage
```

</p>
</details>

<details><summary>Expected output:</summary>
<p>

```bash
-------------------------------

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
-v $(pwd)/../config:/opt/redislabs/redis-connect-sqlserver/config \
--net host \
redislabs/redis-connect-sqlserver:pre-release-alpine start
```

</p>
</details>

<details><summary>Expected output:</summary>
<p>

```bash
-------------------------------

.....  
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
-v $(pwd)/../config:/opt/redislabs/redis-connect-sqlserver/config \
--net host \
redislabs/redis-connect-sqlserver:pre-release-alpine stage
```

</p>
</details>

<details><summary>Expected output:</summary>
<p>

```bash
-------------------------------

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
-v $(pwd)/../config:/opt/redislabs/redis-connect-sqlserver/config \
--net host \
redislabs/redis-connect-sqlserver:pre-release-alpine start
```

</p>
</details>

<details><summary>Expected output:</summary>
<p>

```bash
-------------------------------

.....  
```

</p>
</details>

<details><summary><b>INSERT a record into SQL Server table (source)</b></summary>
<p>

```bash

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

Similarly `UPDATE` and `DELETE` records on SQL Server source and see Redis target getting updated in near real-time.

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
-v $(pwd)/../config:/opt/redislabs/redis-connect-sqlserver/config \
-v $(pwd)/../extlib:/opt/redislabs/redis-connect-sqlserver/extlib \
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
-v $(pwd)/../config:/opt/redislabs/redis-connect-sqlserver/config \
-v $(pwd)/../extlib:/opt/redislabs/redis-connect-sqlserver/extlib \
--net host \
redislabs/redis-connect-sqlserver:pre-release-alpine start
```

</p>
</details>

Validate the output after CustomStage run and make sure that `fname` and `lname` values in Redis has been updated to UPPER CASE.
