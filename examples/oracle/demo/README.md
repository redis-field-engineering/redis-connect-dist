# Demo Outline
:white_check_mark: Setup and start Oracle database (Source)<br>
:white_check_mark: Setup and start Redis Enterprise database (Target)<br>
:white_check_mark: Setup and start Redis Connect<br>
:white_check_mark: Perform Initial load and CDC with Redis Connect<br>

# Prerequisites

* Docker compatible [*nix OS](https://en.wikipedia.org/wiki/Unix-like) and [Docker](https://docs.docker.com/get-docker) installed.
* Please have 8 vCPU*, 8GB RAM and 50GB storage for this demo to function properly. Adjust the resources based on your requirements. For HA, at least have 2 Redis Connect Connector instances deployed on separate hosts.
* [Oracle JDBC Driver](https://www.oracle.com/database/technologies/appdev/jdbc-downloads.html) (`ojdbc8.jar`)

<p>Execute the following commands (copy & paste) to download and setup Redis Connect and demo scripts.
i.e.</p>

```bash
wget -c https://github.com/redis-field-engineering/redis-connect-dist/archive/main.zip && \
mkdir -p redis-connect/demo && \
mkdir -p redis-connect/k8s-docs && \
unzip main.zip "redis-connect-dist-main/examples/oracle/*" -d redis-connect && \
cp -R redis-connect/redis-connect-dist-main/examples/oracle/demo/* redis-connect/demo && \
cp -R redis-connect/redis-connect-dist-main/examples/oracle/k8s-docs/* redis-connect/k8s-docs && \
rm -rf main.zip redis-connect/redis-connect-dist-main && \
cd redis-connect && \
chmod a+x demo/*.sh && \
cd demo
```

Expected output:
```bash
demo$ ls
README.md  delete.sql  emp.ctl                  employees1k_insert.sql  load_c##rcuser_schema.sh  setup_logminer.sh  setup_re.sh
config     emp.csv     employees10k_insert.sql  extlib                  load_sql.sh               setup_oracle.sh    update.sql
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
f31d84987694        virag/oracle-19.3.0-ee                       "/bin/sh -c 'exec $O…"   8 days ago          Up 8 days (healthy)   0.0.0.0:1522->1521/tcp                                                                                                                                                                                                                                                                                          oracle-19.3.0-ee-virag-cdc-1522

demo$ docker exec -it oracle-19.3.0-ee-$(hostname)-1522 bash -c "sqlplus c##rcuser/rcpwd@ORCLPDB1"

SQL*Plus: Release 19.0.0.0.0 - Production on Thu May 26 02:00:21 2022
Version 19.3.0.0.0

Copyright (c) 1982, 2019, Oracle.  All rights reserved.

Last Successful login time: Tue May 17 2022 03:21:34 +00:00

Connected to:
Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
Version 19.3.0.0.0

SQL> select 1 from dual;

	 1
----------
	 1

SQL> select count(*) from c##rcuser.emp;

  COUNT(*)
----------
	 0
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
demo$ docker run \
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
Starting redis-connect v0.9.1.4 Instance using JAVA 11.0.15 on virag-cdc started by root in /opt/redislabs/redis-connect/bin
Loading redis-connect Instance configuration from /opt/redislabs/redis-connect/config/jobmanager.properties
Instance classpath /opt/redislabs/redis-connect/lib/*:/opt/redislabs/redis-connect/extlib/*
02:04:12.114 [main] INFO  redis-connect-manager - ----------------------------------------------------------------------------------------------------------------------------
  /#######                  /## /##          	  /######                                                      /##
 | ##__  ##                | ## |__/          	 /##__  ##                                                    | ##
 | ##  \ ##  /######   /####### /##  /#######	| ##  \__/  /######  /#######  /#######   /######   /####### /######
 | #######/ /##__  ## /##__  ##| ## /##_____/	| ##       /##__  ##| ##__  ##| ##__  ## /##__  ## /##_____/|_  ##_/
 | ##__  ##| ########| ##  | ##| ##|  ###### 	| ##      | ##  \ ##| ##  \ ##| ##  \ ##| ########| ##        | ##
 | ##  \ ##| ##_____/| ##  | ##| ## \____  ##	| ##    ##| ##  | ##| ##  | ##| ##  | ##| ##_____/| ##        | ## /##
 | ##  | ##|  #######|  #######| ## /#######/	|  ######/|  ######/| ##  | ##| ##  | ##|  #######|  #######  |  ####/
 |__/  |__/ \_______/ \_______/|__/|_______/ 	 \______/  \______/ |__/  |__/|__/  |__/ \_______/ \_______/   \___/
Powered by Redis Enterprise
02:04:17.124 [main] INFO  redis-connect-manager - ----------------------------------------------------------------------------------------------------------------------------
02:04:18.935 [main] INFO  redis-connect-manager - Instance: 29@virag-cdc successfully established Redis connection for JobManager - JobManager
02:04:18.957 [main] INFO  redis-connect-manager - Instance: 29@virag-cdc successfully established Redis connection for JobManager - JobReaper
02:04:18.979 [main] INFO  redis-connect-manager - Instance: 29@virag-cdc successfully established Redis connection for JobManager - JobClaimer
02:04:19.000 [main] INFO  redis-connect-manager - Instance: 29@virag-cdc successfully established Redis connection for JobManager - HeartbeatManager
02:04:19.021 [main] INFO  redis-connect-manager - Instance: 29@virag-cdc successfully established Redis connection for JobManager - MetricsReporter
02:04:19.110 [main] INFO  redis-connect-manager - Instance: 29@virag-cdc skipped creating Job Claim Assignment Consumer Group since it already exists
02:04:19.115 [main] INFO  redis-connect-manager - Instance: 29@virag-cdc successfully started JobManager service
02:04:19.118 [main] INFO  redis-connect-manager - Instance: 29@virag-cdc successfully started JobReaper service
02:04:19.118 [main] INFO  redis-connect-manager - Instance: 29@virag-cdc Metrics are not enabled so MetricsReporter threadpool will not be instantiated
02:04:19.121 [main] INFO  redis-connect-manager - Instance: 29@virag-cdc successfully started JobClaimer service
02:04:24.929 [main] INFO  redis-connect-manager - Started Redis Connect REST API listening on ["http-nio-8282"]
02:04:24.930 [main] INFO  redis-connect-manager - ----------------------------------------------------------------------------------------------------------------------------
02:04:24.930 [main] INFO  redis-connect-manager -
02:04:24.930 [main] INFO  redis-connect-manager - Started Redis Connect Instance
02:04:24.930 [main] INFO  redis-connect-manager -
02:04:24.930 [main] INFO  redis-connect-manager - ----------------------------------------------------------------------------------------------------------------------------
02:04:29.116 [JobManagerThreadpool-1] INFO  redis-connect-manager - Instance: 29@virag-cdc was successfully elected Redis Connect cluster leader
02:04:29.119 [JobManagerThreadpool-2] INFO  redis-connect-heartbeat - Instance: 29@virag-cdc successfully refreshed Heartbeat: {connect}:cluster:leader:heartbeat with value: 29@virag-cdc to new Lease: 5000
```

</p>
</details>

**Open browser to access Swagger UI -** [http://localhost:8282/swagger-ui/index.html]()
<br>_For quick start, use '**cdc_job**' as **jobName**_
<br><br><img src="/images/Redis Connect Swagger Front Page.jpg" style="float: right;" width = 700px height = 425px/>

**Create Job Configuration** - `/connect/api/vi/job/config/{jobName}`
<br>_For quick start, use the sample `cdc-job.json` configuration:_ <a href="/examples/oracle/demo/config/samples/payloads/cdc-job.json">Oracle</a>
<br><br><img src="/images/Redis Connect Save Job Config.png" style="float: right;" width = 700px height = 375px/>
<br>

**Or Use `curl` to create the `cdc-job` configuration** <br>
```bash
demo$ curl -v -X POST "http://localhost:8282/connect/api/v1/job/config/cdc-job" -H "accept: */*" -H "Content-Type: multipart/form-data" -F "file=@config/samples/payloads/cdc-job.json;type=application/json"

SUCCESS
```
-------------------------------

### Initial Loader Steps

<details><summary><b>INSERT few records into emp table (source)</b></summary>
<p>
You can also use <a href="https://github.com/redis-field-engineering/redis-connect-crud-loader#redis-connect-crud-loader">redis-connect-crud-loader</a> to load large amount of data using a csv or sql file.

```bash
demo$ docker exec -it oracle-19.3.0-ee-$(hostname)-1522 bash -c "/tmp/load_sql.sh insert1k_emp"

-------------------------------

SQL*Loader: Release 19.0.0.0.0 - Production on Thu May 26 02:30:57 2022
Version 19.3.0.0.0

Copyright (c) 1982, 2019, Oracle and/or its affiliates.  All rights reserved.

Path used:      Conventional
Commit point reached - logical record count 50
Commit point reached - logical record count 100
Commit point reached - logical record count 150
Commit point reached - logical record count 200
Commit point reached - logical record count 250
Commit point reached - logical record count 300
Commit point reached - logical record count 350
Commit point reached - logical record count 400
Commit point reached - logical record count 450
Commit point reached - logical record count 500
Commit point reached - logical record count 550
Commit point reached - logical record count 600
Commit point reached - logical record count 650
Commit point reached - logical record count 700
Commit point reached - logical record count 750
Commit point reached - logical record count 800
Commit point reached - logical record count 850
Commit point reached - logical record count 900
Commit point reached - logical record count 950
Commit point reached - logical record count 1000

Table C##RCUSER.EMP:
  1000 Rows successfully loaded.

Check the log file:
  emp.log
for more information about the load.
-------------------------------
```

</p>
</details>

**Start Job -** `/connect/api/vi/job/transition/start/{jobName}/{jobType}`
<br>Use '**load**' as _**jobType**_
<br><br><img src="/images/Redis Connect Start Job.png" style="float: right;" width = 700px height = 375px/>

**Or Use `curl` to start the initial load for `cdc-job`** <br>
```bash
demo$ curl -X POST "http://localhost:8282/connect/api/v1/job/transition/start/cdc-job/load" -H "accept: */*"

SUCCESS - Transition has been scheduled
```

<details><summary><b>Query for the above inserted record in Redis (target)</b></summary>
<p>

```bash
demo$ sudo docker exec -it re-node1 bash -c 'redis-cli -p 12000 ft.search idx:emp "@EMPNO:[1 2]"'
1) (integer) 2
2) "EMP:1"
3)  1) "COMM"
    2) "123517.13"
    3) "LNAME"
    4) "McGarvie"
    5) "FirstName"
    6) "Chlo"
    7) "EmployeeNumber"
    8) "1"
    9) "MGR"
   10) "19"
   11) "HireDate"
   12) "2016-08-05 04:07:50.0"
   13) "DEPT"
   14) "96"
   15) "JOB"
   16) "General Manager"
   17) "SAL"
   18) "167105.34"
   19) "EMPNO"
   20) "1"
   21) "FNAME"
   22) "Chlo"
   23) "HIREDATE"
   24) "2016-08-05 04:07:50.0"
4) "EMP:2"
5)  1) "COMM"
    2) "165687.45"
    3) "LNAME"
    4) "Humm"
    5) "FirstName"
    6) "Alex"
    7) "EmployeeNumber"
    8) "2"
    9) "MGR"
   10) "70"
   11) "HireDate"
   12) "2019-08-14 04:01:21.0"
   13) "DEPT"
   14) "51"
   15) "JOB"
   16) "Assistant Media Planner"
   17) "SAL"
   18) "162370.71"
   19) "EMPNO"
   20) "2"
   21) "FNAME"
   22) "Alex"
   23) "HIREDATE"
   24) "2019-08-14 04:01:21.0"
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

<details><summary><b>INSERT a record into emp table (source)</b></summary>
<p>

```bash
demo$ docker exec -it oracle-19.3.0-ee-$(hostname)-1522 bash -c "sqlplus c##rcuser/rcpwd@ORCLPDB1"
SQL*Plus: Release 19.0.0.0.0 - Production on Thu May 26 03:01:01 2022
Version 19.3.0.0.0

Copyright (c) 1982, 2019, Oracle.  All rights reserved.

Last Successful login time: Thu May 26 2022 02:58:29 +00:00

Connected to:
Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
Version 19.3.0.0.0

SQL> insert into C##RCUSER.emp values (1001, 'Allen', 'Terleto', 'FieldCTO', 19, (TO_DATE('2018-08-05 04:07:50', 'yyyy-MM-dd HH:mi:ss')), 167105.34, 123517.13, 96);

1 row created.

```

</p>
</details>

<details><summary><b>Query for the above inserted record in Redis (target)</b></summary>
<p>

```bash
demo$ sudo docker exec -it re-node1 bash -c 'redis-cli -p 12000 ft.search idx:emp "@FNAME:allen"'
1) (integer) 1
2) "EMP:1001"
3)  1) "COMM"
    2) "123517.13"
    3) "LNAME"
    4) "Terleto"
    5) "HIREDATE"
    6) "1533442070000"
    7) "EMPNO"
    8) "1001"
    9) "MGR"
   10) "19"
   11) "DEPT"
   12) "96"
   13) "JOB"
   14) "FieldCTO"
   15) "FNAME"
   16) "Allen"
   17) "SAL"
   18) "167105.34"
```

</p>
</details>
