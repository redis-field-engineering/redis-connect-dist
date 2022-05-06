# Prerequisites
Docker compatible [*nix OS](https://en.wikipedia.org/wiki/Unix-like) and [Docker](https://docs.docker.com/get-docker) installed.
<br>Please have 8 vCPU*, 8GB RAM and 50GB storage for this demo to function properly. Adjust the resources based on your requirements. For HA, at least have 2 Redis Connect Connector instances deployed on separate hosts.</br>
<br>Execute the following commands (copy & paste) to download and setup Redis Connect Postgres Connector and demo scripts.
i.e.</br>

```bash
wget -c https://github.com/redis-field-engineering/redis-connect-dist/archive/main.zip && \
mkdir -p redis-connect/demo && \
mkdir -p redis-connect/k8s-docs && \
unzip main.zip "redis-connect-dist-main/examples/postgres/*" -d redis-connect && \
cp -R redis-connect/redis-connect-dist-main/examples/postgres/demo/* redis-connect/demo && \
cp -R redis-connect/redis-connect-dist-main/examples/postgres/k8s-docs/* redis-connect/k8s-docs && \
rm -rf main.zip redis-connect/redis-connect-dist-main && \
cd redis-connect && \
chmod a+x demo/*.sh
```

Expected output:
```bash
redis-connect$ ls
config demo
```

## Setup PostgreSQL 10+ database (Source)
<b>_PostgreSQL on Docker_</b>
<br>Execute [setup_postgres.sh](setup_postgres.sh)</br>
```bash
redis-connect$ cd demo
demo$ ./setup_postgres.sh 12.7 5432
(or latest or any supported 10+ version from postgres dockerhub)
```

<details><summary>Validate Postgres database is running as expected:</summary>
<p>

```bash
demo$ sudo docker ps -a | grep postgres
b5adf162d133        postgres:12.7                                "docker-entrypoint.s…"   4 hours ago         Up 4 hours              0.0.0.0:5432->5432/tcp                                                                                                                                                                                                                                                                                          postgres-12.7-virag-cdc-5432

demo$ sudo docker exec -it postgres-12.7-$(hostname)-5432 bash -c 'psql -U"redisconnect" -d"RedisConnect" -c "select count(*) from emp;"'
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

## Start Redis Connect

<details><summary>Run Redis Connect docker container to see all the options</summary>
<p>

```bash
docker run \
-it --rm --privileged=true \
--name redis-connect-$(hostname) \
-e REDISCONNECT_JOB_MANAGER_CONFIG_PATH=/opt/rediabs/redis-connect/config/jobmanager.properties \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect/config/logback.xml \
-e REDISCONNECT_JAVA_OPTIONS="-Xms1g -Xmx2g" \
-e REDISCONNECT_EXTLIB_DIR=/opt/redislabs/redis-connect/extlib \
-v $(pwd)/config:/opt/redislabs/redis-connect/config \
-v $(pwd)/config/samples/credentials:/opt/redislabs/redis-connect/config/samples/credentials \
-v $(pwd)/extlib:/opt/redislabs/redis-connect/extlib \
--net host \
redislabs/redis-connect
```

</p>
</details>

<details><summary>Expected output:</summary>
<p>
  
```bash
-------------------------------
Redis Connect startup script.
*******************************
Please ensure that these environment variables are correctly mapped before executing start and cli options. They can also be found in /opt/redislabs/redis-connect/bin/redisconnect.conf
Example environment variables and volume mapping for docker based deployments
-e REDISCONNECT_JOB_MANAGER_CONFIG_PATH=/opt/redislabs/redis-connect/config/jobmanager.properties
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect/config/logback.xml
-e REDISCONNECT_JAVA_OPTIONS=-Xms1g -Xmx2g
-e REDISCONNECT_EXTLIB_DIR=/opt/redislabs/redis-connect/extlib
-v <HOST_PATH_TO_JOB_MANAGER_PROPERTIES>:/opt/redislabs/redis-connect/config
-v <HOST_PATH_TO_CREDENTIALS>:/opt/redislabs/redis-connect/config/samples/credentials
-v <HOST_PATH_TO_EXTLIB>:/opt/redislabs/redis-connect/extlib
-p 8282:8282

Usage: [-h|cli|start]
options:
-h: Print this help message and exit.
-v: Print version.
cli: starts redis-connect-cli.
start: start Redis Connect instance with provided cdc or initial loader job configurations.
-------------------------------
```

</p>
</details>

-------------------------------

### Initial Loader Steps
<details><summary><b>INSERT few records into postgres table (source)</b></summary>
<p>
You can also use <a href="https://github.com/redis-field-engineering/redis-connect-crud-loader#redis-connect-crud-loader">redis-connect-crud-loader</a> to insert load large amount of data using a csv or sql file.

```bash
demo$ sudo docker exec -it postgres-12.7-$(hostname)-5432 bash -c 'psql -U"redisconnect" -d"RedisConnect"'

psql (12.7 (Debian 12.7-1.pgdg100+1))
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

<details><summary><b>Start pre configured loader job</b></summary>
<p>

```bash
docker run \
-it --rm --privileged=true \
--name redis-connect-$(hostname) \
-e REDISCONNECT_JOB_MANAGER_CONFIG_PATH=/opt/rediabs/redis-connect/config/jobmanager.properties \
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect/config/logback.xml \
-e REDISCONNECT_JAVA_OPTIONS="-Xms1g -Xmx2g" \
-e REDISCONNECT_EXTLIB_DIR=/opt/redislabs/redis-connect/extlib \
-v $(pwd)/config:/opt/redislabs/redis-connect/config \
-v $(pwd)/config/samples/credentials:/opt/redislabs/redis-connect/config/samples/credentials \
-v $(pwd)/extlib:/opt/redislabs/redis-connect/extlib \
--net host \
redislabs/redis-connect start
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

<details><summary><b>Start pre configured cdc job</b></summary>
<p>

```bash

```

</p>
</details>

<details><summary>Expected output:</summary>
<p>

```bash

```

</p>
</details>

<details><summary><b>INSERT a record into postgres table (source)</b></summary>
<p>

```bash
demo$ sudo docker exec -it postgres-12.7-$(hostname)-5432 bash -c 'psql -U"redisconnect" -d"RedisConnect"'

psql (12.7 (Debian 12.7-1.pgdg100+1))
Type "help" for help.

RedisConnect=# INSERT INTO public.emp (empno, fname, lname, job, mgr, hiredate, sal, comm, dept) VALUES (1, 'Allen', 'Terleto', 'FieldCTO', 1, '2018-08-06', 20000, 10, 1);
INSERT 0 1

RedisConnect=# select * from emp where empno=1;
 empno | fname |  lname  |   job    | mgr |  hiredate  |    sal     |  comm   | dept
-------+-------+---------+----------+-----+------------+------------+---------+------
     1 | Allen | Terleto | FieldCTO |   1 | 2018-08-06 | 20000.0000 | 10.0000 |    1
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
    2) "Allen"
    3) "Salary"
    4) "20000.0"
    5) "lname"
    6) "Terleto"
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

<!---

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

```

</p>
</details>

<details><summary><b>Start pre-configured loader job with Custom Stage</b></summary>
<p>

```bash

```

</p>
</details>

Validate the output after CustomStage run and make sure that `fname` and `lname` values in Redis has been updated to UPPER CASE.
--->