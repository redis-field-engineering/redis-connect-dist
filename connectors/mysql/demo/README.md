# Prerequisites

Docker compatible [*nix OS](https://en.wikipedia.org/wiki/Unix-like) and [Docker](https://docs.docker.com/get-docker) installed.
<br>Please have 8 vCPU*, 8GB RAM and 50GB storage for this demo to function properly. Adjust the resources based on your requirements. For HA, at least have 2 Redis Connect Connector instances deployed on separate hosts.</br>
<br>Execute the following commands (copy & paste) to download and setup Redis Connect MySQL Connector and demo scripts.
i.e.</br>
```bash
wget -c https://github.com/redis-field-engineering/redis-connect-dist/archive/main.zip && \
mkdir -p redis-connect-mysql/demo && \
unzip main.zip "redis-connect-dist-main/connectors/mysql/demo/*" -d redis-connect-mysql/demo && \
cp -R redis-connect-mysql/demo/redis-connect-dist-main/connectors/mysql/demo/* redis-connect-mysql/demo && \
mv redis-connect-mysql/demo/config redis-connect-mysql && \
rm -rf main.zip redis-connect-mysql/demo/redis-connect-dist-main && \
cd redis-connect-mysql && \
chmod a+x demo/*.sh
```
Expected output:
```bash
redis-connect-mysql$ ls
config demo
```

## Setup MySQL database in docker (Source)

<br>Execute [setup_mysql.sh](setup_mysql.sh)</br>
```bash
redis-connect-mysql$ cd demo
demo$ ./setup_mysql.sh latest
```

<details><summary>Validate MySQL database is running as expected:</summary>
<p>

```bash
demo$ docker ps -a | grep mysql
33e66aaa75db        mysql:latest                                 "docker-entrypoint.s…"   31 minutes ago      Up 31 minutes       0.0.0.0:3306->3306/tcp, 33060/tcp                                                                                                                                                                                                                                                                               mysql-latest-virag-cdc

demo$ docker exec -i mysql-latest-virag-cdc mysql -uroot -pRedis@123  <<< "SHOW VARIABLES LIKE 'log_bin';"
mysql: [Warning] Using a password on the command line interface can be insecure.
Variable_name	Value
log_bin	ON
```
</p>
</details>

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

## Start Redis Connect MySQL Connector

<details><summary>Run Redis Connect MySQL Connector docker container to see all the options</summary>
<p>

```bash
docker run \
-it --rm --privileged=true \
--name redis-connect-mysql \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-mysql/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-mysql/config/samples/mysql \
-e REDISCONNECT_SOURCE_USERNAME=redisconnectuser \
-e REDISCONNECT_SOURCE_PASSWORD=redisconnectpassword \
-e REDISCONNECT_JAVA_OPTIONS="-Xms256m -Xmx256m" \
-v $(pwd)/../config:/opt/redislabs/redis-connect-mysql/config \
--net host \
redislabs/redis-connect-mysql:pre-release-alpine
```

</p>
</details>

<details><summary>Expected output:</summary>
<p>

```bash
Unable to find image 'redislabs/redis-connect-mysql:pre-release-alpine' locally
pre-release-alpine: Pulling from redislabs/redis-connect-mysql
a0d0a0d46f8b: Already exists
44537f359f3a: Pull complete
9aaa9874ae7f: Pull complete
13f6c829139b: Pull complete
06add1107609: Pull complete
bfc29d6a129c: Pull complete
249c85a8a900: Pull complete
ffe4c573e59c: Pull complete
Digest: sha256:da7987fd874c50bc858b3ba2d3affde3e2f8506b7a3a5f7d42c6feb1bc9d8621
Status: Downloaded newer image for redislabs/redis-connect-mysql:pre-release-alpine
-------------------------------
Redis Connect startup script.
*******************************
Please ensure that the values of environment variables in /opt/redislabs/redis-connect-mysql/bin/redisconnect.conf are correctly mapped before executing any of the options below
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
<details><summary><b>INSERT few records into MySQL table (source) using the insert.sql or create a more realistic load using https://github.com/redis-field-engineering/redis-connect-crud-loader</b></summary>
<p>

```bash
demo$ ./insert_mysql.sh
mysql: [Warning] Using a password on the command line interface can be insecure.
count(*)
12
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
--name redis-connect-mysql \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-mysql/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-mysql/config/samples/loader \
-e REDISCONNECT_SOURCE_USERNAME=root \
-e REDISCONNECT_SOURCE_PASSWORD=Redis@123 \
-e REDISCONNECT_JAVA_OPTIONS="-Xms256m -Xmx256m" \
-v $(pwd)/../config:/opt/redislabs/redis-connect-mysql/config \
--net host \
redislabs/redis-connect-mysql:pre-release-alpine stage
```

</p>
</details>

<details><summary>Expected output:</summary>
<p>

```bash
-------------------------------
Staging Redis Connect redis-connect-mysql v0.4.0.7 job using Java 11.0.13 on virag-cdc started by root in /opt/redislabs/redis-connect-mysql/bin
Loading Redis Connect redis-connect-mysql Configurations from /opt/redislabs/redis-connect-mysql/config/samples/loader
04:20:11,322 |-INFO in ch.qos.logback.classic.LoggerContext[default] - Found resource [/opt/redislabs/redis-connect-mysql/config/logback.xml] at [file:/opt/redislabs/redis-connect-mysql/config/logback.xml]
04:20:11,498 |-INFO in ch.qos.logback.classic.joran.action.ConfigurationAction - Will scan for changes in [file:/opt/redislabs/redis-connect-mysql/config/logback.xml]
....
....
04:20:11.584 [main] INFO  startup - ##################################################################
04:20:11.586 [main] INFO  startup -
04:20:11.587 [main] INFO  startup - REDIS CONNECT SETUP CLEAN - Deletes metadata related to Redis Connect from Job Management Database

04:20:11.587 [main] INFO  startup -
04:20:11.587 [main] INFO  startup - ##################################################################
....
....
04:20:13.910 [main] INFO  startup - ##################################################################
04:20:13.912 [main] INFO  startup -
04:20:13.913 [main] INFO  startup - REDIS CONNECT SETUP CREATE - Seed metadata related to Redis Connect to Job Management Database
04:20:13.913 [main] INFO  startup -
04:20:13.913 [main] INFO  startup - ##################################################################
04:20:14.639 [main] INFO  startup - Instance: 99@virag-cdc will attempt Job Management Database (Redis) with all the configurations and scripts, if applicable, needed to execute jobs
04:20:15.375 [main] INFO  startup - Instance: 99@virag-cdc successfully established Redis connection for INIT service
04:20:15.377 [main] INFO  startup - Instance: 99@virag-cdc successfully created Job Claim Assignment Stream and Consumer Group
04:20:15.391 [main] INFO  startup - Instance: 99@virag-cdc successfully seeded Job related metadata
04:20:15.392 [main] INFO  startup - Instance: 99@virag-cdc successfully seeded Metrics related metadata
04:20:15.392 [main] INFO  startup - Instance: 99@virag-cdc successfully staged Job Management Database (Redis) with all the configurations and scripts, if applicable, needed to execute jobs
-------------------------------
```

</p>
</details>

<details><summary><b>Start pre configured loader job</b></summary>
<p>

```bash
docker run \
-it --rm --privileged=true \
--name redis-connect-mysql \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-mysql/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-mysql/config/samples/loader \
-e REDISCONNECT_REST_API_ENABLED=false \
-e REDISCONNECT_REST_API_PORT=8282 \
-e REDISCONNECT_SOURCE_USERNAME=root \
-e REDISCONNECT_SOURCE_PASSWORD=Redis@123 \
-e REDISCONNECT_JAVA_OPTIONS="-Xms256m -Xmx1g" \
-v $(pwd)/../config:/opt/redislabs/redis-connect-mysql/config \
--net host \
redislabs/redis-connect-mysql:pre-release-alpine start
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
--name redis-connect-mysql \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-mysql/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-mysql/config/samples/mysql \
-e REDISCONNECT_SOURCE_USERNAME=redisconnectuser \
-e REDISCONNECT_SOURCE_PASSWORD=redisconnectpassword \
-e REDISCONNECT_JAVA_OPTIONS="-Xms256m -Xmx256m" \
-v $(pwd)/../config:/opt/redislabs/redis-connect-mysql/config \
--net host \
redislabs/redis-connect-mysql:pre-release-alpine stage
```

</p>
</details>

<details><summary>Expected output:</summary>
<p>

```bash
-------------------------------
Staging Redis Connect redis-connect-mysql v0.4.0.7 job using Java 11.0.13 on virag-cdc started by root in /opt/redislabs/redis-connect-mysql/bin
Loading Redis Connect redis-connect-mysql Configurations from /opt/redislabs/redis-connect-mysql/config/samples/mysql

06:37:36,477 |-INFO in ch.qos.logback.classic.LoggerContext[default] - Found resource [/opt/redislabs/redis-connect-mysql/config/logback.xml] at [file:/opt/redislabs/redis-connect-mysql/config/logback.xml]
....
....
06:37:36.727 [main] INFO  startup - ##################################################################
06:37:36.730 [main] INFO  startup -
06:37:36.730 [main] INFO  startup - REDIS CONNECT SETUP CLEAN - Deletes metadata related to Redis Connect from Job Management Database

06:37:36.730 [main] INFO  startup -
06:37:36.730 [main] INFO  startup - ##################################################################
....
....
06:37:39.104 [main] INFO  startup - ##################################################################
06:37:39.106 [main] INFO  startup -
06:37:39.106 [main] INFO  startup - REDIS CONNECT SETUP CREATE - Seed metadata related to Redis Connect to Job Management Database
06:37:39.106 [main] INFO  startup -
06:37:39.106 [main] INFO  startup - ##################################################################
06:37:39.841 [main] INFO  startup - Instance: 99@virag-cdc will attempt Job Management Database (Redis) with all the configurations and scripts, if applicable, needed to execute jobs
06:37:40.591 [main] INFO  startup - Instance: 99@virag-cdc successfully established Redis connection for INIT service
06:37:40.593 [main] INFO  startup - Instance: 99@virag-cdc successfully created Job Claim Assignment Stream and Consumer Group
06:37:40.607 [main] INFO  startup - Instance: 99@virag-cdc successfully seeded Job related metadata
06:37:40.755 [main] ERROR startup - Key - RedisConnect:emp:C:Throughput already exists
06:37:40.756 [main] ERROR startup - Key - RedisConnect:emp:U:Throughput already exists
06:37:40.757 [main] ERROR startup - Key - RedisConnect:emp:D:Throughput already exists
06:37:40.759 [main] ERROR startup - Key - RedisConnect:emp:Latency already exists
06:37:40.769 [main] INFO  startup - Instance: 99@virag-cdc successfully seeded Metrics related metadata
06:37:40.769 [main] INFO  startup - Instance: 99@virag-cdc successfully staged Job Management Database (Redis) with all the configurations and scripts, if applicable, needed to execute jobs
-------------------------------
```

</p>
</details>

<details><summary><b>Start pre configured cdc job</b></summary>
<p>

```bash
docker run \
-it --rm --privileged=true \
--name redis-connect-mysql \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-mysql/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-mysql/config/samples/mysql \
-e REDISCONNECT_REST_API_ENABLED=true \
-e REDISCONNECT_REST_API_PORT=8282 \
-e REDISCONNECT_SOURCE_USERNAME=redisconnectuser \
-e REDISCONNECT_SOURCE_PASSWORD=redisconnectpassword \
-e REDISCONNECT_JAVA_OPTIONS="-Xms256m -Xmx1g" \
-v $(pwd)/../config:/opt/redislabs/redis-connect-mysql/config \
--net host \
redislabs/redis-connect-mysql:pre-release-alpine start
```

</p>
</details>

<details><summary>Expected output:</summary>
<p>

```bash
-------------------------------
Starting Redis Connect redis-connect-mysql v0.4.0.7 instance using Java 11.0.13 on virag-cdc started by root in /opt/redislabs/redis-connect-mysql/bin
Loading Redis Connect redis-connect-mysql Configurations from /opt/redislabs/redis-connect-mysql/config/samples/mysql
06:37:51,779 |-INFO in ch.qos.logback.classic.LoggerContext[default] - Found resource [/opt/redislabs/redis-connect-mysql/config/logback.xml] at [file:/opt/redislabs/redis-connect-mysql/config/logback.xml]
....
....
06:37:52.098 [main] INFO  startup -
06:37:52.103 [main] INFO  startup -  /$$$$$$$                  /$$ /$$                  /$$$$$$                                                      /$$
06:37:52.103 [main] INFO  startup - | $$__  $$                | $$|__/                 /$$__  $$                                                    | $$
06:37:52.104 [main] INFO  startup - | $$  \ $$  /$$$$$$   /$$$$$$$ /$$  /$$$$$$$      | $$  \__/  /$$$$$$  /$$$$$$$  /$$$$$$$   /$$$$$$   /$$$$$$$ /$$$$$$
06:37:52.104 [main] INFO  startup - | $$$$$$$/ /$$__  $$ /$$__  $$| $$ /$$_____/      | $$       /$$__  $$| $$__  $$| $$__  $$ /$$__  $$ /$$_____/|_  $$_/
06:37:52.104 [main] INFO  startup - | $$__  $$| $$$$$$$$| $$  | $$| $$|  $$$$$$       | $$      | $$  \ $$| $$  \ $$| $$  \ $$| $$$$$$$$| $$        | $$
06:37:52.105 [main] INFO  startup - | $$  \ $$| $$_____/| $$  | $$| $$ \____  $$      | $$    $$| $$  | $$| $$  | $$| $$  | $$| $$_____/| $$        | $$ /$$
06:37:52.105 [main] INFO  startup - | $$  | $$|  $$$$$$$|  $$$$$$$| $$ /$$$$$$$/      |  $$$$$$/|  $$$$$$/| $$  | $$| $$  | $$|  $$$$$$$|  $$$$$$$  |  $$$$/
06:37:52.105 [main] INFO  startup - |__/  |__/ \_______/ \_______/|__/|_______/        \______/  \______/ |__/  |__/|__/  |__/ \_______/ \_______/   \___/
06:37:52.105 [main] INFO  startup -
06:37:52.105 [main] INFO  startup - ##################################################################
06:37:52.105 [main] INFO  startup -
06:37:52.105 [main] INFO  startup - Initializing Redis Connect Instance
06:37:52.106 [main] INFO  startup -
06:37:52.106 [main] INFO  startup - ##################################################################
....
....
06:38:08.788 [JobManager-1] INFO  startup - Instance: 30@virag-cdc successfully established Redis connection for HeartbeatManager service
06:38:08.788 [JobManager-1] INFO  startup - Instance: 30@virag-cdc was successfully elected Redis Connect cluster leader
06:38:18.858 [JobManager-1] INFO  startup - Getting instance of EventHandler for : REDIS_HASH_WRITER
06:38:18.890 [JobManager-1] INFO  startup - Instance: 30@virag-cdc successfully established Redis connection for RedisConnectorEventHandler service
06:38:18.893 [JobManager-1] INFO  startup - Getting instance of EventHandler for : REDIS_HASH_CHECKPOINT_WRITER
06:38:18.894 [JobManager-1] WARN  startup - metricsKey not set - Metrics collection will be disabled
06:38:18.912 [JobManager-1] INFO  startup - Instance: 30@virag-cdc successfully established Redis connection for RedisCheckpointReader service
06:38:18.925 [JobManager-1] INFO  redisconnect - Reading Mapper Config from : /opt/redislabs/redis-connect-mysql/config/samples/mysql/mappers
06:38:18.940 [JobManager-1] INFO  redisconnect - Loaded Config for : RedisConnect.emp
06:38:19.469 [JobManager-1] INFO  i.d.connector.common.BaseSourceTask - Starting MySqlConnectorTask with configuration:
....
....
```

</p>
</details>

<details><summary><b>INSERT a record into MySQL table (source) using the command line or provided script, insert_mysql.sh in the demo directory</b></summary>
<p>

```bash
sudo docker exec -it mysql-latest-virag-cdc bash -c "mysql -uroot -pRedis@123 RedisConnect"

mysql> insert into emp values(1002, 'Virag', 'Tripathi', 'SA', 1, '2018-08-06 00:00:00.000', '2000', '10', 1);
Query OK, 1 row affected (0.00 sec)
mysql> quit
Bye
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

Similarly `UPDATE` and `DELETE` records on SQL Server source using queries on the command line or provided scripts [update_mysql.sh](update_mysql.sh) and [delete_mysql.sh](delete_mysql.sh) and see Redis target getting updated in near real-time.

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
--name redis-connect-mysql \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-mysql/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-mysql/config/samples/loader \
-e REDISCONNECT_SOURCE_USERNAME=root \
-e REDISCONNECT_SOURCE_PASSWORD=Redis@123 \
-e REDISCONNECT_JAVA_OPTIONS="-Xms256m -Xmx256m" \
-v $(pwd)/../config:/opt/redislabs/redis-connect-mysql/config \
-v $(pwd)/../extlib:/opt/redislabs/redis-connect-mysql/extlib \
--net host \
redislabs/redis-connect-mysql:pre-release-alpine stage
```

</p>
</details>

<details><summary><b>Start pre configured loader job with Custom Stage</b></summary>
<p>

```bash
docker run \
-it --rm --privileged=true \
--name redis-connect-mysql \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-mysql/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-mysql/config/samples/loader \
-e REDISCONNECT_REST_API_ENABLED=false \
-e REDISCONNECT_REST_API_PORT=8282 \
-e REDISCONNECT_SOURCE_USERNAME=sa \
-e REDISCONNECT_SOURCE_PASSWORD=Redis@123 \
-e REDISCONNECT_JAVA_OPTIONS="-Xms256m -Xmx1g" \
-v $(pwd)/../config:/opt/redislabs/redis-connect-mysql/config \
-v $(pwd)/../extlib:/opt/redislabs/redis-connect-mysql/extlib \
--net host \
redislabs/redis-connect-mysql:pre-release-alpine start
```

</p>
</details>

Validate the output after CustomStage run and make sure that `fname` and `lname` values in Redis has been updated to UPPER CASE.
