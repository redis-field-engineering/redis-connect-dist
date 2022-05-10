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
cp -R redis-connect/redis-connect-dist-main/examples/mssql/demo/* redis-connect/demo && \
cp -R redis-connect/redis-connect-dist-main/examples/mssql/k8s-docs/* redis-connect/k8s-docs && \
rm -rf main.zip redis-connect/redis-connect-dist-main && \
cd redis-connect && \
chmod a+x demo/*.sh
```

Expected output:
```bash
redis-connect$ ls
demo  k8s-docs
```

## Setup SQL Server 2019 database in docker (Source)

<br>Execute [setup_mssql.sh](setup_mssql.sh)</br>
```bash
redis-connect-sqlserver$ cd demo
demo$ ./setup_mssql.sh 2019-latest 1433
```

<details><summary>Validate SQL Server database is running as expected:</summary>
<p>

```bash
demo$ sudo docker ps -a | grep mssql
1a08b60611fd        mcr.microsoft.com/mssql/server:2019-latest   "/opt/mssql/bin/perm…"   2 weeks ago         Up 2 weeks            0.0.0.0:1433->1433/tcp                                                                                                                                                                                                                                                                                          mssql-2019-latest-virag-cdc-1433

demo$ docker exec -it mssql-2019-latest-$(hostname)-1433 /opt/mssql-tools/bin/sqlcmd -S 127.0.0.1 -U sa -P Redis@123 -y80 -Y 40 -Q 'use RedisConnect;exec sys.sp_cdc_help_change_data_capture;'
Changed database context to 'RedisConnect'.
source_schema                            source_table                             capture_instance                         object_id   source_object_id start_lsn              end_lsn                supports_net_changes has_drop_pending role_name                                index_name                               filegroup_name                           create_date             index_column_list                                                                captured_column_list
---------------------------------------- ---------------------------------------- ---------------------------------------- ----------- ---------------- ---------------------- ---------------------- -------------------- ---------------- ---------------------------------------- ---------------------------------------- ---------------------------------------- ----------------------- -------------------------------------------------------------------------------- --------------------------------------------------------------------------------
dbo                                      emp                                      cdcauditing_emp                            965578478        933578364 0x000000C0000060900001 NULL                                      1             NULL cdc_reader                               PK__emp__AF4C318A8A59B13C                NULL                                     2022-04-23 07:15:26.660 [empno]                                                                          [empno], [fname], [lname], [job], [mgr], [hiredate], [sal], [comm], [dept]  
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

<details><summary><b>Start Redis Connect Instance</b></summary>
<p>

```bash
demo$ docker run \
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
<br>_For quick start, use the sample `cdc-job.json` configuration:_ <a href="/examples/mssql/demo/config/samples/payloads/cdc-job.json">SQL Server</a>
<br><br><img src="/images/Redis Connect Save Job Config.png" style="float: right;" width = 700px height = 375px/>
<br>

**Or Use `curl` to create the `cdc-job` configuration** <br>
`demo$ curl -v -X POST "http://localhost:8282/connect/api/v1/job/config/cdc-job" -H "accept: */*" -H "Content-Type: multipart/form-data" -F "file=@config/samples/payloads/cdc-job.json;type=application/json"`

-------------------------------

### Initial Loader Steps

<details><summary><b>INSERT few records into SQL Server table (source)</b></summary>
<p>
You can also use <a href="https://github.com/redis-field-engineering/redis-connect-crud-loader#redis-connect-crud-loader">redis-connect-crud-loader</a> to insert load large amount of data using a csv or sql file.

```bash
demo$ ./insert_mssql.sh
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
demo$ sudo docker exec -it re-node1 bash -c 'redis-cli -p 12000 ft.search idx:emp "@empno:[151 152]"'

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
`demo$ curl -X GET "http://localhost:8282/connect/api/v1/cluster/jobs/claim/all" -H "accept: */*"

Expected output: `[{"jobId":"{connect}:job:cdc-job","jobName":"cdc-job","jobStatus":"CLAIMED","jobOwner":"30@virag-cdc","jobType":"STREAM"}]`

<details><summary><b>INSERT a record into SQL Server table (source)</b></summary>
<p>

```bash
demo$ sudo docker exec -it mssql-2019-latest-$(hostname)-1433 bash -c '/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "Redis@123" -d RedisConnect'

1> insert into dbo.emp values(1002, 'Virag', 'Tripathi', 'SA', 1, '2018-08-06 00:00:00.000', '2000', '10', 1)
2> go

(1 rows affected)
1> quit
```

</p>
</details>

<details><summary><b>Query for the above inserted record in Redis (target)</b></summary>
<p>

```bash
demo$ sudo docker exec -it re-node1 bash -c 'redis-cli -p 12000 idx:emp "@fname:virag"'

```

</p>
</details>
