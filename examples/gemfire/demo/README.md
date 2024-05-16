# Demo Outline
:white_check_mark: Setup and start Gemfire database (Source)<br>
:white_check_mark: Setup and start Redis Enterprise database (Target)<br>
:white_check_mark: Setup and start Redis Connect<br>
:white_check_mark: Perform Initial load and CDC with Redis Connect<br>

# Prerequisites
Docker compatible [*nix OS](https://en.wikipedia.org/wiki/Unix-like) and [Docker](https://docs.docker.com/get-docker) installed.
<br>Please have 8 vCPU*, 8GB RAM and 50GB storage for this demo to function properly. Adjust the resources based on your requirements. For HA, at least have 2 Redis Connect instances deployed on separate hosts.</br>
<br>Execute the following commands (copy & paste) to download and setup Redis Connect and demo scripts.
i.e.</br>

```bash
wget -c https://github.com/redis-field-engineering/redis-connect-dist/archive/main.zip && \
mkdir -p redis-connect/demo && \
unzip main.zip "redis-connect-dist-main/examples/gemfire/*" -d redis-connect && \
cp -R redis-connect-dist-main/examples/gemfire/demo/* redis-connect/demo && \
rm -rf main.zip redis-connect/redis-connect-dist-main && \
cd redis-connect && \
chmod a+x demo/*.sh && \
cd demo
```

## Setup Gemfire database (Source)
<b>_Apache Geode on Docker_</b>
<br>Execute [setup_gemfire.sh](setup_gemfire.sh)</br>
```bash
demo$ ./setup_gemfire.sh
```

<details><summary>Validate Gemfire database is running as expected:</summary>
<p>

```bash
demo$ docker ps -a | grep gemfire
beb0205a037f   apachegeode/geode:1.12.9   "sh -c /geode/script…"   4 hours ago   Up 4 hours   0.0.0.0:1099->1099/tcp, 0.0.0.0:7070->7070/tcp, 0.0.0.0:8080->8080/tcp, 0.0.0.0:10334->10334/tcp, 0.0.0.0:40404->40404/tcp                                                                              gemfire-1.12.9-virag-WPG6PH3FV5

demo$ docker exec -it gemfire-1.12.9-$(hostname) sh -c "gfsh version"
1.12.9  
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
Starting redis-connect v0.10.1.5 Instance using JAVA 11.0.19 on docker-desktop started by root in /opt/redislabs/redis-connect/bin
Loading redis-connect Instance configuration from /opt/redislabs/redis-connect/config/jobmanager.properties
Instance classpath /opt/redislabs/redis-connect/lib/*:/opt/redislabs/redis-connect/extlib/*
Check redis-connect-manager-<PID>.log for cluster-level information, redis-connect-heartbeat-<PID>.log for heartbeat-lease renewals, and redis-connect-<PID>.log for the job-level information
07:11:09.184 [main] INFO  redis-connect-manager - ----------------------------------------------------------------------------------------------------------------------------
  /#######                  /## /##          	  /######                                                      /##
 | ##__  ##                | ## |__/          	 /##__  ##                                                    | ##
 | ##  \ ##  /######   /####### /##  /#######	| ##  \__/  /######  /#######  /#######   /######   /####### /######
 | #######/ /##__  ## /##__  ##| ## /##_____/	| ##       /##__  ##| ##__  ##| ##__  ## /##__  ## /##_____/|_  ##_/
 | ##__  ##| ########| ##  | ##| ##|  ###### 	| ##      | ##  \ ##| ##  \ ##| ##  \ ##| ########| ##        | ##
 | ##  \ ##| ##_____/| ##  | ##| ## \____  ##	| ##    ##| ##  | ##| ##  | ##| ##  | ##| ##_____/| ##        | ## /##
 | ##  | ##|  #######|  #######| ## /#######/	|  ######/|  ######/| ##  | ##| ##  | ##|  #######|  #######  |  ####/
 |__/  |__/ \_______/ \_______/|__/|_______/ 	 \______/  \______/ |__/  |__/|__/  |__/ \_______/ \_______/   \___/   v0.10.1
Powered by Redis Enterprise
07:11:14.190 [main] INFO  redis-connect-manager - ----------------------------------------------------------------------------------------------------------------------------
07:11:14.930 [main] INFO  redis-connect-manager - Instance: 30@docker-desktop successfully established Redis connection with ClientId: JobManager ConnectionId: JobManager
07:11:14.934 [main] INFO  redis-connect-manager - Instance: 30@docker-desktop successfully established Redis connection with ClientId: JobManager ConnectionId: JobReaper
07:11:14.939 [main] INFO  redis-connect-manager - Instance: 30@docker-desktop successfully established Redis connection with ClientId: JobManager ConnectionId: JobClaimer
07:11:14.943 [main] INFO  redis-connect-manager - Instance: 30@docker-desktop successfully established Redis connection with ClientId: JobManager ConnectionId: JobOrchestrator
07:11:14.947 [main] INFO  redis-connect-manager - Instance: 30@docker-desktop successfully established Redis connection with ClientId: JobManager ConnectionId: HeartbeatManager
07:11:14.949 [main] INFO  redis-connect-manager - Instance: 30@docker-desktop successfully established Redis connection with ClientId: JobManager ConnectionId: MetricsReporter
07:11:14.951 [main] INFO  redis-connect-manager - Instance: 30@docker-desktop successfully established Redis connection with ClientId: JobManager ConnectionId: CredentialsRotationEventListener
07:11:14.953 [main] INFO  redis-connect-manager - Instance: 30@docker-desktop successfully established Redis connection with ClientId: JobManager ConnectionId: ChangeEventQueue
07:11:14.986 [main] INFO  redis-connect-manager - Instance: 30@docker-desktop successfully created Job Claim Assignment Stream and Consumer Group
07:11:14.988 [main] INFO  redis-connect-manager - Instance: 30@docker-desktop successfully started JobManager service
07:11:14.988 [main] INFO  redis-connect-manager - Instance: 30@docker-desktop successfully started JobReaper service
07:11:14.989 [main] INFO  redis-connect-manager - Instance: 30@docker-desktop successfully started JobClaimer service
07:11:14.990 [main] INFO  redis-connect-manager - Instance: 30@docker-desktop Metrics are not enabled so MetricsReporter threadpool will not be instantiated
07:11:16.630 [main] INFO  redis-connect-manager - Instance: 30@docker-desktop started Redis Connect REST API listening on ["http-nio-8282"]
07:11:16.630 [main] INFO  redis-connect-manager - ----------------------------------------------------------------------------------------------------------------------------
07:11:16.630 [main] INFO  redis-connect-manager -
07:11:16.630 [main] INFO  redis-connect-manager - Started Redis Connect Instance v0.10.1
07:11:16.630 [main] INFO  redis-connect-manager -
07:11:16.630 [main] INFO  redis-connect-manager - ----------------------------------------------------------------------------------------------------------------------------
07:11:24.997 [JOB_MANAGER_THREADPOOL-2] INFO  redis-connect-manager - Instance: 30@docker-desktop was successfully elected Redis Connect cluster leader
```

</p>
</details>

**Open browser to access Swagger UI -** [http://localhost:8282/swagger-ui/index.html]()
<br>_For quick start, use '**cdc_job**' as **jobName**_
<br><br><img src="/images/quick-start/Redis Connect Swagger Front Page.jpg" style="float: right;" width = 700px height = 425px/>

**Create Job Configuration** - `/connect/api/vi/job/config/{jobName}`
<br>_For quick start, use the sample `cdc-job.json` configuration:_ <a href="/examples/postgres/demo/config/samples/payloads/cdc-job.json">Gemfire</a>
<br><br><img src="/images/quick-start/Redis Connect Save Job Config.png" style="float: right;" width = 700px height = 375px/>
<br>

**Or Use `curl` to create the `cdc-job` configuration** <br>
`demo$ curl -v -X POST "http://localhost:8282/connect/api/v1/job/config/cdc-job" -H "accept: */*" -H "Content-Type: multipart/form-data" -F "file=@config/samples/payloads/cdc-job.json;type=application/json"`

-------------------------------

### Initial Loader Steps

<details><summary><b>INSERT few records into Gemfire region (source)</b></summary>
<p>

```bash
demo$ ./load.sh

Inserting records in session region..

(1) Executing - connect --locator localhost[10334]

Connecting to Locator at [host=localhost, port=10334] ..
Connecting to Manager at [host=beb0205a037f, port=1099] ..
Successfully connected to: [host=beb0205a037f, port=1099]

You are connected to a cluster of version: 1.12.9


(2) Executing - put --key=(Key1) --value=(Value1) --region=/session

Result      : true
Key Class   : java.lang.String
Key         : {Key1}
Value Class : java.lang.String
Old Value   : "{UpdatedValue1}"


(3) Executing - put --key=(Key2) --value=(Value2) --region=/session

Result      : true
Key Class   : java.lang.String
Key         : {Key2}
Value Class : java.lang.String
Old Value   : "{UpdatedValue2}"


(4) Executing - put --key=(Key3) --value=(Value3) --region=/session

Result      : true
Key Class   : java.lang.String
Key         : {Key3}
Value Class : java.lang.String
Old Value   : "{Value3}"


(5) Executing - put --key=(Key4) --value=(Value4) --region=/session

Result      : true
Key Class   : java.lang.String
Key         : {Key4}
Value Class : java.lang.String
Old Value   : "{Value4}"


(6) Executing - put --key=(Key5) --value=(Value5) --region=/session

Result      : true
Key Class   : java.lang.String
Key         : {Key5}
Value Class : java.lang.String
Old Value   : "{Value5}"


(7) Executing - put --key=(Key6) --value=(Value6) --region=/session

Result      : true
Key Class   : java.lang.String
Key         : {Key6}
Value Class : java.lang.String
Old Value   : "{Value6}"


(8) Executing - put --key=(Key7) --value=(Value7) --region=/session

Result      : true
Key Class   : java.lang.String
Key         : {Key7}
Value Class : java.lang.String
Old Value   : null


(9) Executing - put --key=(Key8) --value=(Value8) --region=/session

Result      : true
Key Class   : java.lang.String
Key         : {Key8}
Value Class : java.lang.String
Old Value   : "{Value8}"


(10) Executing - put --key=(Key9) --value=(Value9) --region=/session

Result      : true
Key Class   : java.lang.String
Key         : {Key9}
Value Class : java.lang.String
Old Value   : null


(11) Executing - put --key=(Key10) --value=(Value10) --region=/session

Result      : true
Key Class   : java.lang.String
Key         : {Key10}
Value Class : java.lang.String
Old Value   : "{Value10}"

done
```

</p>
</details>

**Start Job -** `/connect/api/vi/job/transition/start/{jobName}/{jobType}`
<br>Use '**load**' as _**jobType**_
<br><br><img src="/images/quick-start/Redis Connect Start Job.png" style="float: right;" width = 700px height = 375px/>

**Or Use `curl` to start the initial load for `cdc-job`** <br>
`demo$ curl -X POST "http://localhost:8282/connect/api/v1/job/transition/start/cdc-job/load" -H "accept: */*"`

<details><summary><b>Query for the above inserted record in Redis (target)</b></summary>
<p>

```bash
demo$ 
```

</p>
</details>

-------------------------------

### CDC Steps

**Start Job -** `/connect/api/vi/job/transition/start/{jobName}/{jobType}`
<br>Use '**stream**' as _**jobType**_
<br><br><img src="/images/quick-start/Redis Connect Start Job.png" style="float: right;" width = 700px height = 375px/>

**Or Use `curl` to start the stream for `cdc-job`** <br>
`demo$ curl -X POST "http://localhost:8282/connect/api/v1/job/transition/start/cdc-job/stream" -H "accept: */*"`

**Confirm Job Claim -** `/connect/api/vi/jobs/claim/{jobStatus}`
<br>_For quick start, use '**all**' as **jobStatus**_
<br><br><img src="/images/quick-start/Redis Connect Get Claims.png" style="float: right;" width = 700px height = 250px/>

**Or Use `curl` to query the `cdc-job` status** <br>
`demo$ curl -X GET "http://localhost:8282/connect/api/v1/cluster/jobs/claim/all" -H "accept: */*"`

Expected output: `[{"jobId":"{connect}:job:cdc-job","jobName":"cdc-job","jobStatus":"CLAIMED","jobOwner":"30@virag-cdc","jobType":"STREAM"}]`

<details><summary><b>INSERT a record into Gemfire region (source)</b></summary>
<p>

```bash
demo$ ./insert.sh

Inserting records in session region..

(1) Executing - connect --locator localhost[10334]

Connecting to Locator at [host=localhost, port=10334] ..
Connecting to Manager at [host=beb0205a037f, port=1099] ..
Successfully connected to: [host=beb0205a037f, port=1099]

You are connected to a cluster of version: 1.12.9


(2) Executing - put --key=(Key11) --value=(Value11) --region=/session

Result      : true
Key Class   : java.lang.String
Key         : {Key11}
Value Class : java.lang.String
Old Value   : "{Value11}"

done
```

</p>
</details>

<details><summary><b>Query for the above inserted record in Redis (target)</b></summary>
<p>

```bash
demo$ 

```

</p>
</details>
