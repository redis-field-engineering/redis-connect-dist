<h1>redis-connect-gemfire</h1>

redis-connect-gemfire is a connector framework for capturing changes (INSERT, UPDATE and DELETE) from Gemfire [Region(s)](https://gemfire.docs.pivotal.io/910/geode/developing/region_options/region_types.html) (source) and writing them to a Redis Enterprise database (Target).
<p>

## Overview

The functionality of the connector is based upon [Durable Client/Server Messaging](https://gemfire.docs.pivotal.io/910/geode/developing/events/implementing_durable_client_server_messaging.html).

The connector is also tolerant of failures. As the connector reads changes and produces events, it records the Checkpoint i.e. <i>DURABLE_CLIENT_ID</i> in the target Redis Enterprise database that is associated with _CDC_ record with each event.
If the connector stops for any reason (including communication failures, network problems, or crashes), upon restart it simply continues reading the Regions where it last left off.
The connector then produces a _change event_ for every row-level insert, update, and delete operation that was published via the _CDC API_, while recording all the change events for each table in a Redis Enterprise Database with a choice of your data structure such as [Hashes](https://redis.io/topics/data-types#hashes). Please see a list of supported data structures [here](../../docs/writers.md), and it's usage examples.

## Architecture

![Redis Connect high-level Architecture](/docs/images/RedisConnect_Arch.png)
<b>Redis Connect high-level Architecture Diagram</b>

Redis Connect has a cloud-native shared-nothing architecture which allows any cluster node (Redis Connect Instance) to perform either/both Job Management and Job Execution functions. It is implemented and compiled in JAVA, which deploys on a platform-independent JVM, allowing Redis Connect instances to be agnostic of the underlying operating system (Linux, Windows, Docker Containers, etc.) Its lightweight design and minimal use of infrastructure-resources avoids complex dependencies on other distributed platforms such as Kafka and ZooKeeper. In fact, most uses of Redis Connect will only require the deployment of a few JVMs to handle Job Execution and Job Management with high-availability.
<p>
On their own Redis Connect instances are stateless therefore require Redis to manage Job Management and Job Execution state – such as checkpoints, claims, optional intermediary data storage, etc. With this design, Redis Connect instances can fail/fail-over without risking data loss, duplication, and/or order. As long as another Redis Connect instance is actively available to claim responsibility for Job Execution, or can be recovered, it will pick up from the last recorded checkpoint. 

<h5>Redis Connect Components</h5>

<h6>Redis Connect Instance</h6>
<p>A Redis Connect instance is a single JVM that executes one or more pipelines.

<h6>Pipeline</h6>
<p>A Pipeline moves, transforms and orchestrates data transfer from one data structure in source data store to another data structure in target data source.

<h6>Job</h6>
<p>A Job is an implementation of a pipeline. One pipeline can have only one implementation. A job is considered “assigned” if a Redis Connect instance is executing the job. Redis Connect instance executes one or more Job processes that
<br>• Read data, in batch, from the data structure on the source data store
<br>• Transforms and maps data to a predefined data structure on the target data store
<br>• Writes data, in batch, to the data structure on the target data store

<h6>Job Manager</h6>
<p>Job Manager is a wrapper process that instantiates Job Reaper and Job Claimer processes. 

<h6>Job Reaper</h6>
<p>Job Reaper is a process, within a Redis Connect instance, that tracks the status of all jobs. If any Jobs are not being executed, then the reaper process makes them available to be “assigned”. A single job reaper process is instantiated within each Redis Connect instance. Only one job reaper process is active across all Redis Connect instances.

<h6>Job Claimer</h6>
<p>Job Claimer is a process, within a Redis Connect instance that initiates “unassigned” jobs. A single job claimer process is instantiated within each Redis Connect instance. All job claimer processes are active across all Redis Connect instances.


## Setting up Gemfire (Source)

Please refer to the installation guide and [Insall and Setup Gemfire](https://gemfire.docs.pivotal.io/910/gemfire/getting_started/installation/install_intro.html).

Here is an example with the included cache config files in the `redis-connect-gemfire/config/samples/gemfire2redis` folder.

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
gfsh>start server --name=server1 --bind-address=127.0.0.1 --cache-xml-file=~/redis-connect-gemfire/config/samples/cdc/gemfire2redis/cache.xml

Start server2
gfsh>start server --name=server2 --bind-address=127.0.0.1 --cache-xml-file=~/redis-connect-gemfire/config/samples/cdc/gemfire2redis/cache1.xml

Deploy jar for the initial loader process
gfsh>deploy --jar=~/redis-connect-gemfire/lib/connector-gemfire-fn-0.8.0.jar
```

## Setting up Redis Enterprise Databases (Target)

Before using the Gemfire connector to capture the changes committed on Gemfire into Redis Enterprise Database, first create a database for the metadata management and metrics provided by Redis Connect by creating a database with [RedisTimeSeries](https://redislabs.com/modules/redis-timeseries/) module enabled, see [Create Redis Enterprise Database](https://docs.redislabs.com/latest/rs/administering/creating-databases/#creating-a-new-redis-database) for reference. Then, create (or use an existing) another Redis Enterprise database (Target) to store the changes coming from Gemfire.

## Download and Setup

---

**NOTE**

The current [release](https://github.com/redis-field-engineering/redis-connect-dist/releases) has been built with JDK 11 and tested with JRE 11 and above. Please have JRE 11+ installed prior to running this connector.

---

Download the [latest release](https://github.com/redis-field-engineering/redis-connect-dist/releases) and un-tar redis-connect-gemfire-`<version>.<build>`.tar.gz archive.

All the contents would be extracted under redis-connect-gemfire

Contents of redis-connect-gemfire
<br>• bin – contains script files
<br>• lib – contains java libraries
<br>• config – contains sample config files for cdc and initial loader jobs
<br>• extlib – directory to copy [custom stage](https://github.com/redis-field-engineering/redis-connect-custom-stage-demo) implementation jar(s)


## Redis Connect Setup and Job Management Configurations

Copy the _sample_ directory and it's contents i.e. _yml_ files, _mappers_ and templates folder under _config_ directory to the name of your choice e.g. ``` redis-connect-gemfire$ cp -R  config/samples/gemfire2redis config/<project_name>/gemfire2redis``` or reuse sample folder as is and edit/update the configuration values according to your setup.

#### Configuration files

<details><summary>Configure logback.xml</summary>
<p>

#### logging configuration file.

### Sample logback.xml under redis-connect-gemfire/config folder
```xml
<configuration debug="true" scan="true" scanPeriod="15 seconds">

    <property name="START_UP_PATH" value="logs/redis-connect-startup.log"/>
    <property name="LOG_PATH" value="logs/redis-connect.log"/>

    <appender name="STARTUP" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <file>${START_UP_PATH}</file>
        <rollingPolicy class="ch.qos.logback.core.rolling.SizeAndTimeBasedRollingPolicy">
            <fileNamePattern>logs/archived/startup.%d{yyyy-MM-dd}.%i.log.gz</fileNamePattern>
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

    <appender name="REDISCONNECT" class="ch.qos.logback.core.rolling.RollingFileAppender">
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

    <appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
        <encoder>
            <pattern>%d{HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n</pattern>
        </encoder>
    </appender>

    <logger name="startup" level="INFO" additivity="false">
        <appender-ref ref="STARTUP"/>
        <appender-ref ref="CONSOLE" />
    </logger>

    <logger name="redisconnect" level="INFO" additivity="false">
        <appender-ref ref="REDISCONNECT"/>
        <appender-ref ref="CONSOLE" />
    </logger>


    <logger name="com.redislabs" level="INFO" additivity="false">
        <appender-ref ref="REDISCONNECT"/>
        <appender-ref ref="CONSOLE" />
    </logger>
    <logger name="io.netty" level="OFF" additivity="false">
        <appender-ref ref="REDISCONNECT"/>
        <appender-ref ref="CONSOLE" />
    </logger>
    <logger name="io.lettuce" level="OFF" additivity="false">
        <appender-ref ref="REDISCONNECT"/>
        <appender-ref ref="CONSOLE" />
    </logger>
    <logger name="org.apache" level="OFF" additivity="false">
        <appender-ref ref="REDISCONNECT"/>
        <appender-ref ref="CONSOLE"/>
    </logger>
    <logger name="org.springframework" level="OFF" additivity="false">
        <appender-ref ref="REDISCONNECT"/>
        <appender-ref ref="CONSOLE"/>
    </logger>

    <root>
        <appender-ref ref="STARTUP"/>
        <appender-ref ref="REDISCONNECT"/>
    </root>

</configuration>
```

</p>
</details>

<details><summary>Configure env.yml</summary>
<p>

#### Environment configuration file with source and target connection informations.

Redis URI syntax is described [here](https://github.com/lettuce-io/lettuce-core/wiki/Redis-URI-and-connection-details#uri-syntax).

### Sample env.yml under redis-connect-gemfire/config/samples/gemfire2redis folder
```yml
connections:
  - id: jobConfigConnection
    type: Redis
    url: redis://${REDISCONNECT_TARGET_USERNAME}:${REDISCONNECT_TARGET_PASSWORD}@127.0.0.1:14001
  - id: targetConnection
    type: Redis
    url: redis://${REDISCONNECT_TARGET_USERNAME}:${REDISCONNECT_TARGET_PASSWORD}@127.0.0.1:14000
  - id: metricsConnection
    type: Redis
    url: redis://${REDISCONNECT_TARGET_USERNAME}:${REDISCONNECT_TARGET_PASSWORD}@127.0.0.1:14001
```

</p>
</details>

<details><summary>Configure Setup.yml</summary>
<p>

#### Environment level configurations.
### Sample Setup.yml under redis-connect-gemfire/config/samples/gemfire2redis folder
```yml
connectionId: jobConfigConnection
job:
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
        gemfireConnectionProvider: GemfireConnectionProvider
        gemfireConnectionId: gemfireConnection
```

</p>
</details>

<details><summary>Configure JobManager.yml</summary>
<p>

#### Configuration for Job Reaper and Job Claimer processes.
### Sample JobManager.yml under redis-connect-gemfire/config/samples/gemfire2redis folder
```yml
connectionId: jobConfigConnection
metricsReporter:
  - REDIS_TS_METRICS_REPORTER
```

</p>
</details>

<details><summary>Configure JobConfig.yml</summary>
<p>

#### Job level details

### Sample JobConfig.yml under redis-connect-gemfire/config/samples/gemfire2redis folder
You can have one or more JobConfig.yml (or with any name e.g. JobConfig-<region_type>.yml) and specify them in the Setup.yml under jobConfig: tag. If specifying more than one table (as below) then make sure maxNumberOfJobs: tag under JobManager.yml is set accordingly e.g. if maxNumberOfJobs: tag is set to 2 then Redis Connect will start 2 cdc jobs under the same JVM instance. If the workload is more and you want to spread out (scale) the cdc jobs then create multiple JobConfig's and specify them in the Setup.yml under jobConfig: tag.
```yml
jobId: ${jobId}
producerConfig:
  producerId: GEMFIRE_EVENT_PRODUCER
  connectionProvider: "${gemfireConnectionProvider}"
  connectionId: "${gemfireConnectionId}"
  clientId: ${jobId}
  clientTimeout: "${durableClientTimeout}" #this has to be quoted, to force the value to be string
  durable: true
  metricsEnabled: false
  regions:
    - session
  pollingInterval: 100
pipelineConfig:
  bufferSize: 1024
  eventTranslator: GEMFIRE_TRANSLATOR
  checkpointConfig:
    providerId: GEMFIRE_STRING_CHECKPOINT_READER
    connectionId: targetConnection
    checkpoint: "${jobId}"
  stages:
    StringWriteStage:
      handlerId: REDIS_KV_TO_STRING_WRITER
      connectionId: targetConnection
      metricsEnabled: true
      async: true
    CheckpointStage:
      handlerId: REDIS_STRING_CHECKPOINT_WRITER
      connectionId: targetConnection
      metricEnabled: false
      async: true
      checkpoint: "${jobId}"
```

</p>
</details>

<details><summary>Configure cache-client.xml</summary>
<p>

#### cache client configuration file.
### Sample cache-client.xml under redis-connect-gemfire/config/samples/gemfire2redis folder

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
</client-cache>
```

</p>
</details>

<details><summary>Configure cache.xml</summary>
<p>

#### cache configuration file.
### Sample cache.xml under redis-connect-gemfire/config/samples/gemfire2redis folder

```xml
<?xml version="1.0" encoding="UTF-8"?>
<cache
        xmlns="http://geode.apache.org/schema/cache"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://geode.apache.org/schema/cache http://geode.apache.org/schema/cache/cache-1.0.xsd"
        version="1.0">
    <cache-server bind-address="127.0.0.1" port="11111" max-connections="16"/>

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
### Sample cache1.xml under redis-connect-gemfire/config/samples/gemfire2redis folder

```xml
<?xml version="1.0" encoding="UTF-8"?>
<cache
        xmlns="http://geode.apache.org/schema/cache"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://geode.apache.org/schema/cache http://geode.apache.org/schema/cache/cache-1.0.xsd"
        version="1.0">
    <cache-server bind-address="127.0.0.1" port="21111" max-connections="16"/>

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

## Start Redis Connect Gemfire Connector
<details><summary>Execute Redis Connect startup script to see all the options</summary>
<p>

```bash
redis-connect-gemfire/bin$ ./redisconnect.sh    
-------------------------------
Redis Connect startup script.
*******************************
Please ensure that the value of REDISCONNECT_CONFIG points to the correct config directory in /home/viragtripathi/redis-connect-gemfire/bin/redisconnect.conf before executing any of the options below
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

<h4>Stage Redis Connect Job</h4>
Before starting a Redis Connect instance, job config data needs to be seeded into Redis Config database from Job Configuration files. Configuration is provided in Setup.yml. After the configuration files are modified as needed, execute the startup script with <i>stage</i> option.

```bash
redis-connect-gemfire/bin$ ./redisconnect.sh stage
```

<h4>Start Redis Connect Job</h4>
Once staging is done, execute the same script with <i>start</i> option to start the configured Job(s) i.e. an instance of Redis Connect.

```bash
redis-connect-gemfire/bin$ ./redisconnect.sh start
```