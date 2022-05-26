# Demo Outline
:white_check_mark: Setup and start MySQL database (Source)<br>
:white_check_mark: Setup and start Redis Enterprise database (Target)<br>
:white_check_mark: Setup and start Redis Connect<br>
:white_check_mark: Perform Initial load and CDC with Redis Connect<br>

# Prerequisites
Docker compatible [*nix OS](https://en.wikipedia.org/wiki/Unix-like) and [Docker](https://docs.docker.com/get-docker) installed.
<br>Please have 8 vCPU*, 8GB RAM and 50GB storage for this demo to function properly. Adjust the resources based on your requirements. For HA, at least have 2 Redis Connect Connector instances deployed on separate hosts.</br>
<br>Execute the following commands (copy & paste) to download and setup Redis Connect and demo scripts.
i.e.</br>

```bash
wget -c https://github.com/redis-field-engineering/redis-connect-dist/archive/main.zip && \
mkdir -p redis-connect/demo && \
mkdir -p redis-connect/k8s-docs && \
unzip main.zip "redis-connect-dist-main/examples/mysql/*" -d redis-connect && \
cp -R redis-connect/redis-connect-dist-main/examples/mysql/demo/* redis-connect/demo && \
cp -R redis-connect/redis-connect-dist-main/examples/mysql/k8s-docs/* redis-connect/k8s-docs && \
rm -rf main.zip redis-connect/redis-connect-dist-main && \
cd redis-connect && \
chmod a+x demo/*.sh && \
cd demo
```

Expected output:
```bash
demo$ ls
README.md  delete.sql       extlib      insert_mysql.sh  mysql_cdc.sql   setup_re.sh  update_mysql.sh
config     delete_mysql.sh  insert.sql  mysql-demo.cnf   setup_mysql.sh  update.sql
```

## Setup MySQL database in docker (Source)

<br>Execute [setup_mysql.sh](setup_mysql.sh)</br>
```bash
demo$ ./setup_mysql.sh latest 3306
```

<details><summary>Validate MySQL database is running as expected:</summary>
<p>

```bash
demo$ sudo docker ps -a | grep mysql
c6661f6e6714        mysql:latest                                 "docker-entrypoint.s…"   27 hours ago        Up 27 hours             0.0.0.0:3306->3306/tcp, 33060/tcp                                                                                                                                                                                                                                                                               mysql-latest-virag-cdc-3306
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

<details><summary>Review options by running Redis Connect docker container </summary>
<p>

```bash
docker run \
-it --rm --privileged=true \
--name redis-connect-$(hostname) \
-v $(pwd)/config:/opt/redislabs/redis-connect/config \
-v $(pwd)/config/samples/credentials:/opt/redislabs/redis-connect/config/samples/credentials \
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
-e REDISCONNECT_JOB_MANAGER_CONFIG_PATH=/opt/redislabs/redis-connect/config/jobmanager.properties [OPTIONAL]
-e REDISCONNECT_LOGBACK_CONFIG=/opt/redislabs/redis-connect/config/logback.xml [OPTIONAL]
-e REDISCONNECT_JAVA_OPTIONS=-Xms1g -Xmx2g [OPTIONAL]
-e REDISCONNECT_EXTLIB_DIR=/opt/redislabs/redis-connect/extlib [OPTIONAL]
-v <HOST_PATH_TO_JOB_MANAGER_PROPERTIES>:/opt/redislabs/redis-connect/config
-v <HOST_PATH_TO_CREDENTIALS>:/opt/redislabs/redis-connect/config/samples/credentials
-v <HOST_PATH_TO_EXTLIB>:/opt/redislabs/redis-connect/extlib [OPTIONAL]
-p 8282:8282

Usage: [-h|cli|start]
options:
-h: Print this help message and exit.
-v: Print version.
cli: init Redis Connect CLI
start: init Redis Connect Instance (Cluster Member)
-------------------------------
```

</p>
</details>

<details><summary><b>Start Redis Connect Instance</b></summary>
<p>

```bash
docker run \
-it --rm --privileged=true \
--name redis-connect-$(hostname) \
-v $(pwd)/config:/opt/redislabs/redis-connect/config \
-v $(pwd)/extlib:/opt/redislabs/redis-connect/extlib \
--net host \
redislabs/redis-connect start
```

</p>
</details>

<details><summary>Expected output:</summary>
<p>

```bash
-------------------------------
Starting redis-connect v0.9.0.4 instance using Java 11.0.15 on virag-cdc started by root in /opt/redislabs/redis-connect/bin
Loading redis-connect instance configurations from /opt/redislabs/redis-connect/config/jobmanager.properties
Instance classpath /opt/redislabs/redis-connect/lib/*:/opt/redislabs/redis-connect/extlib/*
06:42:22.996 [main] INFO  redis-connect-manager - ----------------------------------------------------------------------------------------------------------------------------
  /#######                  /## /##          	  /######                                                      /##
 | ##__  ##                | ## |__/          	 /##__  ##                                                    | ##
 | ##  \ ##  /######   /####### /##  /#######	| ##  \__/  /######  /#######  /#######   /######   /####### /######
 | #######/ /##__  ## /##__  ##| ## /##_____/	| ##       /##__  ##| ##__  ##| ##__  ## /##__  ## /##_____/|_  ##_/
 | ##__  ##| ########| ##  | ##| ##|  ###### 	| ##      | ##  \ ##| ##  \ ##| ##  \ ##| ########| ##        | ##
 | ##  \ ##| ##_____/| ##  | ##| ## \____  ##	| ##    ##| ##  | ##| ##  | ##| ##  | ##| ##_____/| ##        | ## /##
 | ##  | ##|  #######|  #######| ## /#######/	|  ######/|  ######/| ##  | ##| ##  | ##|  #######|  #######  |  ####/
 |__/  |__/ \_______/ \_______/|__/|_______/ 	 \______/  \______/ |__/  |__/|__/  |__/ \_______/ \_______/   \___/
Powered by Redis Enterprise
06:42:28.003 [main] INFO  redis-connect-manager - ----------------------------------------------------------------------------------------------------------------------------
06:42:29.843 [main] INFO  redis-connect-manager - Instance: 29@virag-cdc successfully established Redis connection for JobManager - JobManager
06:42:29.866 [main] INFO  redis-connect-manager - Instance: 29@virag-cdc successfully established Redis connection for JobManager - JobReaper
06:42:29.890 [main] INFO  redis-connect-manager - Instance: 29@virag-cdc successfully established Redis connection for JobManager - JobClaimer
06:42:29.912 [main] INFO  redis-connect-manager - Instance: 29@virag-cdc successfully established Redis connection for JobManager - HeartbeatManager
06:42:29.934 [main] INFO  redis-connect-manager - Instance: 29@virag-cdc successfully established Redis connection for JobManager - MetricsReporter
06:42:30.037 [main] INFO  redis-connect-manager - Instance: 29@virag-cdc skipped creating Job Claim Assignment Consumer Group since it already exists
06:42:30.042 [main] INFO  redis-connect-manager - Instance: 29@virag-cdc successfully started JobManager service
06:42:30.044 [main] INFO  redis-connect-manager - Instance: 29@virag-cdc successfully started JobReaper service
06:42:30.045 [main] INFO  redis-connect-manager - Instance: 29@virag-cdc Metrics are not enabled so MetricsReporter threadpool will not be instantiated
06:42:30.047 [main] INFO  redis-connect-manager - Instance: 29@virag-cdc successfully started JobClaimer service
06:42:36.006 [main] INFO  redis-connect-manager - Started Redis Connect REST API listening on ["http-nio-8282"]
06:42:36.006 [main] INFO  redis-connect-manager - ----------------------------------------------------------------------------------------------------------------------------
06:42:36.006 [main] INFO  redis-connect-manager -
06:42:36.006 [main] INFO  redis-connect-manager - Started Redis Connect Instance
06:42:36.006 [main] INFO  redis-connect-manager -
06:42:36.006 [main] INFO  redis-connect-manager - ----------------------------------------------------------------------------------------------------------------------------
06:42:40.044 [JobManagerThreadpool-1] INFO  redis-connect-manager - Instance: 29@virag-cdc was successfully elected Redis Connect cluster leader
```

</p>
</details>

**Open browser to access Swagger UI -** [http://localhost:8282/swagger-ui/index.html]()
<br>_For quick start, use '**cdc_job**' as **jobName**_
<br><br><img src="/images/Redis Connect Swagger Front Page.jpg" style="float: right;" width = 700px height = 425px/>

**Create Job Configuration** - `/connect/api/vi/job/config/{jobName}`
<br>_For quick start, use the sample `cdc-job.json` configuration:_ <a href="/examples/mysql/demo/config/samples/payloads/cdc-job.json">MySQL</a>
<br><br><img src="/images/Redis Connect Save Job Config.png" style="float: right;" width = 700px height = 375px/>
<br>

**Or Use `curl` to create the `cdc-job` configuration** <br>
`demo$ curl -v -X POST "http://localhost:8282/connect/api/v1/job/config/cdc-job" -H "accept: */*" -H "Content-Type: multipart/form-data" -F "file=@config/samples/payloads/cdc-job.json;type=application/json"`

-------------------------------

### Initial Loader Steps

<details><summary><b>INSERT few records into MySQL table (source)</b></summary>
<p>
You can also use <a href="https://github.com/redis-field-engineering/redis-connect-crud-loader#redis-connect-crud-loader">redis-connect-crud-loader</a> to insert load large amount of data using a csv or sql file.

```bash
demo$ ./insert_mysql.sh
```

</p>
</details>

**Start Job -** `/connect/api/vi/job/transition/start/{jobName}/{jobType}`
<br>Use '**load**' as _**jobType**_
<br><br><img src="/images/Redis Connect Start Job.png" style="float: right;" width = 700px height = 375px/>

**Or Use `curl` to start the initial load for `cdc-job`** <br>
`demo$ curl -X POST "http://localhost:8282/connect/api/v1/job/transition/start/cdc-job/load" -H "accept: */*"`

<details><summary><b>Query for the above inserted record in Redis (target)</b></summary>
<p>

```bash
demo$ sudo docker exec -it re-node1 bash -c 'redis-cli -p 12000 ft.search idx:emp "@empno:[1 11]"'
 1) (integer) 11
 2) "emp:1"
 3)  1) "fname"
     2) "Basanth"
     3) "lname"
     4) "Gowda"
     5) "comm"
     6) "10.0"
     7) "mgr"
     8) "1"
     9) "empno"
    10) "1"
    11) "dept"
    12) "1"
    13) "job"
    14) "FOUNDER"
    15) "hiredate"
    16) "2018-08-09 00:00:00.01"
    17) "sal"
    18) "200000.0"
 4) "emp:11"
 5)  1) "fname"
     2) "Christian"
     3) "lname"
     4) "Mague"
     5) "comm"
     6) "10.0"
     7) "mgr"
     8) "1"
     9) "empno"
    10) "11"
    11) "dept"
    12) "1"
    13) "job"
    14) "PFE"
    15) "hiredate"
    16) "2019-07-09 00:00:00.11"
    17) "sal"
    18) "200000.0"
 6) "emp:2"
 7)  1) "fname"
     2) "Virag"
     3) "lname"
     4) "Tripathi"
     5) "comm"
     6) "10.0"
     7) "mgr"
     8) "1"
     9) "empno"
    10) "2"
    11) "dept"
    12) "1"
    13) "job"
    14) "PFE"
    15) "hiredate"
    16) "2018-08-06 00:00:00.02"
    17) "sal"
    18) "2000.0"
 8) "emp:3"
 9)  1) "fname"
     2) "Drake"
     3) "lname"
     4) "Albee"
     5) "comm"
     6) "10.0"
     7) "mgr"
     8) "1"
     9) "empno"
    10) "3"
    11) "dept"
    12) "1"
    13) "job"
    14) "RSM"
    15) "hiredate"
    16) "2017-08-09 00:00:00.03"
    17) "sal"
    18) "5000.0"
10) "emp:4"
11)  1) "fname"
     2) "Nick"
     3) "lname"
     4) "Doyle"
     5) "comm"
     6) "10.0"
     7) "mgr"
     8) "1"
     9) "empno"
    10) "4"
    11) "dept"
    12) "1"
    13) "job"
    14) "DIR"
    15) "hiredate"
    16) "2019-07-09 00:00:00.04"
    17) "sal"
    18) "10000.0"
12) "emp:5"
13)  1) "fname"
     2) "Allen"
     3) "lname"
     4) "Terleto"
     5) "comm"
     6) "10.0"
     7) "mgr"
     8) "1"
     9) "empno"
    10) "5"
    11) "dept"
    12) "1"
    13) "job"
    14) "FieldCTO"
    15) "hiredate"
    16) "2017-06-09 00:00:00.05"
    17) "sal"
    18) "500000.0"
14) "emp:6"
15)  1) "fname"
     2) "Marco"
     3) "lname"
     4) "Shkedi"
     5) "comm"
     6) "10.0"
     7) "mgr"
     8) "1"
     9) "empno"
    10) "6"
    11) "dept"
    12) "1"
    13) "job"
    14) "SA"
    15) "hiredate"
    16) "2018-06-09 00:00:00.06"
    17) "sal"
    18) "2000.0"
16) "emp:7"
17)  1) "fname"
     2) "Brad"
     3) "lname"
     4) "Barnes"
     5) "comm"
     6) "10.0"
     7) "mgr"
     8) "1"
     9) "empno"
    10) "7"
    11) "dept"
    12) "1"
    13) "job"
    14) "SA"
    15) "hiredate"
    16) "2018-07-09 00:00:00.07"
    17) "sal"
    18) "2000.0"
18) "emp:8"
19)  1) "fname"
     2) "Quinton"
     3) "lname"
     4) "Gingras"
     5) "comm"
     6) "10.0"
     7) "mgr"
     8) "1"
     9) "empno"
    10) "8"
    11) "dept"
    12) "1"
    13) "job"
    14) "SDR"
    15) "hiredate"
    16) "2019-07-09 00:00:00.08"
    17) "sal"
    18) "200000.0"
20) "emp:9"
21)  1) "fname"
     2) "Yuval"
     3) "lname"
     4) "Mankerious"
     5) "comm"
     6) "10.0"
     7) "mgr"
     8) "1"
     9) "empno"
    10) "9"
    11) "dept"
    12) "1"
    13) "job"
    14) "SA"
    15) "hiredate"
    16) "2019-07-09 00:00:00.09"
    17) "sal"
    18) "200000.0"
```

</p>
</details>

-------------------------------

### CDC Steps

**Start Job -** `/connect/api/vi/job/transition/start/{jobName}/{jobType}`
<br>Use '**stream**' as _**jobType**_
<br><br><img src="/images/Redis Connect Start Job.png" style="float: right;" width = 700px height = 375px/>

**Or Use `curl` to start the stream for `cdc-job`** <br>
`demo$ curl -X POST "http://localhost:8282/connect/api/v1/job/transition/start/cdc-job/stream" -H "accept: */*"`

**Confirm Job Claim -** `/connect/api/vi/jobs/claim/{jobStatus}`
<br>_For quick start, use '**all**' as **jobStatus**_
<br><br><img src="/images/Redis Connect Quick Start Get Claims.png" style="float: right;" width = 700px height = 250px/>

**Or Use `curl` to query the `cdc-job` status** <br>
`demo$ curl -X GET "http://localhost:8282/connect/api/v1/cluster/jobs/claim/all" -H "accept: */*"`

Expected output: `[{"jobId":"{connect}:job:cdc-job","jobName":"cdc-job","jobStatus":"CLAIMED","jobOwner":"30@virag-cdc","jobType":"STREAM"}]`

<details><summary><b>INSERT a record into MySQL table (source)</b></summary>
<p>

```bash
sudo docker exec -it mysql-latest-virag-cdc-3306 bash -c "mysql -uroot -pRedis@123 RedisConnect"

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
demo$ sudo docker exec -it re-node1 bash -c 'redis-cli -p 12000 ft.search idx:emp "@empno:[1002 1002]"'
1) (integer) 1
2) "emp:1002"
3)  1) "fname"
    2) "Virag"
    3) "lname"
    4) "Tripathi"
    5) "comm"
    6) "10.0"
    7) "mgr"
    8) "1"
    9) "empno"
   10) "1002"
   11) "dept"
   12) "1"
   13) "job"
   14) "SA"
   15) "hiredate"
   16) "2018-08-06 00:00:00.00"
   17) "sal"
   18) "2000.0"
```

</p>
</details>
