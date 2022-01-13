# Prerequisites

* Docker compatible [*nix OS](https://en.wikipedia.org/wiki/Unix-like) and [Docker](https://docs.docker.com/get-docker) installed.
* Please have 8 vCPU*, 8GB RAM and 50GB storage for this demo to function properly. Adjust the resources based on your requirements. For HA, at least have 2 Redis Connect Connector instances deployed on separate hosts.
* [Oracle JDBC Driver](https://www.oracle.com/database/technologies/appdev/jdbc-downloads.html) (`ojdbc8.jar`)

| :exclamation: IMPORTANT                                                                                                                                                                    |
|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| We can not include the Oracle JDBC Driver due to licensing requirement. Please obtain the Oracle client jar following the link above or get a copy from your existing Oracle installation. |

<p>Execute the following commands (copy & paste) to download and setup Redis Connect Oracle Connector and demo scripts.
i.e.</p>

```bash
wget -c https://github.com/redis-field-engineering/redis-connect-dist/archive/main.zip && \
mkdir -p redis-connect-oracle/demo && \
mkdir -p redis-connect-oracle/k8s-docs && \
unzip main.zip "redis-connect-dist-main/connectors/oracle/*" -d redis-connect-oracle && \
cp -R redis-connect-oracle/redis-connect-dist-main/connectors/oracle/demo/* redis-connect-oracle/demo && \
cp -R redis-connect-oracle/redis-connect-dist-main/connectors/oracle/k8s-docs/* redis-connect-oracle/k8s-docs && \
rm -rf main.zip redis-connect-oracle/redis-connect-dist-main && \
cd redis-connect-oracle && \
chmod a+x demo/*.sh
```

Expected output:
```bash
redis-connect-oracle$ ls
config demo
```

## Setup Oracle database in docker (Source)

<br>Execute [setup_oracle.sh](setup_oracle.sh)</br>
_**Oracle 12c and 18c:**_

```bash
redis-connect-oracle$ cd demo
demo$ ./setup_oracle.sh 12.2.0.1-ee 1521 logminer
```
_**Oracle 19c:**_

```bash
demo$ ./setup_oracle.sh 19.3.0-ee 1522 logminer
```

<details><summary>Expected output:</summary>
<p>

```bash
Status: Downloaded newer image for virag/oracle-12.2.0.1-ee:latest
ae728fa6e001c2f67e7a783ae2db9bd1999b0d4d6d9f72888a1b0b4473216db1
nc: connect to 172.17.0.9 port 1521 (tcp) failed: Connection refused
Wed Nov 17 19:39:02 UTC 2021 - still trying
Connection to 172.17.0.9 1521 port [tcp/*] succeeded!
Wed Nov 17 19:39:04 UTC 2021 - connected successfully
Wed Nov 17 19:39:04 UTC 2021 - Waiting for oracle database to be up (attempt: 1)...
....
....
SQL> Disconnected from Oracle Database 12c Enterprise Edition Release 12.2.0.1.0 - 64bit Production
The Oracle base remains unchanged with value /opt/oracle
#########################
DATABASE IS READY TO USE!
#########################
....
....
Completed:   ALTER DATABASE ADD SUPPLEMENTAL LOG DATA
2021-11-17T19:46:34.230847+00:00
===========================================================
....
....
SQL> SQL> Connected.
SQL>
  COUNT(*)
----------
       107

1 row selected.

SQL> Disconnected from Oracle Database 12c Enterprise Edition Release 12.2.0.1.0 - 64bit Production
```

</p>
</details>

<details><summary>Validate Oracle database is running as expected:</summary>
<p>

```bash
demo$ docker ps -a | grep oracle
ae728fa6e001        virag/oracle-12.2.0.1-ee                     "/bin/sh -c 'exec $O…"   5 hours ago         Up 5 hours (healthy)    0.0.0.0:1521->1521/tcp                                                                                                                                                                                                                                                                                          oracle-12.2.0.1-ee-virag-cdc
cb7c33534565        virag/oracle-19.3.0-ee                       "/bin/sh -c 'exec $O…"   44 hours ago        Up 44 hours (healthy)   0.0.0.0:1522->1521/tcp                                                                                                                                                                                                                                                                                          oracle-19.3.0-ee-virag-cdc

demo$ docker exec -it oracle-12.2.0.1-ee-$(hostname) bash -c "sqlplus sys/Redis123@ORCLPDB1 as sysdba"

SQL*Plus: Release 12.2.0.1.0 Production on Wed Nov 17 20:22:35 2021

Copyright (c) 1982, 2016, Oracle.  All rights reserved.


Connected to:
Oracle Database 12c Enterprise Edition Release 12.2.0.1.0 - 64bit Production

SQL> select 1 from dual;

	 1
----------
	 1
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
1) "idx:employees"
```
</p>
</details>

---

| :memo:        |
|---------------|

The above script will create a 1-node Redis Enterprise cluster in a docker container, [Create a target database with RediSearch module](https://docs.redislabs.com/latest/modules/add-module-to-database/), [Create a job management and metrics database with RedisTimeSeries module](https://docs.redislabs.com/latest/modules/add-module-to-database/), [Create a RediSearch index for emp Hash](https://redislabs.com/blog/getting-started-with-redisearch-2-0/) and [Start an instance of RedisInsight](https://docs.redislabs.com/latest/ri/installing/install-docker/).

---

## Start Redis Connect Oracle Connector

| :point_up:    | Don't forget to download and copy the Oracle client jar into the extlib folder i.e. `demo$ cp ojdbc8.jar extlib` (we have included ojdbc8.jar for this demo purposes) |
|---------------|:----------------------------------------------------------------------------------------------------------------------------------------------------------------------|

<details><summary>Run Redis Connect Oracle Connector docker container to see all the options</summary>
<p>

```bash
docker run \
-it --rm --privileged=true \
--name redis-connect-oracle \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-oracle/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-oracle/config/samples/oracle \
-v $(pwd)/config:/opt/redislabs/redis-connect-oracle/config \
--net host \
redislabs/redis-connect-oracle:latest
```

</p>
</details>

<details><summary>Expected output:</summary>
<p>

```bash
Unable to find image 'redislabs/redis-connect-oracle:latest' locally
latest: Pulling from redislabs/redis-connect-oracle
97518928ae5f: Already exists
7e453f2d6ca6: Pull complete
fbe136ef5948: Pull complete
b765f6e5f803: Pull complete
26dfdb35b1c9: Pull complete
8c79ede59dbd: Pull complete
fa1f01880109: Pull complete
f1620ca0c97f: Pull complete
919ed065f3c8: Pull complete
e1bffcb6a74e: Pull complete
Digest: sha256:c076f988b517c1bc66c7c3d897915c8e5caeaaf094560a18bb057d3df0e56afb
Status: Downloaded newer image for redislabs/redis-connect-oracle:latest
-------------------------------
Redis Connect startup script.
*******************************
Please ensure that the values of environment variables in /opt/redislabs/redis-connect-oracle/bin/redisconnect.conf are correctly mapped before executing any of the options below
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

<details><summary><b>INSERT few records into Oracle table (source) or create a more realistic load using https://github.com/redis-field-engineering/redis-connect-crud-loader</b></summary>

The Oracle [setup](setup_logminer.sh) already loads [Oracle's HR Sample Schema Tables](https://docs.oracle.com/en/database/oracle/oracle-database/19/comsc/HR-sample-schema-table-descriptions.html#GUID-506C25CE-FA5D-472A-9C4C-F9EF200823EE)
<p>Please follow the steps below if you need to load more data into the oracle table before starting the loader job.</p>

Load data using [load sql scripts](load_sql.sh):
<p>

* 12c
```bash
docker exec -it oracle-12.2.0.1-ee-$(hostname) bash -c "/tmp/load_sql.sh insert10k"
```
* 19c
```bash
docker exec -it oracle-19.3.0-ee-$(hostname) bash -c "/tmp/load_sql.sh insert10k"
```
</p>

Load data using crud loader:
<p>

```bash
redis-connect-crud-loader/bin$ ./start.sh crudloader
```
</p>
</details>

<details><summary><b>Stage pre-configured loader job</b></summary>
<p>

Please update the Oracle database port according to your setup e.g. In this demo setup port `1521` is used with Oracle `12c` and port `1522` is used with Oracle `19c`.
```bash
docker run \
-it --rm --privileged=true \
--name redis-connect-oracle \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-oracle/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-oracle/config/samples/loader \
-e REDISCONNECT_PDBNAME=ORCLPDB1 \
-e REDISCONNECT_SOURCE_URL=jdbc:oracle:thin:@127.0.0.1:1521/ORCLPDB1?oracle.net.disableOob=true \
-e REDISCONNECT_SOURCE_HOST=127.0.0.1 \
-e REDISCONNECT_SOURCE_PORT=1521 \
-e REDISCONNECT_SOURCE_USERNAME=hr \
-e REDISCONNECT_SOURCE_PASSWORD=hr \
-e REDISCONNECT_JOBCONFIG_REDIS_URL=redis://127.0.0.1:14001 \
-e REDISCONNECT_TARGET_REDIS_URL=redis://127.0.0.1:14000 \
-e REDISCONNECT_METRICS_REDIS_URL=redis://127.0.0.1:14001 \
-e REDISCONNECT_JAVA_OPTIONS="-Xms256m -Xmx256m -Doracle.net.disableOob=true" \
-v $(pwd)/config:/opt/redislabs/redis-connect-oracle/config \
-v $(pwd)/extlib:/opt/redislabs/redis-connect-oracle/extlib \
--net host \
redislabs/redis-connect-oracle:latest stage
```

</p>
</details>

<details><summary>Expected output:</summary>
<p>

```bash
-------------------------------
Staging Redis Connect redis-connect-oracle v0.6.1.1 job using Java 11.0.13 on virag-cdc started by root in /opt/redislabs/redis-connect-oracle/bin
Loading Redis Connect redis-connect-oracle Configurations from /opt/redislabs/redis-connect-oracle/config/samples/loader
01:14:59,609 |-INFO in ch.qos.logback.classic.LoggerContext[default] - Found resource [/opt/redislabs/redis-connect-oracle/config/logback.xml] at [file:/opt/redislabs/redis-connect-oracle/config/logback.xml]
....
01:14:59.913 [main] INFO  startup - ##################################################################
01:14:59.916 [main] INFO  startup -
01:14:59.916 [main] INFO  startup - REDIS CONNECT SETUP CLEAN - Deletes metadata related to Redis Connect from Job Management Database

01:14:59.916 [main] INFO  startup -
01:14:59.916 [main] INFO  startup - ##################################################################
01:15:00.631 [main] INFO  startup - Instance: 31@virag-cdc will attempt to delete (clean) all the metadata related to Redis Connect
01:15:01.418 [main] INFO  startup - Instance: 31@virag-cdc successfully established Redis connection for INIT service
01:15:01.426 [main] INFO  startup - Instance: 31@virag-cdc successfully completed flush (clean) of all the metadata related to Redis Connect
....
01:15:02.279 [main] INFO  startup - ##################################################################
01:15:02.281 [main] INFO  startup -
01:15:02.281 [main] INFO  startup - REDIS CONNECT SETUP CREATE - Seed metadata related to Redis Connect to Job Management Database
01:15:02.281 [main] INFO  startup -
01:15:02.281 [main] INFO  startup - ##################################################################
01:15:02.981 [main] INFO  startup - Instance: 95@virag-cdc will attempt Job Management Database (Redis) with all the configurations and scripts, if applicable, needed to execute jobs
01:15:03.711 [main] INFO  startup - Instance: 95@virag-cdc successfully established Redis connection for INIT service
01:15:03.714 [main] INFO  startup - Instance: 95@virag-cdc successfully created Job Claim Assignment Stream and Consumer Group
01:15:03.728 [main] INFO  startup - Instance: 95@virag-cdc successfully seeded Job related metadata
01:15:03.728 [main] INFO  startup - Instance: 95@virag-cdc successfully seeded Metrics related metadata
01:15:03.728 [main] INFO  startup - Instance: 95@virag-cdc successfully staged Job Management Database (Redis) with all the configurations and scripts, if applicable, needed to execute jobs
-------------------------------
```

</p>
</details>

<details><summary><b>Start pre-configured loader job</b></summary>
<p>

Please update the Oracle database port according to your setup e.g. In this demo setup port `1521` is used with Oracle `12c` and port `1522` is used with Oracle `19c`.
```bash
docker run \
-it --rm --privileged=true \
--name redis-connect-oracle \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-oracle/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-oracle/config/samples/loader \
-e REDISCONNECT_PDBNAME=ORCLPDB1 \
-e REDISCONNECT_SOURCE_URL=jdbc:oracle:thin:@127.0.0.1:1521/ORCLPDB1?oracle.net.disableOob=true \
-e REDISCONNECT_SOURCE_HOST=127.0.0.1 \
-e REDISCONNECT_SOURCE_PORT=1521 \
-e REDISCONNECT_SOURCE_USERNAME=hr \
-e REDISCONNECT_SOURCE_PASSWORD=hr \
-e REDISCONNECT_JOBCONFIG_REDIS_URL=redis://127.0.0.1:14001 \
-e REDISCONNECT_TARGET_REDIS_URL=redis://127.0.0.1:14000 \
-e REDISCONNECT_METRICS_REDIS_URL=redis://127.0.0.1:14001 \
-e REDISCONNECT_JAVA_OPTIONS="-Xms256m -Xmx256m -Doracle.net.disableOob=true" \
-v $(pwd)/config:/opt/redislabs/redis-connect-oracle/config \
-v $(pwd)/extlib:/opt/redislabs/redis-connect-oracle/extlib \
--net host \
redislabs/redis-connect-oracle:latest start
```

</p>
</details>

<details><summary>Expected output:</summary>
<p>

```bash
-------------------------------
Starting Redis Connect redis-connect-oracle v0.6.1.1 instance using Java 11.0.13 on virag-cdc started by root in /opt/redislabs/redis-connect-oracle/bin
Loading Redis Connect redis-connect-oracle Configurations from /opt/redislabs/redis-connect-oracle/config/samples/loader
01:18:32,266 |-INFO in ch.qos.logback.classic.LoggerContext[default] - Found resource [/opt/redislabs/redis-connect-oracle/config/logback.xml] at [file:/opt/redislabs/redis-connect-oracle/config/logback.xml]
....
01:18:32.575 [main] INFO  startup -
01:18:32.578 [main] INFO  startup -  /$$$$$$$                  /$$ /$$                  /$$$$$$                                                      /$$
01:18:32.578 [main] INFO  startup - | $$__  $$                | $$|__/                 /$$__  $$                                                    | $$
01:18:32.579 [main] INFO  startup - | $$  \ $$  /$$$$$$   /$$$$$$$ /$$  /$$$$$$$      | $$  \__/  /$$$$$$  /$$$$$$$  /$$$$$$$   /$$$$$$   /$$$$$$$ /$$$$$$
01:18:32.579 [main] INFO  startup - | $$$$$$$/ /$$__  $$ /$$__  $$| $$ /$$_____/      | $$       /$$__  $$| $$__  $$| $$__  $$ /$$__  $$ /$$_____/|_  $$_/
01:18:32.579 [main] INFO  startup - | $$__  $$| $$$$$$$$| $$  | $$| $$|  $$$$$$       | $$      | $$  \ $$| $$  \ $$| $$  \ $$| $$$$$$$$| $$        | $$
01:18:32.579 [main] INFO  startup - | $$  \ $$| $$_____/| $$  | $$| $$ \____  $$      | $$    $$| $$  | $$| $$  | $$| $$  | $$| $$_____/| $$        | $$ /$$
01:18:32.579 [main] INFO  startup - | $$  | $$|  $$$$$$$|  $$$$$$$| $$ /$$$$$$$/      |  $$$$$$/|  $$$$$$/| $$  | $$| $$  | $$|  $$$$$$$|  $$$$$$$  |  $$$$/
01:18:32.580 [main] INFO  startup - |__/  |__/ \_______/ \_______/|__/|_______/        \______/  \______/ |__/  |__/|__/  |__/ \_______/ \_______/   \___/
01:18:32.580 [main] INFO  startup -
01:18:32.580 [main] INFO  startup - ##################################################################
01:18:32.580 [main] INFO  startup -
01:18:32.580 [main] INFO  startup - Initializing Redis Connect Instance
01:18:32.580 [main] INFO  startup -
01:18:32.580 [main] INFO  startup - ##################################################################
....
01:18:59.911 [JobManager-1] INFO  startup - Instance: 30@virag-cdc has claimed 1 job(s) from its 2 max allowable capacity
01:18:59.924 [JobManager-1] INFO  startup - JobId: {connect}:job:initial_load claim request with ID: 1640049303721-0 has been fully processed and all metadata has been updated
01:18:59.927 [JobManager-1] INFO  startup - Instance: 30@virag-cdc published Job Claim Transition Event to Channel: REDIS.CONNECT.JOB.CLAIM.TRANSITION.EVENTS Message: {"jobId":"{connect}:job:initial_load","instanceName":"30@virag-cdc","transitionEvent":"CLAIMED","serviceName":"JobClaimer"}
....
01:19:30.311 [JobManager-2] INFO  startup - Instance: 30@virag-cdc successfully started job execution for JobId: {connect}:task:partition:initial_load:1
01:19:30.317 [JobManager-2] INFO  startup - Instance: 30@virag-cdc successfully established Redis connection for HeartbeatManager service
01:19:30.318 [JobManager-2] INFO  startup - Instance: 30@virag-cdc has successfully claimed ownership of JobId: {connect}:task:partition:initial_load:1
01:19:30.318 [JobManager-2] INFO  startup - Instance: 30@virag-cdc has claimed 1 job(s) from its 2 max allowable capacity
01:19:30.322 [JobManager-2] INFO  startup - JobId: {connect}:task:partition:initial_load:1 claim request with ID: 1640049540105-0 has been fully processed and all metadata has been updated
01:19:30.323 [JobManager-2] INFO  startup - Instance: 30@virag-cdc published Job Claim Transition Event to Channel: REDIS.CONNECT.JOB.CLAIM.TRANSITION.EVENTS Message: {"jobId":"{connect}:task:partition:initial_load:1","instanceName":"30@virag-cdc","transitionEvent":"CLAIMED","serviceName":"JobClaimer"}
01:19:30.324 [lettuce-epollEventLoop-4-3] INFO  startup - Instance: 30@virag-cdc consumed Job Claim Transition Event on Channel: REDIS.CONNECT.JOB.CLAIM.TRANSITION.EVENTS Message: {"jobId":"{connect}:task:partition:initial_load:1","instanceName":"30@virag-cdc","transitionEvent":"CLAIMED","serviceName":"JobClaimer"}
01:19:30.349 [EventProducer-2] INFO  redisconnect - Instance: 30@virag-cdc completed JobId: {connect}:task:partition:initial_load:1 from StartRecord: 1 to EndRecord: 220
01:19:40.354 [EventProducer-2] INFO  startup - Instance: 30@virag-cdc successfully cancelled heartbeat for JobId: {connect}:task:partition:initial_load:1
01:19:40.354 [EventProducer-2] INFO  startup - Instance: 30@virag-cdc successfully stopped replication pipeline for JobId: {connect}:task:partition:initial_load:1
01:19:40.354 [EventProducer-2] INFO  startup - Instance: 30@virag-cdc now owns 0 job(s) from its 2 max allowable capacity
01:19:40.355 [EventProducer-2] INFO  startup - Instance: 30@virag-cdc successfully removed JobId: {connect}:task:partition:initial_load:1
....
01:19:59.302 [JobManager-2] INFO  startup - Instance: 30@virag-cdc successfully started job execution for JobId: {connect}:task:partition:initial_load:2
01:19:59.302 [JobManager-2] INFO  startup - Instance: 30@virag-cdc has successfully claimed ownership of JobId: {connect}:task:partition:initial_load:2
01:19:59.302 [JobManager-2] INFO  startup - Instance: 30@virag-cdc has claimed 1 job(s) from its 2 max allowable capacity
01:19:59.305 [JobManager-2] INFO  startup - JobId: {connect}:task:partition:initial_load:2 claim request with ID: 1640049540109-0 has been fully processed and all metadata has been updated
01:19:59.306 [lettuce-epollEventLoop-4-3] INFO  startup - Instance: 30@virag-cdc consumed Job Claim Transition Event on Channel: REDIS.CONNECT.JOB.CLAIM.TRANSITION.EVENTS Message: {"jobId":"{connect}:task:partition:initial_load:2","instanceName":"30@virag-cdc","transitionEvent":"CLAIMED","serviceName":"JobClaimer"}
01:19:59.306 [JobManager-2] INFO  startup - Instance: 30@virag-cdc published Job Claim Transition Event to Channel: REDIS.CONNECT.JOB.CLAIM.TRANSITION.EVENTS Message: {"jobId":"{connect}:task:partition:initial_load:2","instanceName":"30@virag-cdc","transitionEvent":"CLAIMED","serviceName":"JobClaimer"}
01:19:59.313 [EventProducer-1] INFO  redisconnect - Instance: 30@virag-cdc completed JobId: {connect}:task:partition:initial_load:2 from StartRecord: 221 to EndRecord: 440
01:20:09.317 [EventProducer-1] INFO  startup - Instance: 30@virag-cdc successfully cancelled heartbeat for JobId: {connect}:task:partition:initial_load:2
01:20:09.317 [EventProducer-1] INFO  startup - Instance: 30@virag-cdc successfully stopped replication pipeline for JobId: {connect}:task:partition:initial_load:2
01:20:09.317 [EventProducer-1] INFO  startup - Instance: 30@virag-cdc now owns 0 job(s) from its 2 max allowable capacity
01:20:09.317 [EventProducer-1] INFO  startup - Instance: 30@virag-cdc successfully removed JobId: {connect}:task:partition:initial_load:2
....
01:20:29.308 [JobManager-1] INFO  startup - Instance: 30@virag-cdc successfully started job execution for JobId: {connect}:task:partition:initial_load:3
01:20:29.308 [JobManager-1] INFO  startup - Instance: 30@virag-cdc has successfully claimed ownership of JobId: {connect}:task:partition:initial_load:3
01:20:29.308 [JobManager-1] INFO  startup - Instance: 30@virag-cdc has claimed 1 job(s) from its 2 max allowable capacity
01:20:29.311 [JobManager-1] INFO  startup - JobId: {connect}:task:partition:initial_load:3 claim request with ID: 1640049540113-0 has been fully processed and all metadata has been updated
01:20:29.312 [JobManager-1] INFO  startup - Instance: 30@virag-cdc published Job Claim Transition Event to Channel: REDIS.CONNECT.JOB.CLAIM.TRANSITION.EVENTS Message: {"jobId":"{connect}:task:partition:initial_load:3","instanceName":"30@virag-cdc","transitionEvent":"CLAIMED","serviceName":"JobClaimer"}
01:20:29.312 [lettuce-epollEventLoop-4-3] INFO  startup - Instance: 30@virag-cdc consumed Job Claim Transition Event on Channel: REDIS.CONNECT.JOB.CLAIM.TRANSITION.EVENTS Message: {"jobId":"{connect}:task:partition:initial_load:3","instanceName":"30@virag-cdc","transitionEvent":"CLAIMED","serviceName":"JobClaimer"}
01:20:29.316 [EventProducer-2] INFO  redisconnect - Instance: 30@virag-cdc completed JobId: {connect}:task:partition:initial_load:3 from StartRecord: 441 to EndRecord: 660
01:20:39.319 [EventProducer-2] INFO  startup - Instance: 30@virag-cdc successfully cancelled heartbeat for JobId: {connect}:task:partition:initial_load:3
01:20:39.320 [EventProducer-2] INFO  startup - Instance: 30@virag-cdc successfully stopped replication pipeline for JobId: {connect}:task:partition:initial_load:3
01:20:39.320 [EventProducer-2] INFO  startup - Instance: 30@virag-cdc now owns 0 job(s) from its 2 max allowable capacity
01:20:39.320 [EventProducer-2] INFO  startup - Instance: 30@virag-cdc successfully removed JobId: {connect}:task:partition:initial_load:3
....
01:20:59.303 [JobManager-2] INFO  startup - Instance: 30@virag-cdc successfully started job execution for JobId: {connect}:task:partition:initial_load:4
01:20:59.303 [JobManager-2] INFO  startup - Instance: 30@virag-cdc has successfully claimed ownership of JobId: {connect}:task:partition:initial_load:4
01:20:59.303 [JobManager-2] INFO  startup - Instance: 30@virag-cdc has claimed 1 job(s) from its 2 max allowable capacity
01:20:59.305 [JobManager-2] INFO  startup - JobId: {connect}:task:partition:initial_load:4 claim request with ID: 1640049540117-0 has been fully processed and all metadata has been updated
01:20:59.306 [JobManager-2] INFO  startup - Instance: 30@virag-cdc published Job Claim Transition Event to Channel: REDIS.CONNECT.JOB.CLAIM.TRANSITION.EVENTS Message: {"jobId":"{connect}:task:partition:initial_load:4","instanceName":"30@virag-cdc","transitionEvent":"CLAIMED","serviceName":"JobClaimer"}
01:20:59.306 [lettuce-epollEventLoop-4-3] INFO  startup - Instance: 30@virag-cdc consumed Job Claim Transition Event on Channel: REDIS.CONNECT.JOB.CLAIM.TRANSITION.EVENTS Message: {"jobId":"{connect}:task:partition:initial_load:4","instanceName":"30@virag-cdc","transitionEvent":"CLAIMED","serviceName":"JobClaimer"}
01:20:59.310 [EventProducer-1] INFO  redisconnect - Instance: 30@virag-cdc completed JobId: {connect}:task:partition:initial_load:4 from StartRecord: 661 to EndRecord: 880
01:21:09.313 [EventProducer-1] INFO  startup - Instance: 30@virag-cdc successfully cancelled heartbeat for JobId: {connect}:task:partition:initial_load:4
01:21:09.314 [EventProducer-1] INFO  startup - Instance: 30@virag-cdc successfully stopped replication pipeline for JobId: {connect}:task:partition:initial_load:4
01:21:09.314 [EventProducer-1] INFO  startup - Instance: 30@virag-cdc now owns 0 job(s) from its 2 max allowable capacity
01:21:09.314 [EventProducer-1] INFO  startup - Instance: 30@virag-cdc successfully removed JobId: {connect}:task:partition:initial_load:4
....
01:21:29.298 [JobManager-1] INFO  startup - Instance: 30@virag-cdc successfully started job execution for JobId: {connect}:task:partition:initial_load:5
01:21:29.298 [JobManager-1] INFO  startup - Instance: 30@virag-cdc has successfully claimed ownership of JobId: {connect}:task:partition:initial_load:5
01:21:29.298 [JobManager-1] INFO  startup - Instance: 30@virag-cdc has claimed 1 job(s) from its 2 max allowable capacity
01:21:29.301 [JobManager-1] INFO  startup - JobId: {connect}:task:partition:initial_load:5 claim request with ID: 1640049540119-0 has been fully processed and all metadata has been updated
01:21:29.302 [JobManager-1] INFO  startup - Instance: 30@virag-cdc published Job Claim Transition Event to Channel: REDIS.CONNECT.JOB.CLAIM.TRANSITION.EVENTS Message: {"jobId":"{connect}:task:partition:initial_load:5","instanceName":"30@virag-cdc","transitionEvent":"CLAIMED","serviceName":"JobClaimer"}
01:21:29.302 [lettuce-epollEventLoop-4-3] INFO  startup - Instance: 30@virag-cdc consumed Job Claim Transition Event on Channel: REDIS.CONNECT.JOB.CLAIM.TRANSITION.EVENTS Message: {"jobId":"{connect}:task:partition:initial_load:5","instanceName":"30@virag-cdc","transitionEvent":"CLAIMED","serviceName":"JobClaimer"}
01:21:29.305 [EventProducer-2] INFO  redisconnect - Instance: 30@virag-cdc completed JobId: {connect}:task:partition:initial_load:5 from StartRecord: 881 to EndRecord: 1104
01:21:39.308 [EventProducer-2] INFO  startup - Instance: 30@virag-cdc successfully cancelled heartbeat for JobId: {connect}:task:partition:initial_load:5
01:21:39.309 [EventProducer-2] INFO  startup - Instance: 30@virag-cdc successfully stopped replication pipeline for JobId: {connect}:task:partition:initial_load:5
01:21:39.309 [EventProducer-2] INFO  startup - Instance: 30@virag-cdc now owns 0 job(s) from its 2 max allowable capacity
01:21:39.309 [EventProducer-2] INFO  startup - Instance: 30@virag-cdc successfully removed JobId: {connect}:task:partition:initial_load:5
```

</p>
</details>

<details><summary><b>Query for the above inserted record in Redis (target)</b></summary>
<p>
e.g.

```bash
demo$ sudo docker exec -it re-node1 bash -c 'redis-cli -p 12000 ft.search idx:employees "*"'
```

</p>
</details>

-------------------------------

### CDC Steps
<details><summary><b>Stage pre-configured cdc job</b></summary>
<p>

Please update the Oracle database port according to your setup e.g. In this demo setup port `1521` is used with Oracle `12c` and port `1522` is used with Oracle `19c`.
```bash
docker run \
-it --rm --privileged=true \
--name redis-connect-oracle \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-oracle/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-oracle/config/samples/oracle \
-e REDISCONNECT_SOURCE_HOST=127.0.0.1 \
-e REDISCONNECT_SOURCE_PORT=1521 \
-e REDISCONNECT_PDBNAME=ORCLPDB1 \
-e REDISCONNECT_CDBNAME=ORCLCDB \
-e REDISCONNECT_SOURCE_URL=jdbc:oracle:thin:@127.0.0.1:1521/ORCLCDB?oracle.net.disableOob=true \
-e REDISCONNECT_SOURCE_USERNAME=c##rcuser \
-e REDISCONNECT_SOURCE_PASSWORD=rcpwd \
-e REDISCONNECT_SOURCE_METADATA_URL=jdbc:oracle:thin:@127.0.0.1:1521/ORCLPDB1?oracle.net.disableOob=true \
-e REDISCONNECT_SOURCE_METADATA_USERNAME=hr \
-e REDISCONNECT_SOURCE_METADATA_PASSWORD=hr \
-e REDISCONNECT_JOBCONFIG_REDIS_URL=redis://127.0.0.1:14001 \
-e REDISCONNECT_TARGET_REDIS_URL=redis://127.0.0.1:14000 \
-e REDISCONNECT_METRICS_REDIS_URL=redis://127.0.0.1:14001 \
-e REDISCONNECT_JAVA_OPTIONS="-Xms256m -Xmx256m -Doracle.net.disableOob=true" \
-v $(pwd)/config:/opt/redislabs/redis-connect-oracle/config \
-v $(pwd)/extlib:/opt/redislabs/redis-connect-oracle/extlib \
--net host \
redislabs/redis-connect-oracle:latest stage
```

</p>
</details>

<details><summary>Expected output:</summary>
<p>

```bash
-------------------------------
-------------------------------
Staging Redis Connect redis-connect-oracle v0.6.1.1 job using Java 11.0.13 on virag-cdc started by root in /opt/redislabs/redis-connect-oracle/bin
Loading Redis Connect redis-connect-oracle Configurations from /opt/redislabs/redis-connect-oracle/config/samples/oracle
01:36:12,511 |-INFO in ch.qos.logback.classic.LoggerContext[default] - Found resource [/opt/redislabs/redis-connect-oracle/config/logback.xml] at [file:/opt/redislabs/redis-connect-oracle/config/logback.xml]
....
01:36:12.769 [main] INFO  startup - ##################################################################
01:36:12.772 [main] INFO  startup -
01:36:12.772 [main] INFO  startup - REDIS CONNECT SETUP CLEAN - Deletes metadata related to Redis Connect from Job Management Database

01:36:12.772 [main] INFO  startup -
01:36:12.772 [main] INFO  startup - ##################################################################
01:36:13.490 [main] INFO  startup - Instance: 30@virag-cdc will attempt to delete (clean) all the metadata related to Redis Connect
01:36:14.235 [main] INFO  startup - Instance: 30@virag-cdc successfully established Redis connection for INIT service
01:36:14.251 [main] INFO  startup - Instance: 30@virag-cdc successfully completed flush (clean) of all the metadata related to Redis Connect
....
01:36:15.179 [main] INFO  startup - ##################################################################
01:36:15.181 [main] INFO  startup -
01:36:15.181 [main] INFO  startup - REDIS CONNECT SETUP CREATE - Seed metadata related to Redis Connect to Job Management Database
01:36:15.182 [main] INFO  startup -
01:36:15.182 [main] INFO  startup - ##################################################################
01:36:15.911 [main] INFO  startup - Instance: 94@virag-cdc will attempt Job Management Database (Redis) with all the configurations and scripts, if applicable, needed to execute jobs
01:36:16.653 [main] INFO  startup - Instance: 94@virag-cdc successfully established Redis connection for INIT service
01:36:16.656 [main] INFO  startup - Instance: 94@virag-cdc successfully created Job Claim Assignment Stream and Consumer Group
01:36:16.669 [main] INFO  startup - Instance: 94@virag-cdc successfully seeded Job related metadata
01:36:16.834 [main] INFO  startup - Instance: 94@virag-cdc successfully seeded Metrics related metadata
01:36:16.834 [main] INFO  startup - Instance: 94@virag-cdc successfully staged Job Management Database (Redis) with all the configurations and scripts, if applicable, needed to execute jobs
-------------------------------
```

</p>
</details>

<details><summary><b>Start pre-configured cdc job</b></summary>
<p>

Please update the Oracle database port according to your setup e.g. In this demo setup port `1521` is used with Oracle `12c` and port `1522` is used with Oracle `19c`.
```bash
docker run \
-it --rm --privileged=true \
--name redis-connect-oracle \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-oracle/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-oracle/config/samples/oracle \
-e REDISCONNECT_SOURCE_HOST=127.0.0.1 \
-e REDISCONNECT_SOURCE_PORT=1521 \
-e REDISCONNECT_PDBNAME=ORCLPDB1 \
-e REDISCONNECT_CDBNAME=ORCLCDB \
-e REDISCONNECT_SOURCE_URL=jdbc:oracle:thin:@127.0.0.1:1521/ORCLCDB?oracle.net.disableOob=true \
-e REDISCONNECT_SOURCE_USERNAME=c##rcuser \
-e REDISCONNECT_SOURCE_PASSWORD=rcpwd \
-e REDISCONNECT_SOURCE_METADATA_URL=jdbc:oracle:thin:@127.0.0.1:1521/ORCLPDB1?oracle.net.disableOob=true \
-e REDISCONNECT_SOURCE_METADATA_USERNAME=hr \
-e REDISCONNECT_SOURCE_METADATA_PASSWORD=hr \
-e REDISCONNECT_JOBCONFIG_REDIS_URL=redis://127.0.0.1:14001 \
-e REDISCONNECT_TARGET_REDIS_URL=redis://127.0.0.1:14000 \
-e REDISCONNECT_METRICS_REDIS_URL=redis://127.0.0.1:14001 \
-e REDISCONNECT_JAVA_OPTIONS="-Xms256m -Xmx256m -Doracle.net.disableOob=true" \
-v $(pwd)/config:/opt/redislabs/redis-connect-oracle/config \
-v $(pwd)/extlib:/opt/redislabs/redis-connect-oracle/extlib \
--net host \
redislabs/redis-connect-oracle:latest start
```

</p>
</details>

<details><summary>Expected output:</summary>
<p>

```bash
-------------------------------
Starting Redis Connect redis-connect-oracle v0.6.1.1 instance using Java 11.0.13 on virag-cdc started by root in /opt/redislabs/redis-connect-oracle/bin
Loading Redis Connect redis-connect-oracle Configurations from /opt/redislabs/redis-connect-oracle/config/samples/oracle
01:45:09,344 |-INFO in ch.qos.logback.classic.LoggerContext[default] - Found resource [/opt/redislabs/redis-connect-oracle/config/logback.xml] at [file:/opt/redislabs/redis-connect-oracle/config/logback.xml]
....
01:45:09.653 [main] INFO  startup -
01:45:09.657 [main] INFO  startup -  /$$$$$$$                  /$$ /$$                  /$$$$$$                                                      /$$
01:45:09.657 [main] INFO  startup - | $$__  $$                | $$|__/                 /$$__  $$                                                    | $$
01:45:09.657 [main] INFO  startup - | $$  \ $$  /$$$$$$   /$$$$$$$ /$$  /$$$$$$$      | $$  \__/  /$$$$$$  /$$$$$$$  /$$$$$$$   /$$$$$$   /$$$$$$$ /$$$$$$
01:45:09.658 [main] INFO  startup - | $$$$$$$/ /$$__  $$ /$$__  $$| $$ /$$_____/      | $$       /$$__  $$| $$__  $$| $$__  $$ /$$__  $$ /$$_____/|_  $$_/
01:45:09.658 [main] INFO  startup - | $$__  $$| $$$$$$$$| $$  | $$| $$|  $$$$$$       | $$      | $$  \ $$| $$  \ $$| $$  \ $$| $$$$$$$$| $$        | $$
01:45:09.658 [main] INFO  startup - | $$  \ $$| $$_____/| $$  | $$| $$ \____  $$      | $$    $$| $$  | $$| $$  | $$| $$  | $$| $$_____/| $$        | $$ /$$
01:45:09.658 [main] INFO  startup - | $$  | $$|  $$$$$$$|  $$$$$$$| $$ /$$$$$$$/      |  $$$$$$/|  $$$$$$/| $$  | $$| $$  | $$|  $$$$$$$|  $$$$$$$  |  $$$$/
01:45:09.658 [main] INFO  startup - |__/  |__/ \_______/ \_______/|__/|_______/        \______/  \______/ |__/  |__/|__/  |__/ \_______/ \_______/   \___/
01:45:09.658 [main] INFO  startup -
01:45:09.659 [main] INFO  startup - ##################################################################
01:45:09.659 [main] INFO  startup -
01:45:09.659 [main] INFO  startup - Initializing Redis Connect Instance
01:45:09.659 [main] INFO  startup -
01:45:09.659 [main] INFO  startup - ##################################################################
....
01:45:26.352 [JobManager-1] INFO  startup - Instance: 29@virag-cdc successfully established Redis connection for HeartbeatManager service
01:45:26.353 [JobManager-1] INFO  startup - Instance: 29@virag-cdc was successfully elected Redis Connect cluster leader
01:45:36.422 [JobManager-1] INFO  startup - Getting instance of EventHandler for : REDIS_HASH_WRITER
01:45:36.447 [JobManager-1] INFO  startup - Instance: 29@virag-cdc successfully established Redis connection for RedisConnectorEventHandler service
01:45:36.451 [JobManager-1] INFO  startup - Getting instance of EventHandler for : REDIS_HASH_CHECKPOINT_WRITER
01:45:36.451 [JobManager-1] WARN  startup - metricsKey not set - Metrics collection will be disabled
01:45:36.461 [JobManager-1] INFO  startup - Instance: 29@virag-cdc successfully established Redis connection for RedisCheckpointReader service
01:45:37.025 [JobManager-1] INFO  redisconnect - Reading Mapper Config from : /opt/redislabs/redis-connect-oracle/config/samples/oracle/mappers
01:45:37.041 [JobManager-1] INFO  redisconnect - Loaded Config for : HR.EMPLOYEES
01:45:37.041 [JobManager-1] INFO  redisconnect - Loaded Config for : HR.JOBS
01:45:37.369 [JobManager-1] INFO  i.d.connector.common.BaseSourceTask - Starting OracleConnectorTask with configuration:
....
01:45:37.598 [JobManager-1] INFO  startup - Instance: 29@virag-cdc successfully started job execution for JobId: {connect}:job:RedisConnect-Oracle
01:45:37.599 [JobManager-1] INFO  startup - Instance: 29@virag-cdc has successfully claimed ownership of JobId: {connect}:job:RedisConnect-Oracle
01:45:37.599 [JobManager-1] INFO  startup - Instance: 29@virag-cdc has claimed 1 job(s) from its 2 max allowable capacity
....
01:45:39.712 [debezium-oracleconnector-RedisConnect-change-event-source-coordinator] INFO  i.d.p.s.AbstractSnapshotChangeEventSource - Snapshot - Final stage
01:45:39.715 [debezium-oracleconnector-RedisConnect-change-event-source-coordinator] INFO  i.d.p.ChangeEventSourceCoordinator - Snapshot ended with SnapshotResult [status=COMPLETED, offset=OracleOffsetContext [scn=7469456]]
01:45:39.718 [debezium-oracleconnector-RedisConnect-change-event-source-coordinator] INFO  i.d.p.m.StreamingChangeEventSourceMetrics - Connected metrics set to 'true'
01:45:39.719 [debezium-oracleconnector-RedisConnect-change-event-source-coordinator] INFO  i.d.p.ChangeEventSourceCoordinator - Starting streaming
```

</p>
</details>

<details><summary><b>INSERT few records in the Oracle HR.EMPLOYEES table (source)</b>

Insert data using [insert sql scripts](load_sql.sh):
<p>

* 12c
```bash
docker exec -it oracle-12.2.0.1-ee-$(hostname) bash -c "/tmp/load_sql.sh insert1k"
```
* 19c
```bash
docker exec -it oracle-19.3.0-ee-$(hostname) bash -c "/tmp/load_sql.sh insert1k"
```
</p>
</summary>
</details>

<details><summary><b>Query for the above inserted record in Redis (target)</b></summary>
</details>

Similarly `UPDATE` and `DELETE` records on Oracle source and see Redis target getting updated in near real-time.

<details><summary><b>12c</b></summary>

```bash
docker exec -it oracle-12.2.0.1-ee-$(hostname) bash -c "/tmp/load_sql.sh update"

docker exec -it oracle-12.2.0.1-ee-$(hostname) bash -c "/tmp/load_sql.sh delete"
```

</details>

<details><summary><b>19c</b></summary>

```bash
docker exec -it oracle-19.3.0-ee-$(hostname) bash -c "/tmp/load_sql.sh update"

docker exec -it oracle-19.3.0-ee-$(hostname) bash -c "/tmp/load_sql.sh delete"
```

</details>

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
--name redis-connect-oracle \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-oracle/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-oracle/config/samples/loader \
-e REDISCONNECT_PDBNAME=ORCLPDB1 \
-e REDISCONNECT_SOURCE_URL=jdbc:oracle:thin:@127.0.0.1:1521/ORCLPDB1?oracle.net.disableOob=true \
-e REDISCONNECT_SOURCE_HOST=127.0.0.1 \
-e REDISCONNECT_SOURCE_PORT=1521 \
-e REDISCONNECT_SOURCE_USERNAME=hr \
-e REDISCONNECT_SOURCE_PASSWORD=hr \
-e REDISCONNECT_JOBCONFIG_REDIS_URL=redis://127.0.0.1:14001 \
-e REDISCONNECT_TARGET_REDIS_URL=redis://127.0.0.1:14000 \
-e REDISCONNECT_METRICS_REDIS_URL=redis://127.0.0.1:14001 \
-e REDISCONNECT_JAVA_OPTIONS="-Xms256m -Xmx256m -Doracle.net.disableOob=true" \
-v $(pwd)/config:/opt/redislabs/redis-connect-oracle/config \
-v $(pwd)/extlib:/opt/redislabs/redis-connect-oracle/extlib \
--net host \
redislabs/redis-connect-oracle:latest stage
```

</p>
</details>

<details><summary><b>Start pre-configured loader job with Custom Stage</b></summary>
<p>

```bash
docker run \
-it --rm --privileged=true \
--name redis-connect-oracle \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-oracle/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-oracle/config/samples/loader \
-e REDISCONNECT_PDBNAME=ORCLPDB1 \
-e REDISCONNECT_SOURCE_URL=jdbc:oracle:thin:@127.0.0.1:1521/ORCLPDB1?oracle.net.disableOob=true \
-e REDISCONNECT_SOURCE_HOST=127.0.0.1 \
-e REDISCONNECT_SOURCE_PORT=1521 \
-e REDISCONNECT_SOURCE_USERNAME=hr \
-e REDISCONNECT_SOURCE_PASSWORD=hr \
-e REDISCONNECT_JOBCONFIG_REDIS_URL=redis://127.0.0.1:14001 \
-e REDISCONNECT_TARGET_REDIS_URL=redis://127.0.0.1:14000 \
-e REDISCONNECT_METRICS_REDIS_URL=redis://127.0.0.1:14001 \
-e REDISCONNECT_JAVA_OPTIONS="-Xms256m -Xmx256m -Doracle.net.disableOob=true" \
-v $(pwd)/config:/opt/redislabs/redis-connect-oracle/config \
-v $(pwd)/extlib:/opt/redislabs/redis-connect-oracle/extlib \
--net host \
redislabs/redis-connect-oracle:latest start
```

</p>
</details>

Validate the output after CustomStage run and make sure that `fname` and `lname` values in Redis has been updated to UPPER CASE.
