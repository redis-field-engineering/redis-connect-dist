# Prerequisites
Docker compatible [*nix OS](https://en.wikipedia.org/wiki/Unix-like) and [Docker](https://docs.docker.com/get-docker) installed.
<br>Please have 8 vCPU*, 8GB RAM and 50GB storage for this demo to function properly. Adjust the resources based on your requirements. For HA, at least have 2 Redis Connect Connector instances deployed on separate hosts.</br>
<br>Execute the following commands (copy & paste) to download and setup Redis Connect Postgres Connector and demo scripts.
i.e.</br>
```bash
wget -c https://github.com/RedisLabs-Field-Engineering/redis-connect-dist/archive/main.zip && \
mkdir -p redis-connect-postgres/demo && \
unzip main.zip "redis-connect-dist-main/connectors/postgres/demo/*" -d redis-connect-postgres/demo && \
cp -R redis-connect-postgres/demo/redis-connect-dist-main/connectors/postgres/demo/* redis-connect-postgres/demo && \
mv redis-connect-postgres/demo/config redis-connect-postgres && \
rm -rf main.zip redis-connect-postgres/demo/redis-connect-dist-main && \
cd redis-connect-postgres && \
chmod a+x demo/*.sh
```
Expected output:
```bash
redis-connect-postgres$ ls
config demo
```

## Setup PostgreSQL 10+ database (Source)
<b>_PostgreSQL on Docker_</b>
<br>Execute [setup_postgres.sh](setup_postgres.sh)</br>
```bash
redis-connect-postgres$ cd demo
demo$ ./setup_postgres.sh 12.5
(or latest or any supported 10+ version from postgres dockerhub)
```
<b>_PostgreSQL on Amazon RDS_</b>
* Set the instance parameter `rds.logical_replication` to `1`.
* Verify that the `wal_level` parameter is set to `logical` by running the query `SHOW wal_level` as the database RDS master user.
  This might not be the case in multi-zone replication setups.
  You cannot set this option manually.
  It is [automatically changed](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_WorkingWithParamGroups.html) when the `rds.logical_replication` parameter is set to `1`.
  If the `wal_level` is not set to `logical` after you make the preceding change, it is probably because the instance has to be restarted after the parameter group change.
  Restarts occur during your maintenance window, or you can initiate a restart manually.
* Initiate logical replication from an AWS account that has the `rds_replication` role.
  The role grants permissions to manage logical slots and to stream data using logical slots.
  By default, only the master user account on AWS has the `rds_replication` role on Amazon RDS.
  To enable a user account other than the master account to initiate logical replication, you must grant the account the `rds_replication` role.
  For example, `grant rds_replication to _<my_user>_`. You must have `superuser` access to grant the `rds_replication` role to a user.
  To enable accounts other than the master account to create an initial snapshot, you must grant `SELECT` permission to the accounts on the tables to be captured.
  For more information about security for PostgreSQL logical replication, see the [PostgreSQL documentation](https://www.postgresql.org/docs/current/logical-replication-security.html).

## Setup Redis Enterprise cluster, databases and RedisInsight in docker (Target)
<br>Execute [setup_re.sh](setup_re.sh)</br>
```bash
demo$ ./setup_re.sh
```
**NOTE**

The above script will create a 1-node Redis Enterprise cluster in a docker container, [Create a target database with RediSearch module](https://docs.redislabs.com/latest/modules/add-module-to-database/), [Create a job management and metrics database with RedisTimeSeries module](https://docs.redislabs.com/latest/modules/add-module-to-database/), [Create a RediSearch index for emp Hash](https://redislabs.com/blog/getting-started-with-redisearch-2-0/), [Start a docker instance of grafana with Redis Data Source](https://redisgrafana.github.io/) and [Start an instance of RedisInsight](https://docs.redislabs.com/latest/ri/installing/install-docker/).

## Start Redis Connect Postgres Connector

* Run Redis Connect Postgres Connector docker container to see all the options
```bash
docker run \
-it --rm --privileged=true \
--name redis-connect-postgres \
-e LOGBACK_CONFIG=/opt/redislabs/redis-connect-postgres/config/logback.xml \
-e REDIS_CONNECT_CONFIG=/opt/redislabs/redis-connect-postgres/config/samples/postgres \
-e REST_API_ENABLED=true \
-e REST_API_PORT=8282 \
-e REDISCONNECT_SOURCE_USERNAME=redisconnect \
-e REDISCONNECT_SOURCE_PASSWORD=Redis@123 \
-e JAVA_OPTIONS="-Xms256m -Xmx1g" \
-v $(pwd)/../config:/opt/redislabs/redis-connect-postgres/config \
--net host \
redislabs/redis-connect-postgres:pre-release-alpine
```

<details><summary>Expected output:</summary>
<p>
  
```bash
-------------------------------
Redis Connect Connector wrapper script for Docker containers.

Usage: [-h|-v|start_cli|stage_cdc|stage_loader|start_cdc|start_loader]
options:
-h: Print this help message and exit.
-v: Print version information and exit.
start_cli: starts redis-connect-cli.
stage_cdc: clean and stage redis database with cdc job configurations.
stage_loader: clean and stage redis database with initial loader job configurations.
start_cdc: start Redis Connect connector instance.
start_loader: start Redis Connect initial loader instance.
-------------------------------
```

</p>
</details>

* Stage pre configured cdc job
```bash
docker run \
-it --rm --privileged=true \
--name redis-connect-postgres \
-e LOGBACK_CONFIG=/opt/redislabs/redis-connect-postgres/config/logback.xml \
-e REDIS_CONNECT_CONFIG=/opt/redislabs/redis-connect-postgres/config/samples/postgres \
-e REST_API_ENABLED=true \
-e REST_API_PORT=8282 \
-e REDISCONNECT_SOURCE_USERNAME=redisconnect \
-e REDISCONNECT_SOURCE_PASSWORD=Redis@123 \
-e JAVA_OPTIONS="-Xms256m -Xmx1g" \
-v $(pwd)/../config:/opt/redislabs/redis-connect-postgres/config \
--net host \
redislabs/redis-connect-postgres:pre-release-alpine stage_cdc
```

<details><summary>Expected output:</summary>
<p>

```bash
-------------------------------
/opt/redislabs/redis-connect-postgres/config/samples/postgres
.....
.....
19:24:21.258 [main] INFO  startup - Setup Completed.
-------------------------------
```

</p>
</details>

* Start pre configured cdc job
```bash
docker run \
-itd --rm --privileged=true \
--name redis-connect-postgres \
-e LOGBACK_CONFIG=/opt/redislabs/redis-connect-postgres/config/logback.xml \
-e REDIS_CONNECT_CONFIG=/opt/redislabs/redis-connect-postgres/config/samples/postgres \
-e REST_API_ENABLED=true \
-e REST_API_PORT=8282 \
-e REDISCONNECT_SOURCE_USERNAME=redisconnect \
-e REDISCONNECT_SOURCE_PASSWORD=Redis@123 \
-e JAVA_OPTIONS="-Xms256m -Xmx1g" \
-v $(pwd)/../config:/opt/redislabs/redis-connect-postgres/config \
--net host \
redislabs/redis-connect-postgres:pre-release-alpine start_cdc
```

<details><summary>Expected output:</summary>
<p>

```bash
-------------------------------
/opt/redislabs/redis-connect-postgres/config/samples/postgres
.....
.....
19:28:57.813 [main] INFO  startup -  /$$$$$$$                  /$$ /$$                  /$$$$$$                                                      /$$
19:28:57.817 [main] INFO  startup - | $$__  $$                | $$|__/                 /$$__  $$                                                    | $$
19:28:57.817 [main] INFO  startup - | $$  \ $$  /$$$$$$   /$$$$$$$ /$$  /$$$$$$$      | $$  \__/  /$$$$$$  /$$$$$$$  /$$$$$$$   /$$$$$$   /$$$$$$$ /$$$$$$
19:28:57.818 [main] INFO  startup - | $$$$$$$/ /$$__  $$ /$$__  $$| $$ /$$_____/      | $$       /$$__  $$| $$__  $$| $$__  $$ /$$__  $$ /$$_____/|_  $$_/
19:28:57.818 [main] INFO  startup - | $$__  $$| $$$$$$$$| $$  | $$| $$|  $$$$$$       | $$      | $$  \ $$| $$  \ $$| $$  \ $$| $$$$$$$$| $$        | $$
19:28:57.818 [main] INFO  startup - | $$  \ $$| $$_____/| $$  | $$| $$ \____  $$      | $$    $$| $$  | $$| $$  | $$| $$  | $$| $$_____/| $$        | $$ /$$
19:28:57.818 [main] INFO  startup - | $$  | $$|  $$$$$$$|  $$$$$$$| $$ /$$$$$$$/      |  $$$$$$/|  $$$$$$/| $$  | $$| $$  | $$|  $$$$$$$|  $$$$$$$  |  $$$$/
19:28:57.818 [main] INFO  startup - |__/  |__/ \_______/ \_______/|__/|_______/        \______/  \______/ |__/  |__/|__/  |__/ \_______/ \_______/   \___/
19:28:57.818 [main] INFO  startup -
19:28:57.819 [main] INFO  startup -
19:28:57.819 [main] INFO  startup - ##################################################################
19:28:57.819 [main] INFO  startup -
19:28:57.819 [main] INFO  startup - Initializing Redis Connect Instance
19:28:57.819 [main] INFO  startup -
19:28:57.819 [main] INFO  startup - ##################################################################
.....
.....
19:29:17.316 [JobManagement-1] INFO  redisconnect - Server type configured as - postgres
19:29:17.318 [JobManagement-1] INFO  redisconnect - Reading Mapper Config from : /opt/redislabs/redis-connect-postgres/config/samples/postgres/mappers
19:29:17.545 [JobManagement-1] INFO  redisconnect - Loaded Config for : public.emp
19:29:17.841 [JobManagement-1] INFO  startup - Fetched JobConfig for : testdb-postgres
19:29:17.841 [JobManagement-1] INFO  startup - Starting Pipeline for Job : testdb-postgres
19:29:17.842 [JobManagement-1] INFO  startup - 1 of 1 Jobs Claimed
19:29:17.842 [JobManagement-2] INFO  redisconnect - Refreshing Heartbeat signal for : hb-job:testdb-postgres , with value : JC-7@virag-cdc , expiry : 30000
19:29:17.842 [JobManagement-1] INFO  startup - 1 of 1 Jobs Claimed
.....
.....  
```

</p>
</details>
