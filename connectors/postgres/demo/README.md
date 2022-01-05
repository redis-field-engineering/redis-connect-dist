# Prerequisites
Docker compatible [*nix OS](https://en.wikipedia.org/wiki/Unix-like) and [Docker](https://docs.docker.com/get-docker) installed.
<br>Please have 8 vCPU*, 8GB RAM and 50GB storage for this demo to function properly. Adjust the resources based on your requirements. For HA, at least have 2 Redis Connect Connector instances deployed on separate hosts.</br>
<br>Execute the following commands (copy & paste) to download and setup Redis Connect Postgres Connector and demo scripts.
i.e.</br>

```bash
wget -c https://github.com/redis-field-engineering/redis-connect-dist/archive/main.zip && \
mkdir -p redis-connect-postgres/demo && \
mkdir -p redis-connect-postgres/k8s-docs && \
unzip main.zip "redis-connect-dist-main/connectors/postgres/*" -d redis-connect-postgres && \
cp -R redis-connect-postgres/redis-connect-dist-main/connectors/postgres/demo/* redis-connect-postgres/demo && \
cp -R redis-connect-postgres/redis-connect-dist-main/connectors/postgres/k8s-docs/* redis-connect-postgres/k8s-docs && \
rm -rf main.zip redis-connect-postgres/redis-connect-dist-main && \
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

demo$ docker exec -it postgres-12.5-$(hostname) bash -c 'psql -U"redisconnect" -d"RedisConnect" -c "select count(*) from emp;"'
 count
-------
     0
(1 row)  
```
</p>
</details>

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
-v $(pwd)/config:/opt/redislabs/redis-connect-postgres/config \
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

-------------------------------

### Initial Loader Steps
<details><summary><b>INSERT few records into postgres table (source)</b></summary>
<p>

```bash
demo$ sudo docker exec -it postgres-12.5-$(hostname) bash -c 'psql -U"redisconnect" -d"RedisConnect"'

psql (12.5 (Debian 12.5-1.pgdg100+1))
Type "help" for help.

RedisConnect=# INSERT INTO public.emp (empno, fname, lname, job, mgr, hiredate, sal, comm, dept) VALUES (151, 'Virag', 'Tripathi', 'PFE', 1, '2018-08-06', 2000, 10, 1);
INSERT 0 1

RedisConnect=# INSERT INTO public.emp (empno, fname, lname, job, mgr, hiredate, sal, comm, dept) VALUES (152, 'Brad', 'Barnes', 'RedisConnect-K8s-SME', 1, '2018-08-06', 20000, 10, 1);
INSERT 0 1

RedisConnect=# select * from emp;
 empno | fname |  lname   |         job          | mgr |  hiredate  |    sal     |  comm   | dept
-------+-------+----------+----------------------+-----+------------+------------+---------+------
   151 | Virag | Tripathi | PFE                  |   1 | 2018-08-06 |  2000.0000 | 10.0000 |    1
   152 | Brad  | Barnes   | RedisConnect-K8s-SME |   1 | 2018-08-06 | 20000.0000 | 10.0000 |    1
(2 rows)
```

</p>
</details>

<details><summary><b>Stage pre configured loader job</b></summary>
<p>

```bash
docker run \
-it --rm --privileged=true \
--name redis-connect-postgres \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-postgres/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-postgres/config/samples/loader \
-e REDISCONNECT_SOURCE_USERNAME=redisconnect \
-e REDISCONNECT_SOURCE_PASSWORD=Redis@123 \
-e REDISCONNECT_JAVA_OPTIONS="-Xms256m -Xmx256m" \
-v $(pwd)/config:/opt/redislabs/redis-connect-postgres/config \
--net host \
redislabs/redis-connect-postgres:pre-release-alpine stage
```

</p>
</details>

<details><summary>Expected output:</summary>
<p>

```bash
-------------------------------
Staging Redis Connect redis-connect-postgres v1.0.2.151 job using Java 11.0.12 on 16229e5715a1 started by root in /opt/redislabs/redis-connect-postgres/bin
Loading Redis Connect redis-connect-postgres Configurations from /opt/redislabs/redis-connect-postgres/config/samples/loader
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
--name redis-connect-postgres \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-postgres/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-postgres/config/samples/loader \
-e REDISCONNECT_REST_API_ENABLED=false \
-e REDISCONNECT_REST_API_PORT=8282 \
-e REDISCONNECT_SOURCE_USERNAME=redisconnect \
-e REDISCONNECT_SOURCE_PASSWORD=Redis@123 \
-e REDISCONNECT_JAVA_OPTIONS="-Xms256m -Xmx1g" \
-v $(pwd)/config:/opt/redislabs/redis-connect-postgres/config \
--net host \
redislabs/redis-connect-postgres:pre-release-alpine start
```

</p>
</details>

<details><summary>Expected output:</summary>
<p>

```bash
-------------------------------
Starting Redis Connect redis-connect-postgres v1.0.2.151 instance using Java 11.0.12 on 5aa3dc7a4ead started by root in /opt/redislabs/redis-connect-postgres/bin
Loading Redis Connect redis-connect-postgres Configurations from /opt/redislabs/redis-connect-postgres/config/samples/loader
.....
.....
12:31:49.698 [main] INFO  startup -  /$$$$$$$                  /$$ /$$                  /$$$$$$                                                      /$$
12:31:49.708 [main] INFO  startup - | $$__  $$                | $$|__/                 /$$__  $$                                                    | $$
12:31:49.714 [main] INFO  startup - | $$  \ $$  /$$$$$$   /$$$$$$$ /$$  /$$$$$$$      | $$  \__/  /$$$$$$  /$$$$$$$  /$$$$$$$   /$$$$$$   /$$$$$$$ /$$$$$$
12:31:49.715 [main] INFO  startup - | $$$$$$$/ /$$__  $$ /$$__  $$| $$ /$$_____/      | $$       /$$__  $$| $$__  $$| $$__  $$ /$$__  $$ /$$_____/|_  $$_/
12:31:49.719 [main] INFO  startup - | $$__  $$| $$$$$$$$| $$  | $$| $$|  $$$$$$       | $$      | $$  \ $$| $$  \ $$| $$  \ $$| $$$$$$$$| $$        | $$
12:31:49.720 [main] INFO  startup - | $$  \ $$| $$_____/| $$  | $$| $$ \____  $$      | $$    $$| $$  | $$| $$  | $$| $$  | $$| $$_____/| $$        | $$ /$$
12:31:49.722 [main] INFO  startup - | $$  | $$|  $$$$$$$|  $$$$$$$| $$ /$$$$$$$/      |  $$$$$$/|  $$$$$$/| $$  | $$| $$  | $$|  $$$$$$$|  $$$$$$$  |  $$$$/
12:31:49.723 [main] INFO  startup - |__/  |__/ \_______/ \_______/|__/|_______/        \______/  \______/ |__/  |__/|__/  |__/ \_______/ \_______/   \___/
12:31:49.724 [main] INFO  startup -
12:31:49.725 [main] INFO  startup -
12:31:49.726 [main] INFO  startup - ##################################################################
12:31:49.727 [main] INFO  startup -
12:31:49.728 [main] INFO  startup - Initializing Redis Connect Instance
12:31:49.728 [main] INFO  startup -
12:31:49.729 [main] INFO  startup - ##################################################################
.....
.....
12:32:07.007 [JobManagement-1] INFO  startup - Job Manager owned by a different process ? : false : jobType1
12:32:17.600 [JobManagement-1] INFO  startup - Fetched JobConfig for : batchtaskcreator
12:32:17.601 [JobManagement-1] INFO  startup - Starting Pipeline for Job : batchtaskcreator
12:32:17.602 [JobManagement-1] INFO  startup - 1 of 5 Jobs Claimed
12:32:17.602 [JobManagement-2] INFO  redisconnect - Refreshing Heartbeat signal for : hb-job:batchtaskcreator , with value : JC-32@5aa3dc7a4ead , expiry : 30000
12:32:17.603 [JobManagement-1] INFO  startup - 1 of 5 Jobs Claimed
.....
.....  
```

</p>
</details>

<details><summary><b>Query for the above inserted record in Redis (target)</b></summary>
<p>

```bash
demo$ sudo docker exec -it re-node1 bash -c 'redis-cli -p 12000 ft.search idx:emp "*"'
1) (integer) 2
2) "emp:152"
3)  1) "Salary"
    2) "20000.0000"
    3) "Department"
    4) "1"
    5) "fname"
    6) "Brad"
    7) "Commission"
    8) "10.0000"
    9) "HireDate"
   10) "2018-08-06"
   11) "empno"
   12) "152"
   13) "lname"
   14) "Barnes"
   15) "Job"
   16) "RedisConnect-K8s-SME"
   17) "Manager"
   18) "1"
4) "emp:151"
5)  1) "Salary"
    2) "2000.0000"
    3) "Department"
    4) "1"
    5) "fname"
    6) "Virag"
    7) "Commission"
    8) "10.0000"
    9) "HireDate"
   10) "2018-08-06"
   11) "empno"
   12) "151"
   13) "lname"
   14) "Tripathi"
   15) "Job"
   16) "PFE"
   17) "Manager"
   18) "1"
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
--name redis-connect-postgres \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-postgres/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-postgres/config/samples/postgres \
-e REDISCONNECT_SOURCE_USERNAME=redisconnect \
-e REDISCONNECT_SOURCE_PASSWORD=Redis@123 \
-e REDISCONNECT_JAVA_OPTIONS="-Xms256m -Xmx256m" \
-v $(pwd)/config:/opt/redislabs/redis-connect-postgres/config \
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
-v $(pwd)/config:/opt/redislabs/redis-connect-postgres/config \
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
demo$ sudo docker exec -it postgres-12.5-$(hostname) bash -c 'psql -U"redisconnect" -d"RedisConnect"'

psql (12.5 (Debian 12.5-1.pgdg100+1))
Type "help" for help.

RedisConnect=# INSERT INTO public.emp (empno, fname, lname, job, mgr, hiredate, sal, comm, dept) VALUES (1, 'Virag', 'Tripathi', 'PFE', 1, '2018-08-06', 2000, 10, 1);
INSERT 0 1

RedisConnect=# select * from emp;
 empno | fname |  lname   | job | mgr |  hiredate  |    sal    |  comm   | dept
-------+-------+----------+-----+-----+------------+-----------+---------+------
   1 | Virag | Tripathi | PFE |   1 | 2018-08-06 | 2000.0000 | 10.0000 |    1
(1 row)
```

</p>
</details>

<details><summary><b>Query for the above inserted record in Redis (target)</b></summary>
<p>

```bash
demo$ sudo docker exec -it re-node1 bash -c 'redis-cli -p 12000 ft.search idx:emp "*"'
1) (integer) 3
2) "emp:152"
3)  1) "fname"
    2) "BRAD"
    3) "Salary"
    4) "20000.0000"
    5) "lname"
    6) "BARNES"
    7) "Department"
    8) "1"
    9) "EmployeeNumber"
   10) "152"
   11) "Commission"
   12) "10.0000"
   13) "HireDate"
   14) "2018-08-06"
   15) "Job"
   16) "RedisConnect-K8s-SME"
   17) "Manager"
   18) "1"
4) "emp:151"
5)  1) "fname"
    2) "Virag"
    3) "Salary"
    4) "2000.0000"
    5) "lname"
    6) "Tripathi"
    7) "Department"
    8) "1"
    9) "EmployeeNumber"
   10) "151"
   11) "Commission"
   12) "10.0000"
   13) "HireDate"
   14) "2018-08-06"
   15) "Job"
   16) "PFE"
   17) "Manager"
   18) "1"
6) "emp:1"
7)  1) "fname"
    2) "Virag"
    3) "Salary"
    4) "2000.0"
    5) "lname"
    6) "Tripathi"
    7) "Department"
    8) "1"
    9) "EmployeeNumber"
   10) "1"
   11) "Commission"
   12) "10.0"
   13) "HireDate"
   14) "17749"
   15) "Job"
   16) "PFE"
   17) "Manager"
   18) "1"
```

</p>
</details>

Similarly `UPDATE` and `DELETE` records on Postgres source and see Redis target getting updated in near real-time.

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
--name redis-connect-postgres \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-postgres/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-postgres/config/samples/loader \
-e REDISCONNECT_SOURCE_USERNAME=redisconnect \
-e REDISCONNECT_SOURCE_PASSWORD=Redis@123 \
-e REDISCONNECT_JAVA_OPTIONS="-Xms256m -Xmx256m" \
-v $(pwd)/config:/opt/redislabs/redis-connect-postgres/config \
-v $(pwd)/extlib:/opt/redislabs/redis-connect-postgres/extlib \
--net host \
redislabs/redis-connect-postgres:pre-release-alpine stage
```

</p>
</details>

<details><summary><b>Start pre configured loader job with Custom Stage</b></summary>
<p>

```bash
docker run \
-it --rm --privileged=true \
--name redis-connect-postgres \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-postgres/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-postgres/config/samples/loader \
-e REDISCONNECT_REST_API_ENABLED=false \
-e REDISCONNECT_REST_API_PORT=8282 \
-e REDISCONNECT_SOURCE_USERNAME=redisconnect \
-e REDISCONNECT_SOURCE_PASSWORD=Redis@123 \
-e REDISCONNECT_JAVA_OPTIONS="-Xms256m -Xmx1g" \
-v $(pwd)/config:/opt/redislabs/redis-connect-postgres/config \
-v $(pwd)/extlib:/opt/redislabs/redis-connect-postgres/extlib \
--net host \
redislabs/redis-connect-postgres:pre-release-alpine start
```

</p>
</details>

Validate the output after CustomStage run and make sure that `fname` and `lname` values in Redis has been updated to UPPER CASE.
