<h1>rediscdc-cassandra-connector</h1>

rediscdc-cassandra-connector is a connector framework for capturing row level changes (INSERT, UPDATE and DELETE) from Cassandra nodes (source) and writing them to a Redis Enterprise database (Target).
<p>
The first time the connector connects to a Cassandra node, it performs a snapshot of all CDC-enabled tables in all keyspaces. The connector will also read the changes that are written to Cassandra commit logs and generates corresponding insert, update, and delete events. All events for each table are recorded in a separate Redis data structure, where they can be consumed easily by applications and services.

## Overview

The functionality of the connector is based upon [change data capture](https://cassandra.apache.org/doc/latest/operating/cdc.html#enabling-or-disabling-cdc-on-a-table) feature provided by Cassandra since [Cassandra 3.x](https://cassandra.apache.org/doc/3.11.3/operating/cdc.html) where CDC was introduced.

The database operator must [enable](https://cassandra.apache.org/doc/latest/operating/cdc.html#enabling-or-disabling-cdc-on-a-table) _CDC_ for the table(s) that should be captured by the connector.
The connector then produces a _change event_ for every row-level insert, update, and delete operation that was published via the _CDC API_, while recording all the change events for each table in a Redis Enterprise Database with a choice of your data structure such as [Hashes](https://redis.io/topics/data-types#hashes).

The connector is also tolerant of failures.
As the connector reads commit logs and produces events, it records each commit log segment’s filename and position along with each event. If the connector stops for any reason (including communication failures, network problems, or crashes), upon restart it simply continues reading the commit log where it last left off. This includes snapshots: if the snapshot was not completed when the connector is stopped, upon restart it will begin a new snapshot.As the connector reads commit logs and produces events, it records each commit log segment’s filename and position along with each event. If the connector stops for any reason (including communication failures, network problems, or crashes), upon restart it simply continues reading the commit log where it last left off. This includes snapshots: if the snapshot was not completed when the connector is stopped, upon restart it will begin a new snapshot.

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


## Setting up SQL Server (Source)

Before the Cassandra connector can be used to monitor the changes in a Cassandra cluster, CDC must be enabled on the node level and table level.

## Setting up Redis Enterprise Databases (Target)

Before using the Cassandra connector (redislabs-cassandra-cdc-connector) to capture the changes committed on SQL Server into Redis Enterprise Database, first create a database for the metadata management and metrics provided by RedisCDC by creating a database with [RedisTimeSeries](https://redislabs.com/modules/redis-timeseries/) module enabled, see [Create Redis Enterprise Database](https://docs.redislabs.com/latest/rs/administering/creating-databases/#creating-a-new-redis-database) for reference. Then, create (or use an existing) another Redis Enterprise database (Target) to store the changes coming from SQL Server. Additionally, you can enable [RediSearch 2.0](https://redislabs.com/blog/introducing-redisearch-2-0/) module on the target database to enable secondary index with full-text search capabilities on the existing hashes where SQL Server changed events are being written at then [create an index, and start querying](https://oss.redislabs.com/redisearch/Commands/) the document in hashes.

## Download and Setup
---
**NOTE**

The current [release](https://github.com/RedisLabs-Field-Engineering/RedisCDC/releases/download/rediscdc-cassandra/redislabs-cassandra-cdc-connector-1.0.1.47.tar.gz) has been built with JDK1.8 and tested with JRE1.8. Please have JRE1.8 ([OpenJRE](https://openjdk.java.net/install/) or OracleJRE) installed prior to running this connector. The scripts below to seed Job config data and start RedisCDC connector is currently only written for [*nix platform](https://en.wikipedia.org/wiki/Unix-like).

---
Download the [latest release](https://github.com/RedisLabs-Field-Engineering/RedisCDC/releases) e.g. ```wget https://github.com/RedisLabs-Field-Engineering/RedisCDC/releases/download/rediscdc-cassandra/redislabs-cassandra-cdc-connector-1.0.1.47.tar.gz``` and untar (tar -xvf redislabs-cassandra-cdc-connector-1.0.1.47.tar.gz) the redislabs-cassandra-cdc-connector-1.0.1.47.tar.gz archive.

All the contents would be extracted under redislabs-cassandra-cdc-connector

Contents of redislabs-cassandra-cdc-connector
<br>•	bin – contains script files
<br>•	lib – contains java libraries
<br>•	config/samples – contains sample config files


## RedisCDC Setup and Job Management Configurations

Copy the _sample_ directory and it's contents i.e. _yml_ files, _mappers_ and templates folder under _config_ directory to the name of your choice e.g. ``` redislabs-cassandra-cdc-connector$ cp -R  config/sample config/<project_name>``` or reuse sample folder as is and edit/update the configuration values according to your setup.

#### Configuration files

<details><summary>Configure logback.xml</summary>
<p>

#### logging configuration file.
### Sample logback.xml under redislabs-cassandra-cdc-connector/config folder
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

### Sample env.yml under redislabs-cassandra-cdc-connector/config/sample folder
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
### Sample Setup.yml under redislabs-cassandra-cdc-connector/config/sample folder
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
        source: "expiry:cdc_test.customer1"
        keyPrefix: "customer1:"
```

</p>
</details>

<details><summary>Configure JobManager.yml</summary>
<p>

#### Configuration for Job Reaper and Job Claimer processes.
### Sample JobManager.yml under redislabs-cassandra-cdc-connector/config/sample folder
```yml
connectionId: jobConfigConnection # This refers to connectionId from env.yml for Job Config Redis
jobTypeId: jobType1 #Variable
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
  claimInterval: 30000
  heartBeatConfig:
    key: "hb-job:"
    expiry: 30000
  maxNumberOfJobs: 1 #This indicates the maximum number of Jobs a single RedisCDC instance can execute
  consumerGroup: jobGroup
  batchSize: 1
```

</p>
</details>

<details><summary>Configure JobConfig.yml</summary>
<p>

#### Job level details.
### Sample JobConfig.yml under redislabs-cassandra-cdc-connector/config/sample folder

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
### Sample mapper.xml under redislabs-cassandra-cdc-connector/config/sample/mappers folder

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

<h4>Seed Config Data</h4>
<p>Before starting a RedisCDC instance, job config data needs to be seeded into Redis Config database from a Job Configuration file. Configuration is provided in Setup.yml. After the file is modified as needed, execute cleansetup.sh. This script will delete existing configs and reload them into Config DB.

```bash
redislabs-cassandra-cdc-connector/bin$./cleansetup.sh
../config/samples
```

<h4>Start RedisCDC Connector</h4>
<p>Execute startup.sh script to start a RedisCDC instance. Pass <b>true</b> or <b>false</b> parameter indicating whether the RedisCDC instance should start with Job Management role.</p>

```bash
redislabs-cassandra-cdc-connector/bin$./startup.sh true (starts RedisCDC Connector with Job Management enabled)
```
```bash
redislabs-cassandra-cdc-connector/bin$./startup.sh false (starts RedisCDC Connector with Job Management disabled
```

