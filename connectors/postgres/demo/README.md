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

<details><summary>Validate Postgres database is running as expected:</summary>
<p>

```bash
demo$ sudo docker ps -a | grep postgres
724aea897d12        postgres:12.5                                         "docker-entrypoint.s…"   10 days ago         Up 10 days          0.0.0.0:5432->5432/tcp                                                                                                                                                                                                                                                                                          postgres-12.5-virag-cdc

demo$ docker exec -it postgres-12.5-virag-cdc bash -c 'psql -U"redisconnect" -d"RedisConnect" -c "select count(*) from emp;"'
 count
-------
     0
(1 row)  
```
</p>
</details>  
  
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

<details><summary>Run Redis Connect Postgres Connector docker container to see all the options</summary>
<p>

```bash
docker run \
-it --rm --privileged=true \
--name redis-connect-postgres \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-postgres/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-postgres/config/samples/postgres \
-e REDISCONNECT_SOURCE_USERNAME=redisconnect \
-e REDISCONNECT_SOURCE_PASSWORD=Redis@123 \
-e REDISCONNECT_JAVA_OPTIONS="-Xms256m -Xmx256m" \
-v $(pwd)/../config:/opt/redislabs/redis-connect-postgres/config \
--net host \
redislabs/redis-connect-postgres:pre-release-alpine
```

</p>
</details>

<details><summary>Expected output:</summary>
<p>
  
```bash
-------------------------------
Redis Connect startup script.
*******************************
Please ensure that the values of environment variables in /opt/redislabs/redis-connect-postgres/bin/redisconnect.conf are correctly mapped before executing any of the options below
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

<details><summary><b>Stage pre configured cdc job</b></summary>
<p>

```bash
docker run \
-it --rm --privileged=true \
--name redis-connect-postgres \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-postgres/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-postgres/config/samples/postgres \
-e REDISCONNECT_SOURCE_USERNAME=redisconnect \
-e REDISCONNECT_SOURCE_PASSWORD=Redis@123 \
-e REDISCONNECT_JAVA_OPTIONS="-Xms256m -Xmx256m" \
-v $(pwd)/../config:/opt/redislabs/redis-connect-postgres/config \
--net host \
redislabs/redis-connect-postgres:pre-release-alpine stage
```

</p>
</details>

<details><summary>Expected output:</summary>
<p>

```bash
-------------------------------
Staging Redis Connect redis-connect-postgres v1.0.2.151 job using Java 11.0.12 on virag-cdc started by root in /opt/redislabs/redis-connect-postgres/bin.
Loading Redis Connect redis-connect-postgres Configurations from /opt/redislabs/redis-connect-postgres/config/samples/postgres.
.....
.....
20:15:06.819 [main] INFO  startup - Setup Completed.
-------------------------------
```

</p>
</details>

<details><summary><b>Start pre configured cdc job</b></summary>
<p>

```bash
docker run \
-it --rm --privileged=true \
--name redis-connect-postgres \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-postgres/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-postgres/config/samples/postgres \
-e REDISCONNECT_REST_API_ENABLED=true \
-e REDISCONNECT_REST_API_PORT=8282 \
-e REDISCONNECT_SOURCE_USERNAME=redisconnect \
-e REDISCONNECT_SOURCE_PASSWORD=Redis@123 \
-e REDISCONNECT_JAVA_OPTIONS="-Xms256m -Xmx1g" \
-v $(pwd)/../config:/opt/redislabs/redis-connect-postgres/config \
--net host \
redislabs/redis-connect-postgres:pre-release-alpine start
```

</p>
</details>

<details><summary>Expected output:</summary>
<p>

```bash
-------------------------------
Starting Redis Connect redis-connect-postgres v1.0.2.151 instance using Java 11.0.12 on virag-cdc started by root in /opt/redislabs/redis-connect-postgres/bin.
Loading Redis Connect redis-connect-postgres Configurations from /opt/redislabs/redis-connect-postgres/config/samples/postgres.
.....
.....
20:15:39.125 [main] INFO  startup -  /$$$$$$$                  /$$ /$$                  /$$$$$$                                                      /$$
20:15:39.128 [main] INFO  startup - | $$__  $$                | $$|__/                 /$$__  $$                                                    | $$
20:15:39.128 [main] INFO  startup - | $$  \ $$  /$$$$$$   /$$$$$$$ /$$  /$$$$$$$      | $$  \__/  /$$$$$$  /$$$$$$$  /$$$$$$$   /$$$$$$   /$$$$$$$ /$$$$$$
20:15:39.128 [main] INFO  startup - | $$$$$$$/ /$$__  $$ /$$__  $$| $$ /$$_____/      | $$       /$$__  $$| $$__  $$| $$__  $$ /$$__  $$ /$$_____/|_  $$_/
20:15:39.128 [main] INFO  startup - | $$__  $$| $$$$$$$$| $$  | $$| $$|  $$$$$$       | $$      | $$  \ $$| $$  \ $$| $$  \ $$| $$$$$$$$| $$        | $$
20:15:39.129 [main] INFO  startup - | $$  \ $$| $$_____/| $$  | $$| $$ \____  $$      | $$    $$| $$  | $$| $$  | $$| $$  | $$| $$_____/| $$        | $$ /$$
20:15:39.129 [main] INFO  startup - | $$  | $$|  $$$$$$$|  $$$$$$$| $$ /$$$$$$$/      |  $$$$$$/|  $$$$$$/| $$  | $$| $$  | $$|  $$$$$$$|  $$$$$$$  |  $$$$/
20:15:39.129 [main] INFO  startup - |__/  |__/ \_______/ \_______/|__/|_______/        \______/  \______/ |__/  |__/|__/  |__/ \_______/ \_______/   \___/
20:15:39.129 [main] INFO  startup -
20:15:39.129 [main] INFO  startup -
20:15:39.129 [main] INFO  startup - ##################################################################
20:15:39.129 [main] INFO  startup -
20:15:39.129 [main] INFO  startup - Initializing Redis Connect Instance
20:15:39.130 [main] INFO  startup -
20:15:39.130 [main] INFO  startup - ##################################################################
.....
.....
20:15:58.678 [JobManagement-1] INFO  redisconnect - Server type configured as - postgres
20:15:58.680 [JobManagement-1] INFO  redisconnect - Reading Mapper Config from : /opt/redislabs/redis-connect-postgres/config/samples/postgres/mappers
20:15:58.975 [JobManagement-1] INFO  redisconnect - Loaded Config for : public.emp
20:15:59.293 [JobManagement-1] INFO  startup - Fetched JobConfig for : testdb-postgres
20:15:59.293 [JobManagement-1] INFO  startup - Starting Pipeline for Job : testdb-postgres
20:15:59.294 [JobManagement-1] INFO  startup - 1 of 1 Jobs Claimed
.....
.....  
```

</p>
</details>

<details><summary><b>INSERT a record into postgres table (source)</b></summary>
<p>

```bash
demo$ sudo docker exec -it postgres-12.5-virag-cdc bash -c 'psql -U"redisconnect" -d"RedisConnect"'

psql (12.5 (Debian 12.5-1.pgdg100+1))
Type "help" for help.

RedisConnect=# INSERT INTO public.emp (empno, fname, lname, job, mgr, hiredate, sal, comm, dept) VALUES (151, 'Virag', 'Tripathi', 'PFE', 1, '2018-08-06', 2000, 10, 1);
INSERT 0 1

RedisConnect=# select * from emp;
 empno | fname |  lname   | job | mgr |  hiredate  |    sal    |  comm   | dept
-------+-------+----------+-----+-----+------------+-----------+---------+------
   151 | Virag | Tripathi | PFE |   1 | 2018-08-06 | 2000.0000 | 10.0000 |    1
(1 row)
```

</p>
</details>

<details><summary><b>Query for the above inserted record in Redis (target)</b></summary>
<p>

```bash
demo$ sudo docker exec -it re-node1 bash -c "redis-cli -p 12000 hgetall emp:151"
 1) "fname"
 2) "Virag"
 3) "lname"
 4) "Tripathi"
 5) "comm"
 6) "10.0"
 7) "mgr"
 8) "1"
 9) "empno"
10) "151"
11) "dept"
12) "1"
13) "job"
14) "PFE"
15) "hiredate"
16) "17749"
17) "sal"
18) "2000.0"

demo$ sudo docker exec -it re-node1 bash -c 'redis-cli -p 12000 ft.search idx:emp "*"'
1) (integer) 1
2) "emp:151"
3)  1) "fname"
    2) "Virag"
    3) "lname"
    4) "Tripathi"
    5) "comm"
    6) "10.0"
    7) "mgr"
    8) "1"
    9) "empno"
   10) "151"
   11) "dept"
   12) "1"
   13) "job"
   14) "PFE"
   15) "hiredate"
   16) "17749"
   17) "sal"
   18) "2000.0"
```

</p>
</details>

Similarly `UPDATE` and `DELETE` records on Postgres source and see Redis target getting updated in near real-time.
