# redis-connect-cassandra

redis-connect-cassandra is a connector framework for capturing row level changes (INSERT, UPDATE and DELETE) from Cassandra nodes (source) and writing them to a Redis Enterprise database (Target).

The first time the connector connects to a Cassandra node, it performs a snapshot of all CDC-enabled tables in all key spaces. The connector will also read the changes that are written to Cassandra commit logs and generates corresponding insert, update, and delete events. All events for each table are recorded in a separate [Redis data structure or module](../../docs/writers.md) of your choice, where they can be consumed easily by applications and services.

## Overview

The functionality of the connector is based upon [change data capture](https://cassandra.apache.org/doc/latest/operating/cdc.html#enabling-or-disabling-cdc-on-a-table) feature provided by Cassandra since [Cassandra 3.x](https://cassandra.apache.org/doc/3.11/cassandra/operating/cdc.html) where CDC was introduced.

The database operator must [enable](https://cassandra.apache.org/doc/latest/operating/cdc.html#enabling-or-disabling-cdc-on-a-table) _CDC_ for the table(s) that should be captured by the connector.
The connector then produces a _change event_ for every row-level insert, update, and delete operation that was published via the _CDC API_, while recording all the change events for each table in a Redis Enterprise Database with a choice of your data structure such as [Hashes](https://redis.io/topics/data-types#hashes).

The connector is also tolerant of failures.
As the connector reads commit logs and produces events, it records each commit log segment’s filename and position along with each event. If the connector stops for any reason (including communication failures, network problems, or crashes), upon restart it simply continues reading the commit log where it last left off. This includes snapshots: if the snapshot was not completed when the connector is stopped, upon restart it will begin a new snapshot.As the connector reads commit logs and produces events, it records each commit log segment’s filename and position along with each event. If the connector stops for any reason (including communication failures, network problems, or crashes), upon restart it simply continues reading the commit log where it last left off. This includes snapshots: if the snapshot was not completed when the connector is stopped, upon restart it will begin a new snapshot.

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
<p>Job Claimer is a process, within a Redis Connect instance that initiates "unassigned" jobs. A single job claimer process is instantiated within each Redis Connect instance. All job claimer processes are active across all Redis Connect instances.


## Setting up Cassandra Server (Source)

Before the Cassandra connector can be used to monitor the changes in a Cassandra cluster, CDC must be enabled on the node level and table level.

## Setting up Redis Enterprise Databases (Target)

Before using the Cassandra connector (redis-connect-cassandra) to capture the changes committed on SQL Server into Redis Enterprise Database, first create a database for the metadata management and metrics provided by Redis Connect by creating a database with [RedisTimeSeries](https://redislabs.com/modules/redis-timeseries/) module enabled, see [Create Redis Enterprise Database](https://docs.redislabs.com/latest/rs/administering/creating-databases/#creating-a-new-redis-database) for reference. Then, create (or use an existing) another Redis Enterprise database (Target) to store the changes coming from SQL Server. Additionally, you can enable [RediSearch 2.0](https://redislabs.com/blog/introducing-redisearch-2-0/) module on the target database to enable secondary index with full-text search capabilities on the existing hashes where SQL Server changed events are being written at then [create an index, and start querying](https://oss.redislabs.com/redisearch/Commands/) the document in hashes.

## Download and Setup

---

### Minimum Hardware Requirements

* 1GB of RAM
* 4 CPU cores
* 20GB of disk space
* 1G Network

### Runtime Requirements

* JRE 11+
* Cassandra 3.x (see [Cassandra's doc](https://cassandra.apache.org/doc/3.11/cassandra/operating/cdc.html))

| :memo:        |
|---------------|

The current [release](https://github.com/redis-field-engineering/redis-connect-dist/releases) has been built with JDK 11 and tested with JRE 11 and above. Please have JRE 11+ installed prior to running this connector.

---

Download the [latest release](https://github.com/redis-field-engineering/redis-connect-dist/releases) and un-tar redis-connect-postgres-`<version>.<build>`.tar.gz archive.

All the contents would be extracted under redis-connect-postgres

Contents of redis-connect-postgres
<br>• bin – contains script files
<br>• lib – contains java libraries
<br>• config – contains sample config files for cdc and initial loader jobs
<br>• extlib – directory to copy [custom stage](https://github.com/redis-field-engineering/redis-connect-custom-stage-demo) implementation jar(s)


## Redis Connect Setup and Job Management Configurations

Copy the _sample_ directory and it's contents i.e. _yml_ files, _mappers_ and templates folder under _config_ directory to the name of your choice e.g. ``` redis-connect-cassandra$ cp -R  config/sample config/<project_name>``` or reuse sample folder as is and edit/update the configuration values according to your setup.

#### Configuration files

<details><summary>Configure logback.xml</summary>
<p>

#### logging configuration file.

### Sample logback.xml under redis-connect-cassandra/config folder

```xml
<configuration debug="true" scan="true" scanPeriod="15 seconds">

    <property name="LOG_REDIS_CONNECT_PATH" value="logs/redis-connect.log"/>
    <property name="LOG_REDIS_CONNECT_MANAGER_PATH" value="logs/redis-connect-manager.log"/>
    <property name="LOG_REDIS_CONNECT_HEARTBEAT_PATH" value="logs/redis-connect-heartbeat.log"/>

    <appender name="REDIS_CONNECT_HEARTBEAT" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <file>${LOG_REDIS_CONNECT_HEARTBEAT_PATH}</file>
        <rollingPolicy class="ch.qos.logback.core.rolling.SizeAndTimeBasedRollingPolicy">
            <fileNamePattern>logs/archived/redis-connect-heartbeat.%d{yyyy-MM-dd}.%i.log.gz</fileNamePattern>
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
    <appender name="REDIS_CONNECT_MANAGER" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <file>${LOG_REDIS_CONNECT_MANAGER_PATH}</file>
        <rollingPolicy class="ch.qos.logback.core.rolling.SizeAndTimeBasedRollingPolicy">
            <fileNamePattern>logs/archived/redis-connect-manager.%d{yyyy-MM-dd}.%i.log.gz</fileNamePattern>
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
    <appender name="REDIS_CONNECT" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <file>${LOG_REDIS_CONNECT_PATH}</file>
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
        <withJansi>true</withJansi>
        <encoder>
            <pattern>%d{HH:mm:ss.SSS} [%thread] %highlight(%-5level) %cyan(%logger{36}) - %msg%n</pattern>
        </encoder>
    </appender>

    <logger name="redis-connect-heartbeat" level="INFO" additivity="false">
        <appender-ref ref="REDIS_CONNECT_HEARTBEAT"/>
        <appender-ref ref="CONSOLE" />
    </logger>
    <logger name="redis-connect-manager" level="INFO" additivity="false">
        <appender-ref ref="REDIS_CONNECT_MANAGER"/>
        <appender-ref ref="CONSOLE" />
    </logger>
    <logger name="redis-connect" level="INFO" additivity="false">
        <appender-ref ref="REDIS_CONNECT"/>
        <appender-ref ref="CONSOLE" />
    </logger>
    <logger name="io.netty" level="OFF" additivity="false">
        <appender-ref ref="REDIS_CONNECT"/>
        <appender-ref ref="CONSOLE" />
    </logger>
    <logger name="io.lettuce" level="OFF" additivity="false">
        <appender-ref ref="REDIS_CONNECT"/>
        <appender-ref ref="CONSOLE" />
    </logger>
    <logger name="com.zaxxer" level="OFF" additivity="false">
        <appender-ref ref="REDIS_CONNECT"/>
        <appender-ref ref="CONSOLE"/>
    </logger>
    <logger name="io.debezium" level="INFO" additivity="false">
        <appender-ref ref="REDIS_CONNECT"/>
        <appender-ref ref="CONSOLE"/>
    </logger>
    <logger name="org.apache.kafka" level="OFF" additivity="false">
        <appender-ref ref="REDIS_CONNECT"/>
        <appender-ref ref="CONSOLE"/>
    </logger>
    <logger name="org.springframework" level="OFF" additivity="false">
        <appender-ref ref="REDIS_CONNECT"/>
        <appender-ref ref="CONSOLE"/>
    </logger>

    <root>
        <appender-ref ref="REDIS_CONNECT"/>
        <appender-ref ref="REDIS_CONNECT_MANAGER"/>
        <appender-ref ref="REDIS_CONNECT_HEARTBEAT"/>
    </root>

</configuration>
```

</p>
</details>

<details><summary>Configure env.yml</summary>
<p>

#### Environment configuration file with source and target connection informations.

Redis URI syntax is described [here](https://github.com/lettuce-io/lettuce-core/wiki/Redis-URI-and-connection-details#uri-syntax).

### Sample env.yml under redis-connect-cassandra/config/sample folder

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

### Sample Setup.yml under redis-connect-cassandra/config/sample folder
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
      - key: cdc_test:customer:Latency
        retentionInHours: 4
        labels:
          schema: cdc_test
          table: customer
      - key: cdc_test:customer:I:Throughput
        retentionInHours: 4
        labels:
          schema: cdc_test
          table: customer
          op: I
      - key: cdc_test:customer1:Latency
        retentionInHours: 4
        labels:
          schema: cdc_test
          table: customer1
      - key: cdc_test:customer1:I:Throughput
        retentionInHours: 4
        labels:
          schema: cdc_test
          table: customer1
          op: I
  jobConfig:
    - name: node1CDC
      config: JobConfig.yml
      variables:
        node: node1
    - name: node2CDC
      config: JobConfig.yml
      variables:
        node: node2
    - name: node3CDC
      config: JobConfig.yml
      variables:
        node: node3
    - name: customerExpiryHandler
      config: JobConfig-Expiry.yml
      variables:
        source: "expiry:cdc_test.customer"
        keyPrefix: "customer:"
```

</p>
</details>

<details><summary>Configure JobManager.yml</summary>
<p>

#### Configuration for Job Reaper and Job Claimer processes.

### Sample JobManager.yml under redis-connect-cassandra/config/sample folder

```yml
connectionId: jobConfigConnection
metricsReporter:
  - REDIS_TS_METRICS_REPORTER
```

</p>
</details>

<details><summary>Configure JobConfig.yml</summary>
<p>

#### Job level details. Please see [writers](../../docs/writers.md) for other write stage usages.

### Sample JobConfig.yml under redis-connect-cassandra/config/sample folder

```yml
jobId: ${jobId} #Unique Job Identifier. This value is the job name from Setup.yml
producerConfig:
  producerId: CASS_EVENT_PRODUCER
  cdcSrcLocation: "/home/viragtripathi/.ccm/cdc_cluster/${node}/cdc_raw"
  cassandraConfig: "file:///home/viragtripathi/.ccm/cdc_cluster/${node}/conf/cassandra.yaml"
  tables:
    - cdc_test.customer #Name of the table with SCHEMA.TABLE format
    - cdc_test.customer1
    - cdc_test.customer_orders
  metricsKey: "${jobId}:Metrics" 
  metricsEnabled: false
  includeExistingFiles: true
pipelineConfig:
  bufferSize: 1024
  eventTranslator: CASS_OP_2_CE_TRANSLATOR
  checkpointConfig:
    providerId: HASH_CHECKPOINT_READER
    connectionId: srcConnection
    checkpoint: "${jobId}-${node}"
  stages:
    HashWriteStage:
      handlerId: OP_2_HASH_WRITER
      connectionId: srcConnection
      prependTableNameToKeys: true
      async: true
      metricsEnabled: true
    ExpiryWriter:
      handlerId: COL_EXP_WRITER
      connectionId: srcConnection
      metricsEnabled: false
      async: true
      setPrefix: expiry
    CheckpointStage:
      handlerId: OP_CP_WRITER
      connectionId: srcConnection
      metricsEnabled: false
      async: true
      checkpoint: "${jobId}-${node}"
    CDCFileDeleter:
      handlerId: CASS_CDC_FILE_DELETER
      cdcFileNamePattern: "/home/viragtripathi/.ccm/cdc_cluster/${node}/cdc_raw/CommitLog-6-segmentId.log"
```

</p>
</details>

<details><summary>Configure mapper.xml</summary>
<p>

#### mapper configuration file.
### Sample mapper.xml under redis-connect-cassandra/config/sample/mappers folder

```xml
<Schema xmlns="http://cdc.ivoyant.com/Mapper/Config" name="cdc_test"> <!-- Schema name e.g. dbo. One mapper file per schema and you can have multiple tables in the same mapper file as long as schema is same, otherwise create multiple mapper files e.g. mapper1.xml, mapper2.xml or <table_name>.xml etc. under mappers folder of your config dir.-->
<Tables>
        <Table name="customer">
            <Mapper id="customer" processorID="Test" publishBefore="false">
                <Column src="customer_id" target="CustomerId" key="true"/>
                <Column src="address" target="Address"/>
                <Column src="age" target="Age" type="INT"/>
                <Column src="customer_since" target="CustomerSince" type="DATE"/>
                <Column src="email" target="Email"/>
                <Column src="first_name" target="FirstName"/>
                <Column src="last_name" target="LastName"/>
            </Mapper>
        </Table>
        <Table name="customer1">
            <Mapper id="customer1" processorID="Test" publishBefore="false">
                <Column src="customer_id" target="CustomerId" key="true"/>
                <Column src="address" target="Address"/>
                <Column src="age" target="Age" type="INT"/>
                <Column src="customer_since" target="CustomerSince" type="DATE"/>
                <Column src="email" target="Email"/>
                <Column src="first_name" target="FirstName"/>
                <Column src="last_name" target="LastName"/>
            </Mapper>
        </Table>  
    </Tables>
</Schema>
```

</p>
</details>

<h4>Stage Redis Connect Job</h4>
Before starting a Redis Connect instance, job config data needs to be seeded into Redis Config database from Job Configuration files. Configuration is provided in Setup.yml. After the configuration files are modified as needed, execute the startup script with <i>stage</i> option.

```bash
redis-connect-cassandra/bin$ ./redisconnect.sh stage
```

<h4>Start Redis Connect Job</h4>
Once staging is done, execute the same script with <i>start</i> option to start the configured Job(s) i.e. an instance of Redis Connect.

```bash
redis-connect-cassandra/bin$ ./redisconnect.sh start
```

