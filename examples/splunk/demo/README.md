# Demo Outline
:white_check_mark: Setup and start Splunk Enterprise (Source)<br>
:white_check_mark: Setup and start Redis Enterprise database (Target)<br>
:white_check_mark: Setup and start Redis Connect<br>
:white_check_mark: Perform Initial load with Redis Connect<br>

# Prerequisites
Docker compatible [*nix OS](https://en.wikipedia.org/wiki/Unix-like) and [Docker](https://docs.docker.com/get-docker) installed.
<br>Please have 8 vCPU*, 8GB RAM and 50GB storage for this demo to function properly. Adjust the resources based on your requirements. For HA, at least have 2 Redis Connect Connector instances deployed on separate hosts.</br>
<br>Execute the following commands (copy & paste) to download and setup Redis Connect and demo scripts.
i.e.</br>

```bash
wget -c https://github.com/redis-field-engineering/redis-connect-dist/archive/main.zip && \
mkdir -p redis-connect/demo && \
mkdir -p redis-connect/k8s-docs && \
unzip main.zip "redis-connect-dist-main/examples/splunk/*" -d redis-connect && \
cp -R redis-connect/redis-connect-dist-main/examples/splunk/demo/* redis-connect/demo && \
rm -rf main.zip redis-connect/redis-connect-dist-main && \
cd redis-connect && \
chmod a+x demo/*.sh && \
cd demo
```

Expected output:
```bash
demo$ ls
README.md  config  extlib  setup_re.sh  setup_splunk.sh
```

## Setup Splunk Enterprise (Source)
<br>Execute [setup_splunk.sh](setup_splunk.sh)</br>
```bash
demo$ ./setup_splunk.sh
```

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
redislabs/redis-connect:0.9.5.5-rc1
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
redislabs/redis-connect:0.9.5.5-rc1 start
```

</p>
</details>

<details><summary>Expected output:</summary>
<p>

```bash
-------------------------------
Starting redis-connect v0.9.5.5 Instance using JAVA 11.0.15 on virag-cdc started by root in /opt/redislabs/redis-connect/bin
Loading redis-connect Instance configuration from /opt/redislabs/redis-connect/config/jobmanager.properties
Instance classpath /opt/redislabs/redis-connect/lib/*:/opt/redislabs/redis-connect/extlib/*
23:32:54.102 [main] INFO  redis-connect-manager - ----------------------------------------------------------------------------------------------------------------------------
  /#######                  /## /##          	  /######                                                      /##
 | ##__  ##                | ## |__/          	 /##__  ##                                                    | ##
 | ##  \ ##  /######   /####### /##  /#######	| ##  \__/  /######  /#######  /#######   /######   /####### /######
 | #######/ /##__  ## /##__  ##| ## /##_____/	| ##       /##__  ##| ##__  ##| ##__  ## /##__  ## /##_____/|_  ##_/
 | ##__  ##| ########| ##  | ##| ##|  ###### 	| ##      | ##  \ ##| ##  \ ##| ##  \ ##| ########| ##        | ##
 | ##  \ ##| ##_____/| ##  | ##| ## \____  ##	| ##    ##| ##  | ##| ##  | ##| ##  | ##| ##_____/| ##        | ## /##
 | ##  | ##|  #######|  #######| ## /#######/	|  ######/|  ######/| ##  | ##| ##  | ##|  #######|  #######  |  ####/
 |__/  |__/ \_______/ \_______/|__/|_______/ 	 \______/  \______/ |__/  |__/|__/  |__/ \_______/ \_______/   \___/
Powered by Redis Enterprise
23:32:59.108 [main] INFO  redis-connect-manager - ----------------------------------------------------------------------------------------------------------------------------
23:33:01.015 [main] INFO  redis-connect-manager - Instance: 30@virag-cdc successfully established Redis connection with ClientId: JobManager ConnectionId: JobManager
23:33:01.043 [main] INFO  redis-connect-manager - Instance: 30@virag-cdc successfully established Redis connection with ClientId: JobManager ConnectionId: JobReaper
23:33:01.063 [main] INFO  redis-connect-manager - Instance: 30@virag-cdc successfully established Redis connection with ClientId: JobManager ConnectionId: JobClaimer
23:33:01.085 [main] INFO  redis-connect-manager - Instance: 30@virag-cdc successfully established Redis connection with ClientId: JobManager ConnectionId: JobOrchestrator
23:33:01.112 [main] INFO  redis-connect-manager - Instance: 30@virag-cdc successfully established Redis connection with ClientId: JobManager ConnectionId: HeartbeatManager
23:33:01.138 [main] INFO  redis-connect-manager - Instance: 30@virag-cdc successfully established Redis connection with ClientId: JobManager ConnectionId: MetricsReporter
23:33:01.170 [main] INFO  redis-connect-manager - Instance: 30@virag-cdc successfully established Redis connection with ClientId: JobManager ConnectionId: CredentialsRotationEventListener
23:33:01.210 [main] INFO  redis-connect-manager - Instance: 30@virag-cdc successfully established Redis connection with ClientId: JobManager ConnectionId: ChangeEventQueue
23:33:01.297 [main] INFO  redis-connect-manager - Instance: 30@virag-cdc skipped creating Job Claim Assignment Consumer Group since it already exists
23:33:01.303 [main] INFO  redis-connect-manager - Instance: 30@virag-cdc successfully started JobManager service
23:33:01.304 [main] INFO  redis-connect-manager - Instance: 30@virag-cdc successfully started JobReaper service
23:33:01.307 [main] INFO  redis-connect-manager - Instance: 30@virag-cdc successfully started JobClaimer service
23:33:01.308 [main] INFO  redis-connect-manager - Instance: 30@virag-cdc Metrics are not enabled so MetricsReporter threadpool will not be instantiated
23:33:06.841 [main] INFO  redis-connect-manager - Instance: 30@virag-cdc started Redis Connect REST API listening on ["http-nio-8282"]
23:33:06.841 [main] INFO  redis-connect-manager - ----------------------------------------------------------------------------------------------------------------------------
23:33:06.841 [main] INFO  redis-connect-manager -
23:33:06.842 [main] INFO  redis-connect-manager - Started Redis Connect Instance
23:33:06.842 [main] INFO  redis-connect-manager -
23:33:06.842 [main] INFO  redis-connect-manager - ----------------------------------------------------------------------------------------------------------------------------
23:33:11.303 [JobManagerThreadpool-2] INFO  redis-connect-manager - Instance: 30@virag-cdc was successfully elected Redis Connect cluster leader
```

</p>
</details>

**Open browser to access Swagger UI -** [http://localhost:8282/swagger-ui/index.html]()
<br>_For quick start, use '**cdc_job**' as **jobName**_
<br><br><img src="/images/quick-start/Redis Connect Swagger Front Page.jpg" style="float: right;" width = 700px height = 425px/>

**Create Job Configuration** - `/connect/api/vi/job/config/{jobName}`
<br>_For quick start, use the sample `cdc-job.json` configuration:_ <a href="/examples/splunk/demo/config/samples/payloads/cdc-job.json">Splunk</a>
<br><br><img src="/images/quick-start/Redis Connect Save Job Config.png" style="float: right;" width = 700px height = 375px/>
<br>

**Or Use `curl` to create the `cdc-job` configuration** <br>
`demo$ curl -v -X POST "http://localhost:8282/connect/api/v1/job/config/cdc-job" -H "accept: */*" -H "Content-Type: multipart/form-data" -F "file=@config/samples/payloads/cdc-job.json;type=application/json"`

-------------------------------
