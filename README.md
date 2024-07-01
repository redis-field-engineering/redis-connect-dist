<p align="center"><img src="/images/icons/Redis Connect Banner.png" alt="Redis Connect" width = "100%" title="Redis Connect"></p>

**Redis Connect** :rocket: is a distributed platform that enables real-time event streaming, transformation, and propagation of 
changed-data events from heterogeneous data platforms to [Azure Cache for Redis](https://azure.microsoft.com/en-us/products/cache/), [Redis Cloud](https://redis.com/redis-enterprise-cloud/overview/), and [Redis Enterprise](https://redis.com/redis-enterprise-software/overview/).
<br><br> :white_check_mark: No Code :white_check_mark: Seamless Integration :white_check_mark: Multi-Tenancy :white_check_mark: Linear-Scalability :white_check_mark: High-Availability :white_check_mark: Support
<br><br>

## End-to-End demos

<table>
    <tr>
        <td><a href="/examples/db2/demo/README.md"><img src="/images/icons/DB2 Icon.png" style="float: center;" width="100" height="100" alt="Redis Connect DB2 demo"/></a></td>
        <td><a href="/examples/mysql/demo/README.md"><img src="/images/icons/MySQL Icon.png" style="float: center;" width="100" height="100" alt="Redis Connect MySQL demo"/></a></td>
        <td><a href="/examples/oracle/demo/README.md"><img src="/images/icons/Oracle Icon.png" style="float: center;" width="100" height="100" alt="Redis Connect Oracle demo"/></a></td>
        <td><a href="/examples/postgres/demo/README.md"><img src="/images/icons/Postgres Icon.png" style="float: center;" width="100" height="100" alt="Redis Connect Postgres demo"/></a></td>
        <td><a href="/examples/mssql/demo/README.md"><img src="/images/icons/SQL Server Icon.png" style="float: center;" width="100" height="100" alt="Redis Connect SQL Server demo"/></a></td>
    </tr>
</table>
<table>
    <tr>
        <td><a href="/examples/mongodb/demo/README.md"><img src="/images/icons/MongoDB Icon.png" style="float: center;" width="100" height="100" alt="Redis Connect MongoDB demo"/></a></td>
        <td><a href="/examples/gemfire/demo/README.md"><img src="/images/icons/Geode Icon.png" style="float: center;" width="100" height="100" alt="Redis Connect Gemfire/Apache Geode demo"/></a></td>
        <td><a href="/examples/splunk/demo/README.md"><img src="/images/icons/Splunk HEC Icon.png" style="float: center;" width="100" height="100" alt="Redis Connect Splunk HEC demo"/></a></td>
        <td><a href="/examples/files/demo/README.md"><img src="/images/icons/CSV Icon.png" style="float: center;" width="100" height="100" alt="Redis Connect Files demo"/></a></td>
        <td><a href="/examples/vertica/demo/README.md"><img src="/images/icons/Vertica Icon.png" style="float: center;" width="100" height="100" alt="Redis Connect Vertica demo"/></a></td>
    </tr>
</table>

## Video Tutorials

<table>
    <tr>
        <td><a href="https://www.youtube.com/watch?v=hQWhPU7y0OU"><img src="/images/video-tutorials/Redis Connect Webinar.png" style="float: right;" width="500" height="200"/></a></td> 
        <td width="50%"><a href="https://asciinema.org/a/492521"><img src="/images/video-tutorials/Redis Connect CLI.png" style="float: right;" width="500" height="200"/></a></td> 
    </tr>
</table>

## Table of Contents

* [Background](#background)
* [Quick start](#quick-start)
* [Requirements](#requirements)

## Background

<table>
    <tr>
        <td> <b>Cloud-Native Architecture</b> <br> Redis Connect has a cloud-native and shared-nothing architecture which allows any node to operate stand-alone or as a cluster member. Its platform-agnostic and lightweight design requires minimal infrastructure and avoids complex dependencies on 3rd-party platforms. All you need is Redis Enterprise.</td>
        <td width="50%"><img src="/images/capabilities/Redis Connect Architecture.png" style="float: right;" width="500" height="250" title="Redis Connect Architecture" alt="Redis Connect Architecture"/></td>
    </tr>
    <tr><td height="20" colspan="2">&nbsp;</td></tr>
    <tr>
        <td width="50%"><img src="/images/capabilities/Redis Insight.png" style="float: right;" width="500" height="200" alt="Redis Insight"/></td> 
        <td> <b>Multi-Tenancy | Partitioning | Linear Scalability</b> <br> Redis Connect manages multi-tenant replication pipelines. A pipeline from source to sink is known as a job. Jobs with different source types can be collocated without becoming noisy neighbors. Jobs can be partitioned for linear scalability across one or more cluster nodes.</td>
    </tr>
    <tr><td bgcolor="#FFFFFF" colspan="2">&nbsp;</td></tr>
    <tr>
        <td> <b>High-Availability | Recovery</b> <br> Redis Connect jobs update their checkpoint upon each committed changed-data event within a transactional scope. In the event of a node failure or network split, in-flight jobs will fail over to another node and seamlessly begin replication from the last committed checkpoint. Data is not lost, and order is preserved. Redis Connect works in container orchestration environments such as Kubernetes and OpenShift.</td>
        <td width="50%"><img src="/images/capabilities/Redis Connect Cluster.png" style="float: right;" width="500" height="200" alt="Redis Connect Cluster"/></td>
    </tr>
    <tr><td bgcolor="#FFFFFF" colspan="2">&nbsp;</td></tr>
    <tr>
        <td width="50%"><img src="/images/capabilities/Redis Connect Custom Transformer.jpg" style="float: none;" width="500" height="150" alt="Redis Connect Custom Transformation"/></td>
        <td> <b>Custom Transformations</b> <br> Redis Connect jobs support user-defined business logic. You can create custom workflows that include user-defined stages for proprietary business rules, custom transformations, de-tokenization, and more. You can also extend the supported list of target sinks.</td> 
    </tr>
    <tr><td bgcolor="#FFFFFF" colspan="2">&nbsp;</td></tr>
    <tr>
        <td> <b>REST API | CLI | <a href="https://redis-field-engineering.github.io/redis-connect-api-docs" target="_blank">Swagger UI</a></b> <br> Redis Connect is entirely data-driven and relies on Redis Enterprise as its metadata store. You can configure, start, stop, migrate, and restart jobs using the built-in REST API and interactive CLI. Redis Connect also exposes a Swagger UI to simplify endpoint discovery and operational experience.</td>
        <td width="50%"><a href="https://redis-field-engineering.github.io/redis-connect-api-docs"><img src="/images/capabilities/Redis Connect Swagger UI.png" style="float: right;" width="500" height="200" alt="Redis Connect Swagger UI"></a></td>
    </tr>
    <tr><td bgcolor="#FFFFFF" colspan="2">&nbsp;</td></tr>
    <tr>
        <td width="50%"><img src="/images/capabilities/Redis Enterprise ACL.png" style="float: right;" width="500" height="200" alt="Redis Enterprise ACL"/></td>
        <td> <b>Enterprise-Grade Security</b> <br> Redis Connect jobs are stateless, so changed-data events are always in-transit. Redis Connect benefits from Redis Enterprise’s security, including RBAC, TLS, and more. Credentials, secrets, and trust-store passwords are never stored in Redis Connect; these secrets can be dynamically rotated with minimal disruption to the replication pipeline. Vault integration is supported.</td>
    </tr>
</table>

## Requirements

### Minimum production hardware requirements

* 1 GB of RAM
* 4 CPU cores
* 20 GB of disk space
* 1 Gbps network

### Runtime requirements

* JRE 11+ (JRE 17+ version 0.10.7 onwards) e.g. [Azul OpenJDK](https://www.azul.com/downloads/?package=jdk#download-openjdk)

## Quick Start

You can run Redis Connect as a container or by downloading the code and running in your environment of choice.

### Docker

You can run and deploy Redis Connect using the [Redis Connect Docker image](https://hub.docker.com/r/redislabs/redis-connect).

### Download

Download the [latest release](https://github.com/redis-field-engineering/redis-connect-dist/releases) for `Linux` or `Windows` and unarchive `redis-connect-<version>.<build>.[tar.gz|zip]` archive<br>

The following subdirectories will be extracted under `/redis-connect`:
* `bin` – Startup scripts
* `lib` – Dependencies
* `config` – Credentials property files, jobmanager.properties, and job-config (JSON) examples
* `extlib` – Custom/external dependencies (e.g., [custom stages](https://github.com/redis-field-engineering/redis-connect-custom-stage-demo), source-database drivers, etc.)

### Launch Redis Connect

Redis Connect includes scripts for launching a single instance. You can run the scripts as follows:

#### On Linux
```bash
redis-connect/bin$ ./redisconnect.sh    
-------------------------------
Redis Connect startup script.
*******************************
Please ensure that the value of REDISCONNECT_JOB_MANAGER_CONFIG_PATH points to the correct jobmanager.properties in /home/viragtripathi/qa/vm/redis-connect/bin/redisconnect.conf before executing any of the options below
Check the value of redis.connection.url and credentials.dir.path in jobmanager.properties e.g.
redis.connection.url=redis://redis-19836.c9.us-east-1-2.ec2.cloud.redislabs.com:19836
credentials.dir.path=/var/secrets/redis
*******************************
Usage: [-h|cli|start]
options:
-h: Print this help message and exit.
cli: init Redis Connect CLI
start: init Redis Connect Instance (Cluster Member)
-------------------------------
```

#### On Windows
```cmd
redis-connect\bin> redisconnect.bat
```

| Prerequisite Configuration :exclamation:                                                                                                                                                            |
|:----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Update `credentials.dir.path` and `redis.connection.url` in `/config/jobmanager.properties`<br/> Example - <a href="/examples/postgres/demo/config/jobmanager.properties">jobmanager.properties</a> |

### Starting an instance

Linux:
```bash
redis-connect/bin$ ./redisconnect.sh start
```
Windows:
```cmd
redis-connect\bin> redisconnect.bat start
```
<img src="/images/quick-start/Redis Connect Start Log.png" style="float: right;" width = 700px height = 250px alt="Redis Connect Start Log"/>

### Swagger UI

Redis Connect Swagger UI is available on port 8282 by default. If you're running locally, you can point your browser to `http://localhost:8282/swagger-ui/index.html`

<br>_For quick start, use '**cdc_job**' as **jobName**_
<br><br><img src="/images/quick-start/Redis Connect Swagger Front Page.jpg" style="float: right;" width = 700px height = 425px/>

**Create Job Configuration** - `/connect/api/vi/job/config/{jobName}`
<br>_For quick start, use a sample job configuration:_ <a href="/examples/db2/demo/config/samples/payloads/cdc-job.json">DB2</a>, <a href="/examples/files/demo/config/samples/payloads/cdc-job.json">Files</a>, <a href="/examples/gemfire/demo/config/samples/payloads/cdc-job.json">Gemfire</a>, <a href="/examples/mongodb/demo/config/samples/payloads/cdc-job.json">MongoDB</a>, <a href="/examples/mysql/demo/config/samples/payloads/cdc-job.json">MySQL</a>, <a href="/examples/oracle/demo/config/samples/payloads/cdc-job.json">Oracle</a>, <a href="/examples/postgres/demo/config/samples/payloads/cdc-job.json">PostgreSQL</a>, <a href="/examples/mssql/demo/config/samples/payloads/cdc-job.json">SQL Server</a> and <a href="/examples/vertica/demo/config/samples/payloads/cdc-job.json">VERTICA</a>
<br><br><img src="/images/quick-start/Redis Connect Save Job Config.png" style="float: right;" width = 700px height = 375px/>

| Prerequisite Configuration :exclamation:                                                                                                                                                                                           |
|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Update `credentialsDirectoryPath`, `databaseURL`, `database.dbname` (`database.names` for SQL Server), `database.hostname`, `database.port` and `columns` within sample job configuration for source and target, where applicable. |

**Start Job -** `/connect/api/vi/job/transition/start/{jobName}/{jobType}`
<br>_For quick start, use '**stream**' as **jobType**_
<br><br><img src="/images/quick-start/Redis Connect Start Job.png" style="float: right;" width = 700px height = 375px/><br>

**Confirm Job Claim -** `/connect/api/vi/jobs/claim/{jobStatus}`
<br>_For quick start, use '**all**' as **jobStatus**_
<br><br><img src="/images/quick-start/Redis Connect Get Claims.png" style="float: right;" width = 700px height = 250px/><br>

<br>
Once you've configured a job, try inserting some records into the source database. Then confirm that they have arrived in Redis.




### Monitoring the System

Redis Connect exports OpenTelemetry metrics via a Prometheus endpoint. A simple Prometheus configuration would look like this:

```cmd  
- job_name: "connect"
  scrape_interval: 5s
  scrape_timeout: 5s
  metrics_path: /
  scheme: http
  static_configs:
  - targets: ["localhost:19090"]
```

Redis Connect provides a dashboard for monitoring the system. After installing Grafana and connecting it to Prometheus (i.e., adding a datasource), you can install the Redis Connect dashboard by navigating to the Grafana dashboard page and clicking New -> Import.

The Redis Connect dashboard reports the following metrics:

| metric                                     | label         | type      | description                           |
|--------------------------------------------|---------------|-----------|---------------------------------------|
| event_job_starts_total                     | job starts    | count     | number of times job has been started  |
| event_job_stops_total                      | job stops     | count     | number of times job has been stopped  |
| event_input_buffer_histogram               | buffer        | histogram | number of events received             |
| event_input_buffer_count                   | buffer count  | count     | number of measurements                |
| event_input_buffer_sum                     | buffer total  | count     | sum of all measured quantities        |
| event_operation_lag                        | elapsed       | histogram | time it took connect to receive event |
| event_operation_lag_milliseconds_count     | elapsed count | count     | number of times lag was recorded      |
| event_operation_lag_milliseconds_sum       | elapsed sum   | count     | sum total of all lag recordings       |
| event_operation_latency                    | elapsed       | histogram | time it took to process the event     |
| event_operation_latency_milliseconds_count | elapsed count | count     | number of times latency was recorded  |
| event_operation_latency_milliseconds_sum   | elapsed sum   | count     | sum of all latency recordings         |
| event_operation_elapsed                    | elapsed       | histogram | time it took to write event to redis  |
| event_operation_elapsed_milliseconds_count | elapsed count | count     | number of time duration was recorded  |
| event_operation_elapsed_milliseconds_sum   | elapsed sum   | count     | sum of all duration recordings        |
| event_job_operation_throughput_total       | throughput    | count     | total number of events processed      |


## Copyright

Redis Connect is developed by Redis, Inc. Copyright (C) 2023 Redis, Inc.