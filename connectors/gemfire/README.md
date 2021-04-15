<h1>rediscdc-gemfire-connector</h1>

rediscdc-gemfire-connector is a connector framework for capturing changes (INSERT, UPDATE and DELETE) from Gemfire [Region(s)](https://gemfire.docs.pivotal.io/910/geode/developing/region_options/region_types.html) (source) and writing them to a Redis Enterprise database (Target).
<p>

## Overview

The functionality of the connector is based upon [Durable Client/Server Messaging](https://gemfire.docs.pivotal.io/910/geode/developing/events/implementing_durable_client_server_messaging.html).

The connector is also tolerant of failures. As the connector reads changes and produces events, it records the Checkpoint i.e. <i>DURABLE_CLIENT_ID</i> in the target Redis Enterprise database that is associated with _CDC_ record with each event.
If the connector stops for any reason (including communication failures, network problems, or crashes), upon restart it simply continues reading the Regions where it last left off.

## Architecture

![RedisCDC high-level Architecture](/docs/images/RedisCDC_Architecture.png)
<b>RedisCDC high-level Architecture Diagram</b>

RedisCDC has a cloud-native shared-nothing architecture which allows any cluster node (RedisCDC Instance) to perform either/both Job Management and Job Execution functions. It is implemented and compiled in JAVA, which deploys on a platform-independent JVM, allowing RedisCDC instances to be agnostic of the underlying operating system (Linux, Windows, Docker Containers, etc.) Its lightweight design and minimal use of infrastructure-resources avoids complex dependencies on other distributed platforms such as Kafka and ZooKeeper. In fact, most uses of RedisCDC will only require the deployment of a few JVMs to handle Job Execution and Job Management with high-availability.
<p>
On their own RedisCDC instances are stateless therefore require Redis to manage Job Management and Job Execution state – such as checkpoints, claims, optional intermediary data storage, etc. With this design, RedisCDC instances can fail/failover without risking data loss, duplication, and/or order. As long as another RedisCDC instance is actively available to claim responsibility for Job Execution, or can be recovered, it will pick up from the last recorded checkpoint. 

<h5>RedisCDC Components</h5>

<h6>RedisCDC Instance</h6>
<p>A RedisCDC instance is a single JVM that executes one or more pipelines.

<h6>Pipeline</h6>
<p>A Pipeline moves, transforms and orchestrates data transfer from one data structure in source data store to another data structure in target data source.

<h6>Job</h6>
<p>A Job is an implementation of a pipeline. One pipeline can have only one implementation. A job is considered “assigned” if a RedisCDC instance is executing the job. RedisCDC instance executes one or more Job processes that
<br>• Read data, in batch, from the data structure on the source data store
<br>• Transforms and maps data to a predefined data structure on the target data store
<br>• Writes data, in batch, to the data structure on the target data store

<h6>Job Manager</h6>
<p>Job Manager is a wrapper process that instantiates Job Reaper and Job Claimer processes. 

<h6>Job Reaper</h6>
<p>Job Reaper is a process, within a RedisCDC instance, that tracks the status of all jobs. If any Jobs are not being executed, then the reaper process makes them available to be “assigned”. A single job reaper process is instantiated within each RedisCDC instance. Only one job reaper process is active across all RedisCDC instances.

<h6>Job Claimer</h6>
<p>Job Claimer is a process, within a RedisCDC instance that initiates “unassigned” jobs. A single job claimer process is instantiated within each RedisCDC instance. All job claimer processes are active across all RedisCDC instances.


## Setting up Gemfire (Source)

Please refer to the installation guide and [Insall and Setup Gemfire](https://gemfire.docs.pivotal.io/910/gemfire/getting_started/installation/install_intro.html).

Here is an example with the included cache config files in the `rl-connector-gemfire/config/samples/gemfire2redis` folder.

```bash
~/pivotal-gemfire-9.10.4/bin$ ./gfsh
    _________________________     __
   / _____/ ______/ ______/ /____/ /
  / /  __/ /___  /_____  / _____  / 
 / /__/ / ____/  _____/ / /    / /  
/______/_/      /______/_/    /_/    9.10.4

Monitor and Manage VMware Tanzu GemFire
Start locator
gfsh>start locator --name=locator1 --bind-address=127.0.0.1

Start server1
gfsh>start server --name=server1 --bind-address=127.0.0.1 --cache-xml-file=~/rl-connector-gemfire/config/samples/cdc/gemfire2redis/cache.xml

Start server2
gfsh>start server --name=server2 --bind-address=127.0.0.1 --cache-xml-file=~/rl-connector-gemfire/config/samples/cdc/gemfire2redis/cache1.xml

Deploy jar for the initial loader process
gfsh>deploy --jar=~/rl-connector-gemfire/lib/connector-gemfire-fn-1.0.2.jar
```

## Setting up Redis Enterprise Databases (Target)

Before using the Gemfire connector to capture the changes committed on Gemfire into Redis Enterprise Database, first create a database for the metadata management and metrics provided by RedisCDC by creating a database with [RedisTimeSeries](https://redislabs.com/modules/redis-timeseries/) module enabled, see [Create Redis Enterprise Database](https://docs.redislabs.com/latest/rs/administering/creating-databases/#creating-a-new-redis-database) for reference. Then, create (or use an existing) another Redis Enterprise database (Target) to store the changes coming from Gemfire.

## Download and Setup
---
**NOTE**

The current [release](https://github.com/RedisLabs-Field-Engineering/RedisCDC/releases/download/rediscdc-gemfire/rl-connector-gemfire-1.0.2.129.tar.gz) has been built with JDK1.8 and tested with JRE1.8. Please have JRE1.8 ([OpenJRE](https://openjdk.java.net/install/) or OracleJRE) installed prior to running this connector. The scripts below to seed Job config data and start RedisCDC connector is currently only written for [*nix platform](https://en.wikipedia.org/wiki/Unix-like).

---
Download the [latest release](https://github.com/RedisLabs-Field-Engineering/RedisCDC/releases) e.g. ```wget https://github.com/RedisLabs-Field-Engineering/RedisCDC/releases/download/rediscdc-gemfire/rl-connector-gemfire-1.0.2.129.tar.gz``` and untar (tar -xvf rl-connector-gemfire-1.0.2.129.tar.gz) the rl-connector-gemfire-1.0.2.129.tar.gz archive.

All the contents would be extracted under rl-connector-gemfire

Contents of rl-connector-gemfire
<br>•	bin – contains script files
<br>•	lib – contains java libraries
<br>•	config/samples/gemfire2redis – contains sample config files


## RedisCDC Setup and Job Management Configurations

Copy the _sample_ directory and it's contents i.e. _yml_ files, _mappers_ and templates folder under _config_ directory to the name of your choice e.g. ``` rl-connector-gemfire$ cp -R  config/samples/gemfire2redis config/<project_name>/gemfire2redis``` or reuse sample folder as is and edit/update the configuration values according to your setup.

#### Configuration files

<details><summary>Configure logback.xml</summary>
<p>

#### logging configuration file.
### Sample logback.xml under rl-connector-gemfire/config folder
```xml
<configuration debug="true" scan="true" scanPeriod="30 seconds">
    <property name="LOG_PATH" value="logs/cdc-1.log"/>
    <appender name="FILE-ROLLING" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <file>${LOG_PATH}</file>
        <rollingPolicy class="ch.qos.logback.core.rolling.SizeAndTimeBasedRollingPolicy">
            <fileNamePattern>logs/archived/app.%d{yyyy-MM-dd}.%i.log.gz</fileNamePattern>
            <!-- each archived file, size max 10MB -->
            <maxFileSize>10MB</maxFileSize>
            <!-- total size of all archive files, if total size > 20GB, it will delete old archived file -->
            <totalSizeCap>20GB</totalSizeCap>
            <!-- 60 days to keep -->
            <maxHistory>60</maxHistory>
        </rollingPolicy>
        <encoder>
            <pattern>%d %p %c{1.} [%t] %m%n</pattern>
        </encoder>
    </appender>

    <logger name="com.ivoyant" level="INFO" additivity="false">
        <appender-ref ref="FILE-ROLLING"/>
    </logger>
    <logger name="io.netty" level="INFO" additivity="false">
        <appender-ref ref="FILE-ROLLING"/>
    </logger>
    <logger name="io.lettuce" level="INFO" additivity="false">
        <appender-ref ref="FILE-ROLLING"/>
    </logger>

    <root level="error">
        <appender-ref ref="FILE-ROLLING"/>
    </root>

</configuration>
```

</p>
</details>

<details><summary>Configure env.yml</summary>
<p>

#### Environment configuration file with source and target connection informations.

Redis URI syntax is described [here](https://github.com/lettuce-io/lettuce-core/wiki/Redis-URI-and-connection-details#uri-syntax).

### Sample env.yml under rl-connector-gemfire/config/samples/gemfire2redis folder
```yml
connections:
  jobConfigConnection:
    redisUrl: redis://127.0.0.1:12011
  srcConnection:
      redisUrl: redis://127.0.0.1:14000
  metricsConnection:
      redisUrl: redis://127.0.0.1:12011
```

</p>
</details>

<details><summary>Configure Setup.yml</summary>
<p>

#### Environment level configurations.
### Sample Setup.yml under rl-connector-gemfire/config/samples/gemfire2redis folder
```yml
connectionId: jobConfigConnection
job:
  stream: jobStream
  configSet: jobConfigs
  consumerGroup: jobGroup
  metrics:
    connectionId: metricsConnection
    retentionInHours: 12
    keys:
      - key: "session:I:Throughput"
        retentionInHours: 4
        labels:
          region: session
          op: I
      - key: "session:U:Throughput"
        retentionInHours: 4
        labels:
          region: session
          op: U
      - key: "session:D:Throughput"
        retentionInHours: 4
        labels:
          region: session
          op: D
      - key: "job1:PendingMessageCount"
        retentionInHours: 4
  jobConfig:
    - name: job1
      config: JobConfig.yml
      variables:
        durableClientTimeout: "3000" #This is string value, not a number
        gemfireConnectionProvider: com.ivoyant.cdc.connector.gemfire.GemfireConnectionProviderImpl
        gemfireConnectionId: gemfireConnection
```

</p>
</details>

<details><summary>Configure JobManager.yml</summary>
<p>

#### Configuration for Job Reaper and Job Claimer processes.
### Sample JobManager.yml under rl-connector-gemfire/config/samples/gemfire2redis folder
```yml
connectionId: jobConfigConnection # This refers to connectionId from env.yml for Job Config Redis
jobTypeId: jobType1
jobStream: jobStream
jobConfigSet: jobConfigs
initialDelay: 10000
numManagementThreads: 2
metricsReporter: 
  - REDIS_TS_METRICS_REPORTER
heartBeatConfig:
  key: hb-jobManager
  expiry: 30000
jobHeartBeatKeyPrefix: "hb-job:"
jobHeartbeatCheckInterval: 45000
jobClaimerConfig:
  initialDelay: 10000
  claimInterval: 60000
  heartBeatConfig:
    key: "hb-job:"
    expiry: 30000 
  maxNumberOfJobs: 2
  consumerGroup: jobGroup
  batchSize: 1
```

</p>
</details>

<details><summary>Configure JobConfig.yml</summary>
<p>

#### Job level details.
### Sample JobConfig.yml under rl-connector-gemfire/config/samples/gemfire2redis folder
You can have one or more JobConfig.yml (or with any name e.g. JobConfig-<region_type>.yml) and specify them in the Setup.yml under jobConfig: tag. If specifying more than one table (as below) then make sure maxNumberOfJobs: tag under JobManager.yml is set accordingly e.g. if maxNumberOfJobs: tag is set to 2 then RedisCDC will start 2 cdc jobs under the same JVM instance. If the workload is more and you want to spread out (scale) the cdc jobs then create multiple JobConfig's and specify them in the Setup.yml under jobConfig: tag.
```yml
jobId: ${jobId} #Unique Job Identifier. This value is the job name from Setup.yml
producerConfig:
  producerId: GEMFIRE_EVENT_PRODUCER
  connectionProvider: "${gemfireConnectionProvider}"
  connectionId: "${gemfireConnectionId}"
  clientId: ${jobId}
  clientTimeout: "${durableClientTimeout}" #this has to be quoted, to force the value to be string
  metricsKey: "${jobId}:PendingMessageCount"
  durable: true
  metricsEnabled: false
  regions:
    - session
  pollingInterval: 100
pipelineConfig:
  bufferSize: 1024
  eventTranslator: ENTRY_EVENT_2_OP_TRANSLATOR
  checkpointConfig:
    providerId: STRING_CHECKPOINT_READER
    connectionId: srcConnection
    checkpoint: "${jobId}"
  stages:
    StringhWriteStage:
      handlerId: KV_2_STRING_WRITER
      connectionId: srcConnection
      metricsEnabled: true
      async: true
    CheckpointStage:
      handlerId: STRING_CP_WRITER
      connectionId: srcConnection
      metricEnabled: false
      async: true
      checkpoint: "${jobId}"
```

</p>
</details>

<details><summary>Configure cache-client.xml</summary>
<p>

#### cache client configuration file.
### Sample cache-client.xml under rl-connector-gemfire/config/samples/gemfire2redis folder

```xml
<?xml version="1.0" encoding="UTF-8"?>
<client-cache
        xmlns="http://geode.apache.org/schema/cache"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://geode.apache.org/schema/cache http://geode.apache.org/schema/cache/cache-1.0.xsd"
        version="1.0">

    <!-- Refer to https://geode.apache.org/docs/guide/19/developing/events/limit_server_subscription_queue_size.html for more details -->
    <pool name="client1" subscription-enabled="true" subscription-redundancy="1" subscription-ack-interval="3000" subscription-message-tracking-timeout="70000">
        <locator host="127.0.0.1" port="10334"/>
    </pool>

    <pdx read-serialized="false">
        <pdx-serializer>
            <class-name>org.apache.geode.pdx.ReflectionBasedAutoSerializer</class-name>
        </pdx-serializer>
    </pdx>

    <!--<region name="session">
        <region-attributes refid="PROXY" statistics-enabled="true">
            <key-constraint>java.lang.String</key-constraint>
            <value-constraint>java.lang.String</value-constraint>
        </region-attributes>
    </region>
    <region name="sessionId">
        <region-attributes refid="PROXY" statistics-enabled="true">
            <key-constraint>java.lang.String</key-constraint>
            <value-constraint>java.lang.String</value-constraint>
        </region-attributes>
    </region>
    <region name="checkpoint">
        <region-attributes refid="PROXY" statistics-enabled="true">
            <key-constraint>java.lang.String</key-constraint>
            <value-constraint>java.lang.String</value-constraint>
        </region-attributes>
    </region>-->
</client-cache>
```

</p>
</details>

<details><summary>Configure cache.xml</summary>
<p>

#### cache configuration file.
### Sample cache.xml under rl-connector-gemfire/config/samples/gemfire2redis folder

```xml
<?xml version="1.0" encoding="UTF-8"?>
<cache
        xmlns="http://geode.apache.org/schema/cache"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://geode.apache.org/schema/cache http://geode.apache.org/schema/cache/cache-1.0.xsd"
        version="1.0">
    <cache-server port="11111" max-connections="16"/>
    
    <pdx read-serialized="true">
        <pdx-serializer>
            <class-name>org.apache.geode.pdx.ReflectionBasedAutoSerializer</class-name>
        </pdx-serializer>
    </pdx>
    
    <region name="checkpoint">
        <region-attributes refid="PARTITION">
            <key-constraint>java.lang.String</key-constraint>
            <value-constraint>java.lang.String</value-constraint>
        </region-attributes>
    </region>
    <region name="session">
        <region-attributes refid="PARTITION">
            <key-constraint>java.lang.String</key-constraint>
            <value-constraint>java.lang.String</value-constraint>
        </region-attributes>
    </region>
    <region name="sessionId">
        <region-attributes refid="PARTITION">
            <key-constraint>java.lang.String</key-constraint>
            <value-constraint>java.lang.String</value-constraint>
        </region-attributes>
    </region>
</cache>
```

</p>
</details>


<details><summary>Configure cache1.xml</summary>
<p>

#### cache1 configuration file.
### Sample cache1.xml under rl-connector-gemfire/config/samples/gemfire2redis folder

```xml
<?xml version="1.0" encoding="UTF-8"?>
<cache
        xmlns="http://geode.apache.org/schema/cache"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://geode.apache.org/schema/cache http://geode.apache.org/schema/cache/cache-1.0.xsd"
        version="1.0">
    <cache-server port="21111" max-connections="16"/>
    
    <region name="checkpoint">
        <region-attributes refid="PARTITION">
            <key-constraint>java.lang.String</key-constraint>
            <value-constraint>java.lang.String</value-constraint>
        </region-attributes>
    </region>
    <region name="session">
        <region-attributes refid="PARTITION">
            <key-constraint>java.lang.String</key-constraint>
            <value-constraint>java.lang.String</value-constraint>
        </region-attributes>
    </region>
    <region name="sessionId">
        <region-attributes refid="PARTITION">
            <key-constraint>java.lang.String</key-constraint>
            <value-constraint>java.lang.String</value-constraint>
        </region-attributes>
    </region>
</cache>
```

</p>
</details>

<h4>Seed Config Data</h4>
<p>Before starting a RedisCDC instance, job config data needs to be seeded into Redis Config database from a Job Configuration file. Configuration is provided in Setup.yml. After the file is modified as needed, execute cleansetup.sh. This script will delete existing configs and reload them into Config DB.

```bash
rl-connector-gemfire/bin$./cleansetup.sh
../config/samples/gemfire2redis
```

<h4>Start RedisCDC Connector</h4>
<p>Execute startup.sh script to start a RedisCDC instance. Pass <b>true</b> or <b>false</b> parameter indicating whether the RedisCDC instance should start with Job Management role.</p>

```bash
rl-connector-gemfire/bin$./startup.sh true (starts RedisCDC Connector with Job Management enabled)
```
```bash
rl-connector-gemfire/bin$./startup.sh false (starts RedisCDC Connector with Job Management disabled
```
