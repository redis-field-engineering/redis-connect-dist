<p align="center"><img src="/images/Redis_Connect_Intro.JPG" alt="Redis Connect" width = 650px height = 200px></p>

**Redis Connect** :rocket: is a distributed platform that enables real-time event streaming, transformation, and propagation of 
changed-data events from heterogeneous data platforms to multi-model [Redis Enterprise](https://redis.com/redis-enterprise-software/overview/) and [Redis Stack](https://redis.io/docs/stack/).
<br><br> :white_check_mark: No Code :white_check_mark: Seamless Integration :white_check_mark: Multi-Tenancy :white_check_mark: Linear-Scalability :white_check_mark: High-Availability :white_check_mark: Support
<br><br>
<p align="center"><img src="/images/Redis_Connect_Source_Sink.JPG" alt="Redis Connect Source and Sinks" width = 750px height = 375px"></p>

<table>
    <tr><td height="20" colspan="2">&nbsp;</td></tr>
    <tr>
        <td width="50%"><a href="https://redis.com/webinars/rapid-data-ingestion-with-redis-enterprise"><img src="/images/Redis_Connect_Webinar.png" style="float: right;" width="500" height="200"/></a></td> 
        <td width="50%"><a href="https://asciinema.org/a/492521"><img src="/images/Redis_Connect_CLI.png" style="float: right;" width="500" height="200"/></a></td> 
    </tr>
</table>

<table>
    <tr>
        <td> <b>Cloud-Native Architecture</b> <br> Redis Connect has a cloud-native and shared-nothing architecture which allows any node to operate stand-alone or as a cluster member. Its platform-agnostic and lightweight design requires minimal infrastructure and avoids complex dependencies on 3rd-party platforms. All you need is Redis Enterprise.</td>
        <td width="50%"><img src="/images/Redis Connect Architecture.png" style="float: right;" width="500" height="250"/></td>
    </tr>
    <tr><td height="20" colspan="2">&nbsp;</td></tr>
    <tr>
        <td width="50%"><img src="/images/Redis_Insight.png" style="float: right;" width="500" height="200"/></td> 
        <td> <b>Multi-Tenancy | Partitioning | Linear Scalability</b> <br> Redis Connect can manage multi-tenant (jobs) data replication pipelines end-to-end within a single cluster node. Jobs support a variety of different source databases which can be collocated without becoming noisy neighbors. Streaming and initial load jobs can be partitioned for linear scalability across a single or multiple cluster nodes.</td>
    </tr>
    <tr><td bgcolor="#FFFFFF" colspan="2">&nbsp;</td></tr>
    <tr>
        <td> <b>High-Availability | Recovery</b> <br> Redis Connect jobs update their checkpoint upon each committed changed-data event within a transactional scope. In the occurrence of node failure, or network split, a job would failover to another node and seamlessly begin replication from the last committed checkpoint. Data would not be lost, and order would be maintained. Redis Connect is supported on Kubernetes environments including OpenShift.</td>
        <td width="50%"><img src="/images/Redis_Connect_Cluster.png" style="float: right;" width="500" height="200"/></td>
    </tr>
    <tr><td bgcolor="#FFFFFF" colspan="2">&nbsp;</td></tr>
    <tr>
        <td width="50%"><img src="/images/Redis_Connect_Pipeline.png" style="float: right;" width="500" height="150"/></td>
        <td> <b>Custom Transformations</b> <br> Redis Connect Jobs support user-defined business logic simply by adding a JAR to the /extlib directory. Users can create custom workflows that include user-defined stages for proprietary business rules, custom transformations, de-tokenization, and more. Users can also extend the supported list of Target Sinks.</td> 
    </tr>
    <tr><td bgcolor="#FFFFFF" colspan="2">&nbsp;</td></tr>
    <tr>
        <td> <b>REST API | CLI | Swagger UI</b> <br> Redis Connect is entirely data-driven and relies on Redis Enterprise as its metadata store. Users can configure, start, stop, migrate, and restart jobs via its built-in REST API and/or interactive CLI. Redis Connect also exposes a swagger UI to simplify the user and administration experience.</td>
        <td width="50%"><img src="/images/Redis_Connect_Swagger_UI.png" style="float: right;" width="500" height="200"/></td>
    </tr>
    <tr><td bgcolor="#FFFFFF" colspan="2">&nbsp;</td></tr>
    <tr>
        <td width="50%"><img src="/images/Redis_Enterprise_ACL.png" style="float: right;" width="500" height="200"/></td>
        <td> <b>Enterprise-Grade Security</b> <br> Redis Connect jobs are stateless so changed-data events are always in-transit. Redis Connect benefits from Redis Enterprise’s enterprise-grade security capabilities including RBAC, TLS, and more. Credentials, secrets, and trust-store passwords are never stored within Redis Connect however can be dynamically rotated with minimal disruption to the replication pipeline. Vault integration is supported.</td>
    </tr>
</table>

## Quick Start

### Minimum Production Hardware Requirements

* 1GB of RAM
* 4 CPU cores
* 20GB of disk space
* 1G Network

### Runtime Requirements

* JRE 11+ e.g. [Azul OpenJDK](https://www.azul.com/downloads/?package=jdk#download-openjdk)

### Download

Download [latest release](https://github.com/redis-field-engineering/redis-connect-dist/releases) and untar redis-connect-`<version>.<build>`.tar.gz archive<br>
```bash
tar vxf <tarfile name>
```

The following subdirectories will be extracted under /redis-connect -
<br>/bin – Startup scripts
<br>/lib – Dependencies
<br>/config – Credentials property files, jobmanager.properties, and job-config (JSON) examples
<br>/extlib – Custom/External dependencies e.g. [custom stage](https://github.com/redis-field-engineering/redis-connect-custom-stage-demo), source-database drivers, etc.

### Getting Started

**Review options by running Redis Connect startup script** <br>
```bash
redis-connect/bin$ ./redisconnect.sh    
-------------------------------
Redis Connect startup script.
*******************************
Please ensure that the value of REDISCONNECT_JOB_MANAGER_CONFIG_PATH points to the correct jobmanager.properties in redisconnect.conf before executing any of the options below
*******************************
Usage: [-h|cli|start]
options:
-h: Print this help message and exit.
cli: starts redis-connect-cli
start: init Redis Connect Instance
-------------------------------
```

| Prerequisite Configuration :exclamation:                                                                                                                                                                  |
|:----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Update `credentials.file.path` and `redis.connection.url` within `/config/jobmanager.properties`<br/> Example - <a href="/examples/postgres/demo/config/jobmanager.properties">jobmanager.properties</a>  |

**Start Redis Connect Instance**
```bash
redis-connect/bin$ ./redisconnect.sh start
```
<img src="/images/Redis Connect Start Log.png" style="float: right;" width = 700px height = 250px/>

**Open a browser to access Swagger UI -** [http://localhost:8282/swagger-ui/index.html]()
<br>_For quick start, use '**cdc_job**' as **jobName**_
<br><br><img src="/images/Redis Connect Swagger Front Page.JPG" style="float: right;" width = 700px height = 425px/>

**Create a Job Configuration** - `/connect/api/vi/job/config/{jobName}`
<br>_For quick start, use a sample job configuration:_ <a href="/examples/postgres/demo/config/samples/payloads/cdc-job.json">PostgreSQL</a>, <a href="/examples/oracle/demo/config/samples/payloads/cdc-job.json">Oracle</a>, <a href="/examples/mssql/demo/config/samples/payloads/cdc-job.json">SQL Server</a>, <a href="/examples/mysql/demo/config/samples/payloads/cdc-job.json">MySQL</a> and <a href="/examples/db2/demo/config/samples/payloads/cdc-job.json">DB2</a>
<br><br><img src="/images/Redis Connect Save Job Config.png" style="float: right;" width = 700px height = 375px/>

| Prerequisite Configuration :exclamation:                                                                                                                                                                           |
|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Update `credentialsFilePath`, `databaseURL`, `database.dbname`, `database.hostname`, `database.port`, `schemaAndTableName`, and `columns` within sample job configuration for source and target, where applicable  |

**Start Job -** `/connect/api/vi/job/transition/start/{jobName}/{jobType}`
<br>_For quick start, use '**stream**' as **jobType**_
<br><br><img src="/images/Redis Connect Start Job.png" style="float: right;" width = 700px height = 375px/>

**Confirm Job Claim -** `/connect/api/vi/jobs/claim/{jobStatus}`
<br>_For quick start, use '**all**' as **jobStatus**_
<br><br><img src="/images/Redis Connect Quick Start Get Claims.png" style="float: right;" width = 700px height = 250px/>

**Insert some records to the source and confirm they have arrived in Redis. Enjoy!**