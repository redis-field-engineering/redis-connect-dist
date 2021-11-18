# Prerequisites

* Docker compatible [*nix OS](https://en.wikipedia.org/wiki/Unix-like) and [Docker](https://docs.docker.com/get-docker) installed.
* Please have 8 vCPU*, 8GB RAM and 50GB storage for this demo to function properly. Adjust the resources based on your requirements. For HA, at least have 2 Redis Connect Connector instances deployed on separate hosts.
* [Oracle JDBC Driver](https://www.oracle.com/database/technologies/appdev/jdbc-downloads.html) (`ojdbc8.jar`)

| :exclamation: IMPORTANT       |
| :-----------------------------|
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
_**Oracle 19c:**_ Currently redis-connect-oracle does not support CDC with 19c but works with Initial load.

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

demo$ docker exec -it oracle-12.2.0.1-ee-virag-cdc bash -c "sqlplus sys/Redis123@ORCLPDB1 as sysdba"

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
1) "idx:emp"
```
</p>
</details>

---

| :memo:        |
|---------------|

The above script will create a 1-node Redis Enterprise cluster in a docker container, [Create a target database with RediSearch module](https://docs.redislabs.com/latest/modules/add-module-to-database/), [Create a job management and metrics database with RedisTimeSeries module](https://docs.redislabs.com/latest/modules/add-module-to-database/), [Create a RediSearch index for emp Hash](https://redislabs.com/blog/getting-started-with-redisearch-2-0/) and [Start an instance of RedisInsight](https://docs.redislabs.com/latest/ri/installing/install-docker/).

---

## Start Redis Connect Oracle Connector

| :point_up:    | Don't forget to download and copy the Oracle client jar into the extlib folder i.e. `demo$ cp ojdbc8.jar extlib` |
|---------------|:--------------------------|

<details><summary>Run Redis Connect Oracle Connector docker container to see all the options</summary>
<p>

```bash
docker run \
-it --rm --privileged=true \
--name redis-connect-oracle \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-oracle/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-oracle/config/samples/oracle \
-e REDISCONNECT_SOURCE_USERNAME=hr \
-e REDISCONNECT_SOURCE_PASSWORD=hr \
-e REDISCONNECT_JAVA_OPTIONS="-Xms256m -Xmx256m" \
-v $(pwd)/config:/opt/redislabs/redis-connect-oracle/config \
-v $(pwd)/extlib:/opt/redislabs/redis-connect-oracle/extlib \
--net host \
redislabs/redis-connect-oracle:pre-release-alpine
```

</p>
</details>

<details><summary>Expected output:</summary>
<p>

```bash
Unable to find image 'redislabs/redis-connect-oracle:pre-release-alpine' locally
pre-release-alpine: Pulling from redislabs/redis-connect-oracle
a0d0a0d46f8b: Already exists
44537f359f3a: Pull complete
9aaa9874ae7f: Pull complete
13f6c829139b: Pull complete
06add1107609: Pull complete
bfc29d6a129c: Pull complete
249c85a8a900: Pull complete
ffe4c573e59c: Pull complete
Digest: sha256:da7987fd874c50bc858b3ba2d3affde3e2f8506b7a3a5f7d42c6feb1bc9d8621
Status: Downloaded newer image for redislabs/redis-connect-oracle:pre-release-alpine
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

The Oracle [setup](setup_logminer.sh) already loads [Oracle's HR Sample Schema Tables](https://docs.oracle.com/en/database/oracle/oracle-database/19/comsc/HR-sample-schema-table-descriptions.html#GUID-506C25CE-FA5D-472A-9C4C-F9EF200823EE). If you like to work with another Schema or Table then please create using the existing `HR` schema e.g.
```bash
create table hr.emp(  
  empno		number(6,0),
  fname		varchar2(30),
  lname		varchar2(30),  
  job		varchar2(40),
  mgr		number(4,0),
  hiredate	date,
  sal		number(10,4),
  comm		number(10,4),
  dept		number(4,0),
  constraint pk_emp primary key (empno)
)

insert into hr.emp values (1, 'Virag', 'Tripathi', 'PFE', 1, (TO_DATE('2016-08-05 04:07:50', 'yyyy-MM-dd HH:mi:ss')), 1671.34, 1235.13, 96)
```

Load data using the crud loader:
<p>

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
--name redis-connect-oracle \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-oracle/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-oracle/config/samples/loader \
-e REDISCONNECT_SOURCE_USERNAME=hr \
-e REDISCONNECT_SOURCE_PASSWORD=hr \
-e REDISCONNECT_JAVA_OPTIONS="-Xms256m -Xmx256m" \
-v $(pwd)/config:/opt/redislabs/redis-connect-oracle/config \
-v $(pwd)/extlib:/opt/redislabs/redis-connect-oracle/extlib \
--net host \
redislabs/redis-connect-oracle:pre-release-alpine stage
```

</p>
</details>

<details><summary>Expected output:</summary>
<p>

```bash

```

</p>
</details>

<details><summary><b>Start pre configured loader job</b></summary>
<p>

```bash
docker run \
-it --rm --privileged=true \
--name redis-connect-oracle \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-oracle/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-oracle/config/samples/loader \
-e REDISCONNECT_REST_API_ENABLED=false \
-e REDISCONNECT_REST_API_PORT=8282 \
-e REDISCONNECT_SOURCE_USERNAME=hr \
-e REDISCONNECT_SOURCE_PASSWORD=hr \
-e REDISCONNECT_JAVA_OPTIONS="-Xms256m -Xmx1g" \
-v $(pwd)/config:/opt/redislabs/redis-connect-oracle/config \
-v $(pwd)/extlib:/opt/redislabs/redis-connect-oracle/extlib \
--net host \
redislabs/redis-connect-oracle:pre-release-alpine start
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
--name redis-connect-oracle \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-oracle/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-oracle/config/samples/oracle \
-e REDISCONNECT_SOURCE1_USERNAME=c##rcuser \
-e REDISCONNECT_SOURCE1_PASSWORD=rcpwd \
-e REDISCONNECT_SOURCE2_USERNAME=hr \
-e REDISCONNECT_SOURCE2_PASSWORD=hr \
-e REDISCONNECT_JAVA_OPTIONS="-Xms256m -Xmx256m" \
-v $(pwd)/config:/opt/redislabs/redis-connect-oracle/config \
-v $(pwd)/extlib:/opt/redislabs/redis-connect-oracle/extlib \
--net host \
redislabs/redis-connect-oracle:pre-release-alpine stage
```

</p>
</details>

<details><summary>Expected output:</summary>
<p>

```bash
-------------------------------
Staging Redis Connect redis-connect-oracle v0.4.0.26 job using Java 11.0.13 on docker-desktop started by root in /opt/redislabs/redis-connect-oracle/bin
Loading Redis Connect redis-connect-oracle Configurations from /opt/redislabs/redis-connect-oracle/config/samples/oracle
04:33:27,136 |-INFO in ch.qos.logback.classic.LoggerContext[default] - Found resource [/opt/redislabs/redis-connect-oracle/config/logback.xml] at [file:/opt/redislabs/redis-connect-oracle/config/logback.xml]
....
....
04:33:27.750 [main] INFO  startup - ##################################################################
04:33:27.757 [main] INFO  startup -
04:33:27.758 [main] INFO  startup - REDIS CONNECT SETUP CLEAN - Deletes metadata related to Redis Connect from Job Management Database

04:33:27.759 [main] INFO  startup -
04:33:27.760 [main] INFO  startup - ##################################################################
....
....
04:33:31.592 [main] INFO  startup - ##################################################################
04:33:31.597 [main] INFO  startup -
04:33:31.597 [main] INFO  startup - REDIS CONNECT SETUP CREATE - Seed metadata related to Redis Connect to Job Management Database
04:33:31.598 [main] INFO  startup -
04:33:31.600 [main] INFO  startup - ##################################################################
04:33:32.854 [main] INFO  startup - Instance: 57@docker-desktop will attempt Job Management Database (Redis) with all the configurations and scripts, if applicable, needed to execute jobs
04:33:34.185 [main] INFO  startup - Instance: 57@docker-desktop successfully established Redis connection for INIT service
04:33:34.220 [main] INFO  startup - Instance: 57@docker-desktop successfully created Job Claim Assignment Stream and Consumer Group
04:33:34.358 [main] INFO  startup - Instance: 57@docker-desktop successfully seeded Job related metadata
04:33:34.943 [main] INFO  startup - Instance: 57@docker-desktop successfully seeded Metrics related metadata
04:33:34.943 [main] INFO  startup - Instance: 57@docker-desktop successfully staged Job Management Database (Redis) with all the configurations and scripts, if applicable, needed to execute jobs
-------------------------------
```

</p>
</details>

<details><summary><b>Start pre configured cdc job</b></summary>
<p>

```bash
docker run \
-it --rm --privileged=true \
--name redis-connect-oracle \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-oracle/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-oracle/config/samples/oracle \
-e REDISCONNECT_REST_API_ENABLED=false \
-e REDISCONNECT_REST_API_PORT=8282 \
-e REDISCONNECT_SOURCE1_USERNAME=c##rcuser \
-e REDISCONNECT_SOURCE1_PASSWORD=rcpwd \
-e REDISCONNECT_SOURCE2_USERNAME=hr \
-e REDISCONNECT_SOURCE2_PASSWORD=hr \
-e REDISCONNECT_JAVA_OPTIONS="-Xms256m -Xmx1g" \
-v $(pwd)/config:/opt/redislabs/redis-connect-oracle/config \
-v $(pwd)/extlib:/opt/redislabs/redis-connect-oracle/extlib \
--net host \
redislabs/redis-connect-oracle:pre-release-alpine start
```

</p>
</details>

<details><summary>Expected output:</summary>
<p>

```bash
-------------------------------
Starting Redis Connect redis-connect-oracle v0.4.0.26 instance using Java 11.0.13 on docker-desktop started by root in /opt/redislabs/redis-connect-oracle/bin
Loading Redis Connect redis-connect-oracle Configurations from /opt/redislabs/redis-connect-oracle/config/samples/oracle
04:48:47,014 |-INFO in ch.qos.logback.classic.LoggerContext[default] - Found resource [/opt/redislabs/redis-connect-oracle/config/logback.xml] at [file:/opt/redislabs/redis-connect-oracle/config/logback.xml]
....
....
04:48:47.710 [main] INFO  startup -
04:48:47.730 [main] INFO  startup -  /$$$$$$$                  /$$ /$$                  /$$$$$$                                                      /$$
04:48:47.734 [main] INFO  startup - | $$__  $$                | $$|__/                 /$$__  $$                                                    | $$
04:48:47.737 [main] INFO  startup - | $$  \ $$  /$$$$$$   /$$$$$$$ /$$  /$$$$$$$      | $$  \__/  /$$$$$$  /$$$$$$$  /$$$$$$$   /$$$$$$   /$$$$$$$ /$$$$$$
04:48:47.741 [main] INFO  startup - | $$$$$$$/ /$$__  $$ /$$__  $$| $$ /$$_____/      | $$       /$$__  $$| $$__  $$| $$__  $$ /$$__  $$ /$$_____/|_  $$_/
04:48:47.742 [main] INFO  startup - | $$__  $$| $$$$$$$$| $$  | $$| $$|  $$$$$$       | $$      | $$  \ $$| $$  \ $$| $$  \ $$| $$$$$$$$| $$        | $$
04:48:47.743 [main] INFO  startup - | $$  \ $$| $$_____/| $$  | $$| $$ \____  $$      | $$    $$| $$  | $$| $$  | $$| $$  | $$| $$_____/| $$        | $$ /$$
04:48:47.745 [main] INFO  startup - | $$  | $$|  $$$$$$$|  $$$$$$$| $$ /$$$$$$$/      |  $$$$$$/|  $$$$$$/| $$  | $$| $$  | $$|  $$$$$$$|  $$$$$$$  |  $$$$/
04:48:47.750 [main] INFO  startup - |__/  |__/ \_______/ \_______/|__/|_______/        \______/  \______/ |__/  |__/|__/  |__/ \_______/ \_______/   \___/
04:48:47.751 [main] INFO  startup -
04:48:47.757 [main] INFO  startup - ##################################################################
04:48:47.757 [main] INFO  startup -
04:48:47.757 [main] INFO  startup - Initializing Redis Connect Instance
04:48:47.757 [main] INFO  startup -
04:48:47.757 [main] INFO  startup - ##################################################################
....
....
04:49:17.436 [JobManager-1] INFO  startup - Instance: 30@docker-desktop successfully established Redis connection for RedisCheckpointReader service
04:49:19.591 [JobManager-1] INFO  redisconnect - Reading Mapper Config from : /opt/redislabs/redis-connect-oracle/config/samples/oracle/mappers
04:49:19.667 [JobManager-1] INFO  redisconnect - Loaded Config for : HR.EMPLOYEES
04:49:19.669 [JobManager-1] INFO  redisconnect - Loaded Config for : HR.JOBS
04:49:19.672 [JobManager-1] INFO  redisconnect - Loaded Config for : HR.EMP
04:49:20.707 [JobManager-1] INFO  redisconnect - Commit SCN : 0
04:49:20.709 [JobManager-1] INFO  redisconnect - Log Miner will start at new position SCN : 1627357 with fetch size : 1
04:49:20.758 [JobManager-1] INFO  startup - Instance: 30@docker-desktop successfully started job execution for JobId: {connect}:job:ORACLE-HR
04:49:20.758 [EventProducer-1] INFO  redisconnect - Mining for changes .. Processing will start when mining encounters first change
04:49:20.760 [JobManager-1] INFO  startup - Instance: 30@docker-desktop has successfully claimed ownership of JobId: {connect}:job:ORACLE-HR
04:49:20.761 [JobManager-1] INFO  startup - Instance: 30@docker-desktop has claimed 1 job(s) from its 2 max allowable capacity
....
....
```

</p>
</details>

<details><summary><b>INSERT/UPDATE a record in the Oracle HR.EMPLOYEES table (source)</b></summary>
</details>

<details><summary><b>Query for the above inserted record in Redis (target)</b></summary>
</details>

Similarly `UPDATE` and `DELETE` records on Oracle source and see Redis target getting updated in near real-time.

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
--name redis-connect-oracle \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-oracle/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-oracle/config/samples/loader \
-e REDISCONNECT_SOURCE_USERNAME=hr \
-e REDISCONNECT_SOURCE_PASSWORD=hr \
-e REDISCONNECT_JAVA_OPTIONS="-Xms256m -Xmx256m" \
-v $(pwd)/config:/opt/redislabs/redis-connect-oracle/config \
-v $(pwd)/extlib:/opt/redislabs/redis-connect-oracle/extlib \
--net host \
redislabs/redis-connect-oracle:pre-release-alpine stage
```

</p>
</details>

<details><summary><b>Start pre configured loader job with Custom Stage</b></summary>
<p>

```bash
docker run \
-it --rm --privileged=true \
--name redis-connect-oracle \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-oracle/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-oracle/config/samples/loader \
-e REDISCONNECT_REST_API_ENABLED=false \
-e REDISCONNECT_REST_API_PORT=8282 \
-e REDISCONNECT_SOURCE_USERNAME=hr \
-e REDISCONNECT_SOURCE_PASSWORD=hr \
-e REDISCONNECT_JAVA_OPTIONS="-Xms256m -Xmx1g" \
-v $(pwd)/config:/opt/redislabs/redis-connect-oracle/config \
-v $(pwd)/extlib:/opt/redislabs/redis-connect-oracle/extlib \
--net host \
redislabs/redis-connect-oracle:pre-release-alpine start
```

</p>
</details>

Validate the output after CustomStage run and make sure that `fname` and `lname` values in Redis has been updated to UPPER CASE.
