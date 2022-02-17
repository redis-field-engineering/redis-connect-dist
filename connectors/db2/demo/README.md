# Prerequisites
Docker compatible [*nix OS](https://en.wikipedia.org/wiki/Unix-like) and [Docker](https://docs.docker.com/get-docker) installed.
<br>Please have 8 vCPU*, 8GB RAM and 50GB storage for this demo to function properly. Adjust the resources based on your requirements. For HA, at least have 2 Redis Connect Connector instances deployed on separate hosts.</br>
<br>Execute the following commands (copy & paste) to download and setup Redis Connect db2 Connector and demo scripts.
i.e.</br>

```bash
wget -c https://github.com/redis-field-engineering/redis-connect-dist/archive/main.zip && \
mkdir -p redis-connect-db2/demo && \
mkdir -p redis-connect-db2/k8s-docs && \
unzip main.zip "redis-connect-dist-main/connectors/db2/*" -d redis-connect-db2 && \
cp -R redis-connect-db2/redis-connect-dist-main/connectors/db2/demo/* redis-connect-db2/demo && \
cp -R redis-connect-db2/redis-connect-dist-main/connectors/db2/k8s-docs/* redis-connect-db2/k8s-docs && \
rm -rf main.zip redis-connect-db2/redis-connect-dist-main && \
cd redis-connect-db2 && \
chmod a+x demo/*.sh
```

Expected output:
```bash
redis-connect-db2$ ls
config demo
```

## Setup IBM DB2 database (Source)
<br>For this demo, an IBM DB2 LUW database has been created in the IBM cloud. You are free to use your own DB2 instance.</br>

<details><summary><b>CREATE table SQL (source)</b></summary>
<p>

```sql
CREATE TABLE EMP (
       EMPNO    int         NOT NULL,
       FNAME    VARCHAR(50) NULL,
       LNAME    VARCHAR(50) NULL,
       JOB      VARCHAR(50) NULL,
       MGR      int         NULL,
       HIREDATE date        NULL,
       SAL      double      NULL,
       COMM     double      NULL,
       DEPT     int         NULL,
       PRIMARY KEY (EMPNO)      
       )
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

## Start Redis Connect DB2 Connector

<details><summary>Run Redis Connect db2 Connector docker container to see all the options</summary>
<p>

```bash
docker run \
-it --rm --privileged=true \
--name redis-connect-db2 \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-db2/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-db2/config/samples/loader \
-e REDISCONNECT_SOURCE_USERNAME=jjd47182 \
-e REDISCONNECT_SOURCE_PASSWORD=xl+c84m9tmgg1q6v \
-e REDISCONNECT_TARGET_USERNAME="" \
-e REDISCONNECT_TARGET_PASSWORD="" \
-e REDISCONNECT_JAVA_OPTIONS="-Xms256m -Xmx256m" \
-v $(pwd)/config:/opt/redislabs/redis-connect-db2/config \
--net host \
redislabs/redis-connect-db2:latest
```

</p>
</details>

<details><summary>Expected output:</summary>
<p>
  
```bash
-------------------------------
Redis Connect startup script.
*******************************
Please ensure that the values of environment variables in /opt/redislabs/redis-connect-db2/bin/redisconnect.conf are correctly mapped before executing any of the options below
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
<details><summary><b>INSERT few records into db2 table (source)</b></summary>
<p>

```sql
INSERT INTO JJD47182.EMP (empno, fname, lname, job, mgr, hiredate, sal, comm, dept) VALUES ('1', 'Basanth', 'Gowda', 'FOUNDER', '1', '2018-08-09 00:00:00.000', '200000', '10', '1')
INSERT INTO JJD47182.EMP (empno, fname, lname, job, mgr, hiredate, sal, comm, dept) VALUES ('2', 'Virag', 'Tripathi', 'SA', '1', '2018-08-06 00:00:00.000', '2000', '10', '1')
INSERT INTO JJD47182.EMP (empno, fname, lname, job, mgr, hiredate, sal, comm, dept) VALUES ('3', 'Drake', 'Albee', 'RSM', '1', '2017-08-09 00:00:00.000', '5000', '10', '1')
INSERT INTO JJD47182.EMP (empno, fname, lname, job, mgr, hiredate, sal, comm, dept) VALUES ('4', 'Nick', 'Doyle', 'DIR', '1', '2019-07-09 00:00:00.000', '10000', '10', '1')
INSERT INTO JJD47182.EMP (empno, fname, lname, job, mgr, hiredate, sal, comm, dept) VALUES ('5', 'Allen', 'Terleto', 'FieldCTO', '1', '2017-06-09 00:00:00.000', '500000', '10', '1')
INSERT INTO JJD47182.EMP (empno, fname, lname, job, mgr, hiredate, sal, comm, dept) VALUES ('6', 'Marco', 'Mankerious', 'SA', '1', '2018-06-09 00:00:00.000', '2000', '10', '1')
INSERT INTO JJD47182.EMP (empno, fname, lname, job, mgr, hiredate, sal, comm, dept) VALUES ('7', 'Brad', 'Barnes', 'SA', '1', '2018-07-09 00:00:00.000', '2000', '10', '1')
INSERT INTO JJD47182.EMP (empno, fname, lname, job, mgr, hiredate, sal, comm, dept) VALUES ('8', 'Quinton', 'Gingras', 'SDR', '1', '2019-07-09 00:00:00.000', '200000', '10', '1')
INSERT INTO JJD47182.EMP (empno, fname, lname, job, mgr, hiredate, sal, comm, dept) VALUES ('9', 'Yuval', 'Shkedi', 'SA', '1', '2019-07-09 00:00:00.000', '200000', '10', '1')
INSERT INTO JJD47182.EMP (empno, fname, lname, job, mgr, hiredate, sal, comm, dept) VALUES ('10', 'Greg', 'Muscatello', 'RSD', '1', '2019-07-09 00:00:00.000', '500000', '10', '1')
```

</p>
</details>

<details><summary><b>Stage pre configured loader job</b></summary>
<p>

```bash
docker run \
-it --rm --privileged=true \
--name redis-connect-db2 \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-db2/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-db2/config/samples/loader \
-e REDISCONNECT_SOURCE_USERNAME=jjd47182 \
-e REDISCONNECT_SOURCE_PASSWORD=xl+c84m9tmgg1q6v \
-e REDISCONNECT_TARGET_USERNAME="" \
-e REDISCONNECT_TARGET_PASSWORD="" \
-e REDISCONNECT_JAVA_OPTIONS="-Xms256m -Xmx256m" \
-v $(pwd)/config:/opt/redislabs/redis-connect-db2/config \
--net host \
redislabs/redis-connect-db2:latest stage
```

</p>
</details>

<details><summary>Expected output:</summary>
<p>

```bash
-------------------------------
Staging Redis Connect redis-connect-db2 v1.0.2.11 job using Java 11.0.12 on virag-cdc started by root in /opt/redislabs/redis-connect-db2/bin
Loading Redis Connect redis-connect-db2 Configurations from /opt/redislabs/redis-connect-db2/config/samples/loader
.....
.....
19:55:15.314 [main] INFO  startup - Setup Completed.
-------------------------------
```

</p>
</details>

<details><summary><b>Start pre configured loader job</b></summary>
<p>

```bash
docker run \
-it --rm --privileged=true \
--name redis-connect-db2 \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-db2/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-db2/config/samples/loader \
-e REDISCONNECT_SOURCE_USERNAME=jjd47182 \
-e REDISCONNECT_SOURCE_PASSWORD=xl+c84m9tmgg1q6v \
-e REDISCONNECT_TARGET_USERNAME="" \
-e REDISCONNECT_TARGET_PASSWORD="" \
-e REDISCONNECT_JAVA_OPTIONS="-Xms256m -Xmx256m" \
-v $(pwd)/config:/opt/redislabs/redis-connect-db2/config \
--net host \
redislabs/redis-connect-db2:latest start
```

</p>
</details>

<details><summary>Expected output:</summary>
<p>

```bash
-------------------------------
Starting Redis Connect redis-connect-db2 v1.0.2.11 instance using Java 11.0.12 on virag-cdc started by root in /opt/redislabs/redis-connect-db2/bin
Loading Redis Connect redis-connect-db2 Configurations from /opt/redislabs/redis-connect-db2/config/samples/loader
.....
.....
19:57:30.720 [main] INFO  startup -  /$$$$$$$                  /$$ /$$                  /$$$$$$                                                      /$$
19:57:30.723 [main] INFO  startup - | $$__  $$                | $$|__/                 /$$__  $$                                                    | $$
19:57:30.723 [main] INFO  startup - | $$  \ $$  /$$$$$$   /$$$$$$$ /$$  /$$$$$$$      | $$  \__/  /$$$$$$  /$$$$$$$  /$$$$$$$   /$$$$$$   /$$$$$$$ /$$$$$$
19:57:30.723 [main] INFO  startup - | $$$$$$$/ /$$__  $$ /$$__  $$| $$ /$$_____/      | $$       /$$__  $$| $$__  $$| $$__  $$ /$$__  $$ /$$_____/|_  $$_/
19:57:30.724 [main] INFO  startup - | $$__  $$| $$$$$$$$| $$  | $$| $$|  $$$$$$       | $$      | $$  \ $$| $$  \ $$| $$  \ $$| $$$$$$$$| $$        | $$
19:57:30.724 [main] INFO  startup - | $$  \ $$| $$_____/| $$  | $$| $$ \____  $$      | $$    $$| $$  | $$| $$  | $$| $$  | $$| $$_____/| $$        | $$ /$$
19:57:30.724 [main] INFO  startup - | $$  | $$|  $$$$$$$|  $$$$$$$| $$ /$$$$$$$/      |  $$$$$$/|  $$$$$$/| $$  | $$| $$  | $$|  $$$$$$$|  $$$$$$$  |  $$$$/
19:57:30.724 [main] INFO  startup - |__/  |__/ \_______/ \_______/|__/|_______/        \______/  \______/ |__/  |__/|__/  |__/ \_______/ \_______/   \___/
19:57:30.724 [main] INFO  startup -
19:57:30.725 [main] INFO  startup -
19:57:30.725 [main] INFO  startup - ##################################################################
19:57:30.725 [main] INFO  startup -
19:57:30.725 [main] INFO  startup - Initializing Redis Connect Instance
19:57:30.725 [main] INFO  startup -
19:57:30.725 [main] INFO  startup - ##################################################################
.....
.....
19:57:46.800 [JobManagement-1] INFO  startup - Job Manager owned by a different process ? : false : empLoader
19:57:46.801 [JobManagement-2] INFO  redisconnect - Refreshing Heartbeat signal for : hb-loaderJobManager , with value : empLoader-JM-30@virag-cdc , expiry : 30000
19:57:57.986 [JobManagement-1] INFO  startup - Fetched JobConfig for : batchtaskcreator
19:57:57.986 [JobManagement-1] INFO  startup - Starting Pipeline for Job : batchtaskcreator
19:57:57.986 [JobManagement-1] INFO  startup - 1 of 5 Jobs Claimed
19:57:57.986 [JobManagement-1] INFO  startup - 1 of 5 Jobs Claimed
.....
.....  
```

</p>
</details>

<details><summary><b>Query for the above inserted record in Redis (target)</b></summary>
<p>

```bash
demo$ sudo docker exec -it re-node1 bash -c 'redis-cli -p 12000 ft.search idx:emp "*"'
 1) (integer) 10
 2) "emp:9"
 3)  1) "COMM"
     2) "10.0"
     3) "FirstName"
     4) "Yuval"
     5) "HIREDATE"
     6) "2019-07-09"
     7) "EmployeeNumber"
     8) "9"
     9) "MGR"
    10) "1"
    11) "DEPT"
    12) "1"
    13) "LastName"
    14) "Shkedi"
    15) "JOB"
    16) "SA"
    17) "SAL"
    18) "200000.0"
 4) "emp:8"
 5)  1) "COMM"
     2) "10.0"
     3) "FirstName"
     4) "Quinton"
     5) "HIREDATE"
     6) "2019-07-09"
     7) "EmployeeNumber"
     8) "8"
     9) "MGR"
    10) "1"
    11) "DEPT"
    12) "1"
    13) "LastName"
    14) "Gingras"
    15) "JOB"
    16) "SDR"
    17) "SAL"
    18) "200000.0"
 6) "emp:7"
 7)  1) "COMM"
     2) "10.0"
     3) "FirstName"
     4) "Brad"
     5) "HIREDATE"
     6) "2018-07-09"
     7) "EmployeeNumber"
     8) "7"
     9) "MGR"
    10) "1"
    11) "DEPT"
    12) "1"
    13) "LastName"
    14) "Barnes"
    15) "JOB"
    16) "SA"
    17) "SAL"
    18) "2000.0"
 8) "emp:6"
 9)  1) "COMM"
     2) "10.0"
     3) "FirstName"
     4) "Marco"
     5) "HIREDATE"
     6) "2018-06-09"
     7) "EmployeeNumber"
     8) "6"
     9) "MGR"
    10) "1"
    11) "DEPT"
    12) "1"
    13) "LastName"
    14) "Mankerious"
    15) "JOB"
    16) "SA"
    17) "SAL"
    18) "2000.0"
10) "emp:5"
11)  1) "COMM"
     2) "10.0"
     3) "FirstName"
     4) "Allen"
     5) "HIREDATE"
     6) "2017-06-09"
     7) "EmployeeNumber"
     8) "5"
     9) "MGR"
    10) "1"
    11) "DEPT"
    12) "1"
    13) "LastName"
    14) "Terleto"
    15) "JOB"
    16) "FieldCTO"
    17) "SAL"
    18) "500000.0"
12) "emp:4"
13)  1) "COMM"
     2) "10.0"
     3) "FirstName"
     4) "Nick"
     5) "HIREDATE"
     6) "2019-07-09"
     7) "EmployeeNumber"
     8) "4"
     9) "MGR"
    10) "1"
    11) "DEPT"
    12) "1"
    13) "LastName"
    14) "Doyle"
    15) "JOB"
    16) "DIR"
    17) "SAL"
    18) "10000.0"
14) "emp:3"
15)  1) "COMM"
     2) "10.0"
     3) "FirstName"
     4) "Drake"
     5) "HIREDATE"
     6) "2017-08-09"
     7) "EmployeeNumber"
     8) "3"
     9) "MGR"
    10) "1"
    11) "DEPT"
    12) "1"
    13) "LastName"
    14) "Albee"
    15) "JOB"
    16) "RSM"
    17) "SAL"
    18) "5000.0"
16) "emp:2"
17)  1) "COMM"
     2) "10.0"
     3) "FirstName"
     4) "Virag"
     5) "HIREDATE"
     6) "2018-08-06"
     7) "EmployeeNumber"
     8) "2"
     9) "MGR"
    10) "1"
    11) "DEPT"
    12) "1"
    13) "LastName"
    14) "Tripathi"
    15) "JOB"
    16) "SA"
    17) "SAL"
    18) "2000.0"
18) "emp:10"
19)  1) "COMM"
     2) "10.0"
     3) "FirstName"
     4) "Greg"
     5) "HIREDATE"
     6) "2019-07-09"
     7) "EmployeeNumber"
     8) "10"
     9) "MGR"
    10) "1"
    11) "DEPT"
    12) "1"
    13) "LastName"
    14) "Muscatello"
    15) "JOB"
    16) "RSD"
    17) "SAL"
    18) "500000.0"
20) "emp:1"
21)  1) "COMM"
     2) "10.0"
     3) "FirstName"
     4) "Basanth"
     5) "HIREDATE"
     6) "2018-08-09"
     7) "EmployeeNumber"
     8) "1"
     9) "MGR"
    10) "1"
    11) "DEPT"
    12) "1"
    13) "LastName"
    14) "Gowda"
    15) "JOB"
    16) "FOUNDER"
    17) "SAL"
    18) "200000.0"
```

</p>
</details>

-------------------------------

### CDC Steps
Coming soon..

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
--name redis-connect-db2 \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-db2/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-db2/config/samples/loader \
-e REDISCONNECT_SOURCE_USERNAME=jjd47182 \
-e REDISCONNECT_SOURCE_PASSWORD=xl+c84m9tmgg1q6v \
-e REDISCONNECT_TARGET_USERNAME="" \
-e REDISCONNECT_TARGET_PASSWORD="" \
-e REDISCONNECT_JAVA_OPTIONS="-Xms256m -Xmx256m" \
-v $(pwd)/config:/opt/redislabs/redis-connect-db2/config \
-v $(pwd)/extlib:/opt/redislabs/redis-connect-db2/extlib \
--net host \
redislabs/redis-connect-db2:latest stage
```

</p>
</details>

<details><summary><b>Start pre configured loader job with Custom Stage</b></summary>
<p>

```bash
docker run \
-it --rm --privileged=true \
--name redis-connect-db2 \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect-db2/config/logback.xml \
-e REDISCONNECT_CONFIG=/opt/redislabs/redis-connect-db2/config/samples/loader \
-e REDISCONNECT_SOURCE_USERNAME=jjd47182 \
-e REDISCONNECT_SOURCE_PASSWORD=xl+c84m9tmgg1q6v \
-e REDISCONNECT_TARGET_USERNAME="" \
-e REDISCONNECT_TARGET_PASSWORD="" \
-e REDISCONNECT_JAVA_OPTIONS="-Xms256m -Xmx256m" \
-v $(pwd)/config:/opt/redislabs/redis-connect-db2/config \
-v $(pwd)/extlib:/opt/redislabs/redis-connect-db2/extlib \
--net host \
redislabs/redis-connect-db2:latest start
```

</p>
</details>

Validate the output after CustomStage run and make sure that `fname` and `lname` values in Redis has been updated to UPPER CASE.
