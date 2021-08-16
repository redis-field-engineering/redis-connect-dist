# redis-connect-sqlserver

redis-connect-sqlserver is a Redis Connect connector for capturing changes (INSERT, UPDATE and DELETE) from MS SQL Server (source) and writing them to a Redis Enterprise database (Target).

<p>
The first time redis-connect-sqlserver connects to a SQL Server database/cluster, it reads a consistent snapshot of all of the schemas.
When that snapshot is complete, the connector continuously streams the changes that were committed to SQL Server and generates a corresponding insert, update or delete event.
All of the events for each tables are recorded in a separate Redis data structure or module of your choice, where they can be easily consumed by applications and services.

## Overview

The functionality of the connector is based upon [change data capture](https://docs.microsoft.com/en-us/sql/relational-databases/track-changes/about-change-data-capture-sql-server?view=sql-server-2017) feature provided by SQL Server Standard since [SQL Server 2016 SP1](https://blogs.msdn.microsoft.com/sqlreleaseservices/sql-server-2016-service-pack-1-sp1-released/) or Enterprise edition.
Using this mechanism, a SQL Server capture process monitors all databases and tables the user is interested in and stores the changes into specifically created _CDC_ tables that have a stored procedure facade.

The database operator must [enable](https://docs.microsoft.com/en-us/sql/relational-databases/track-changes/enable-and-disable-change-data-capture-sql-server?view=sql-server-2017) _CDC_ for the table(s) that should be captured by the connector.
The connector then produces a _change event_ for every row-level insert, update, and delete operation that was published via the _CDC API_, while recording all the change events for each table in a Redis Enterprise Database with a choice of your data structure such as [Hashes](https://redis.io/topics/data-types#hashes).

The connector is also tolerant of failures.
As the connector reads changes and produces events, it records the position i.e. [(_LSN / Log Sequence Number_)](https://docs.microsoft.com/en-us/sql/relational-databases/sql-server-transaction-log-architecture-and-management-guide?view=sql-server-ver15#Logical_Arch) in the target Redis Enterprise database that is associated with _CDC_ record with each event.
If the connector stops for any reason (including communication failures, network problems, or crashes), upon restart it simply continues reading the _CDC_ tables where it last left off.
This includes snapshots; if the snapshot was not completed when the connector is stopped, a new snapshot will begin upon a restart.

## Architecture

![Redis Connect high-level Architecture](/docs/images/RedisConnect_Arch.png)
<b>Redis Connect high-level Architecture Diagram</b>

RedisConnect has a cloud-native shared-nothing architecture which allows any cluster node (RedisConnect Instance) to perform either/both Job Management and Job Execution functions. It is implemented and compiled in JAVA, which deploys on a platform-independent JVM, allowing RedisConnect instances to be agnostic of the underlying operating system (Linux, Windows, Docker Containers, etc.) Its lightweight design and minimal use of infrastructure-resources avoids complex dependencies on other distributed platforms such as Kafka and ZooKeeper. In fact, most uses of RedisConnect will only require the deployment of a few JVMs to handle Job Execution and Job Management with high-availability.

<p>
On their own RedisConnect instances are stateless therefore require Redis to manage Job Management and Job Execution state - such as checkpoints, claims, optional intermediary data storage, etc. With this design, RedisConnect instances can fail/failover without risking data loss, duplication, and/or order. As long as another RedisConnect instance is actively available to claim responsibility for Job Execution, or can be recovered, it will pick up from the last recorded checkpoint.

<h5>Redis Connect Components</h5>

<h6>Redis Connect Instance</h6>
<p>A Redis Connect instance is a single JVM that executes one or more pipelines.

<h6>Pipeline</h6>
<p>A Pipeline moves, transforms and orchestrates data transfer from one data structure in source data store to another data structure in target data source.

<h6>Job</h6>
<p>A Job is an implementation of a pipeline. One pipeline can have only one implementation. A job is considered “assigned” if a RedisConnect instance is executing the job. RedisConnect instance executes one or more Job processes that
<br>• Read data, in batch, from the data structure on the source data store
<br>• Transforms and maps data to a predefined data structure on the target data store
<br>• Writes data, in batch, to the data structure on the target data store

<h6>Job Manager</h6>
<p>Job Manager is a wrapper process that instantiates Job Reaper and Job Claimer processes.

<h6>Job Reaper</h6>
<p>Job Reaper is a process, within a RedisConnect instance, that tracks the status of all jobs. If any Jobs are not being executed, then the reaper process makes them available to be “assigned”. A single job reaper process is instantiated within each RedisConnect instance. Only one job reaper process is active across all RedisConnect instances.

<h6>Job Claimer</h6>
<p>Job Claimer is a process, within a RedisConnect instance that initiates “unassigned” jobs. A single job claimer process is instantiated within each RedisConnect instance. All job claimer processes are active across all RedisConnect instances.

## Setting up SQL Server (Source)

Before using the SQL Server connector (redis-connect-sqlserver) to monitor the changes committed on SQL Server, first [enable](https://docs.microsoft.com/en-us/sql/relational-databases/track-changes/enable-and-disable-change-data-capture-sql-server?view=sql-server-2017) _CDC_ on a monitored database.

<h5>Note: To support net changes queries, the source table must have a primary key or unique index to uniquely identify rows. If a unique index is used, the name of the index must be specified using the <em>@index_name</em> parameter. The columns defined in the primary key or unique index must be included in the list of source columns to be captured.</h5>

Please see [Enable Change Data Capture for a Table](https://docs.microsoft.com/en-us/sql/relational-databases/track-changes/enable-and-disable-change-data-capture-sql-server?view=sql-server-ver15#enable-change-data-capture-for-a-table) for reference.

Please see an example, [SQL Statements](https://github.com/RedisLabs-Field-Engineering/redis-connect-dist/blob/master/connectors/mssql/demo/mssql_cdc.sql) under [Demo](https://github.com/RedisLabs-Field-Engineering/redis-connect-dist/blob/master/connectors/mssql/demo/).

## Setting up Redis Enterprise Databases (Target)

Before using the SQL Server connector (redis-connect-sqlserver) to capture the changes committed on SQL Server into Redis Enterprise Database, first create a database for the metadata management and metrics provided by RedisConnect by creating a database with [RedisTimeSeries](https://redislabs.com/modules/redis-timeseries/) module enabled, see [Create Redis Enterprise Database](https://docs.redislabs.com/latest/rs/administering/creating-databases/#creating-a-new-redis-database) for reference. Then, create (or use an existing) another Redis Enterprise database (Target) to store the changes coming from SQL Server. Additionally, you can enable [RediSearch 2.0](https://redislabs.com/blog/introducing-redisearch-2-0/) module on the target database to enable secondary index with full-text search capabilities on the existing hashes where SQL Server changed events are being written at then [create an index, and start querying](https://oss.redislabs.com/redisearch/Commands/) the document in hashes.

## Download and Setup

---

**NOTE**

The current [release](https://github.com/RedisLabs-Field-Engineering/redis-connect-dist/releases) has been built with JDK 1.8 and tested with JRE 1.8 and above. Please have JRE 1.8 ([OpenJRE](https://openjdk.java.net/install/) or OracleJRE) or above installed prior to running this connector.

---

Download the [latest release](https://github.com/RedisLabs-Field-Engineering/redis-connect-dist/releases) and untar redis-connect-sqlserver-`<version>.<build>`.tar.gz archive.

All the contents would be extracted under redis-connect-sqlserver

Contents of redis-connect-sqlserver
<br>• bin – contains script files
<br>• lib – contains java libraries
<br>• config – contains sample config files for cdc and initial loader jobs
<br>• extlib – directory to copy [custom stage](https://github.com/RedisLabs-Field-Engineering/redis-connect-custom-stage-demo) implementation jar(s)

## RedisConnect Setup and Job Management Configurations

Copy the _sample_ directory and it's contents i.e. _yml_ files, _mappers_ and templates folder under _config_ directory to the name of your choice e.g. `redis-connect-sqlserver$ cp -R config/samples/sqlserver config/<project_name>` or reuse sample folder as is and edit/update the configuration values according to your setup.

#### Configuration files

<details><summary>Configure logback.xml</summary>
<p>

#### logging configuration file.

### Sample logback.xml under redis-connect-sqlserver/config folder

```xml
<configuration debug="true" scan="true" scanPeriod="30 seconds">

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
        <appender-ref ref="CONSOLE" />
    </logger>
    <logger name="io.lettuce" level="OFF" additivity="false">
        <appender-ref ref="CONSOLE" />
    </logger>
    <logger name="com.zaxxer" level="OFF" additivity="false">
        <appender-ref ref="REDISCONNECT"/>
        <appender-ref ref="STARTUP"/>
    </logger>
    <logger name="io.debezium" level="OFF" additivity="false">
        <appender-ref ref="REDISCONNECT"/>
        <appender-ref ref="STARTUP"/>
    </logger>
    <logger name="org.apache.kafka" level="OFF" additivity="false">
        <appender-ref ref="REDISCONNECT"/>
        <appender-ref ref="STARTUP"/>
    </logger>
    <logger name="org.springframework" level="OFF" additivity="false">
        <appender-ref ref="REDISCONNECT"/>
        <appender-ref ref="STARTUP"/>
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

### Sample env.yml under redis-connect-sqlserver/config/samples/sqlserver folder. Any of these fields (values) can be replaced by environment variables.

```yml
connections:
  jobConfigConnection:
    redisUrl: redis://127.0.0.1:14001 #Job configuration Redis database
  srcConnection:
    redisUrl: redis://127.0.0.1:14000 #Target Redis database
  metricsConnection:
    redisUrl: redis://127.0.0.1:14001 #Metrics Redis database, can be same as Job Configuration database.
  msSQLServerConnection:
    database:
      name: testdb #database name same as database value in Setup.yml
      db: RedisConnect #database
      hostname: 127.0.0.1
      port: 1433
      username: sa #This can be a non privileged user. Please see and example in the demo, https://github.com/RedisLabs-Field-Engineering/redis-connect-dist/blob/main/connectors/mssql/demo/mssql_cdc.sql#L36
      password: Redis@123
      type: mssqlserver #this value cannot be changed for mssqlserver
      jdbcUrl: "jdbc:sqlserver://127.0.0.1:1433;database=RedisConnect"
      maximumPoolSize: 10
      minimumIdle: 2
    include.query: "true"
    snapshot.mode: initial
    snapshot.isolation.mode: read_uncommitted
    schemas.enable: "false"
    include.schema.changes: "false"
    decimal.handling.mode: double
```

</p>
</details>

<details><summary>Configure Setup.yml</summary>
<p>

#### Environment level configurations.

### Sample Setup.yml under redis-connect-sqlserver/config/samples/sqlserver folder

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
      - key: "dbo:emp:C:Throughput"
        retentionInHours: 4
        labels:
          schema: dbo
          table: emp
          op: I
      - key: "dbo:emp:U:Throughput"
        retentionInHours: 4
        labels:
          schema: dbo
          table: emp
          op: U
      - key: "dbo:emp:D:Throughput"
        retentionInHours: 4
        labels:
          schema: dbo
          table: emp
          op: D
      - key: "dbo:emp:Latency"
        retentionInHours: 4
        labels:
          schema: dbo
          table: emp
  jobConfig:
    - name: testdb-emp
      config: JobConfig.yml
      variables:
        database: testdb
        sourceValueTranslator: SOURCE_RECORD_TO_OP_TRANSLATOR
```

</p>
</details>

<details><summary>Configure JobManager.yml</summary>
<p>

#### Configuration for Job Reaper and Job Claimer processes.

### Sample JobManager.yml under redis-connect-sqlserver/config/samples/sqlserver folder

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
  maxNumberOfJobs: 2 #This indicates the maximum number of Jobs a single RedisConnect instance can execute
  consumerGroup: jobGroup
  batchSize: 1
```

</p>
</details>

<details><summary>Configure JobConfig.yml</summary>
<p>

#### Job level details.

### Sample JobConfig.yml under redis-connect-sqlserver/config/samples/sqlserver folder

You can have one or more JobConfig.yml (or with any name e.g. JobConfig-<table_name>.yml) and specify them in the Setup.yml under jobConfig: tag. If specifying more than one table (as below) then make sure maxNumberOfJobs: tag under JobManager.yml is set accordingly e.g. if maxNumberOfJobs: tag is set to 2 then RedisConnect will start 2 cdc jobs under the same JVM instance. If the workload is more and you want to spread out (scale) the cdc jobs then create multiple JobConfig's and specify them in the Setup.yml under jobConfig: tag.

```yml
jobId: ${jobId} #Unique Job Identifier. This value is the job name from Setup.yml
producerConfig:
  producerId: RDB_EVENT_PRODUCER
  connectionId: testdb-msSQLServerConnection #Name of the Redis connection id specified in env.yml
  tables:
    - dbo.emp #Name of the table with SCHEMA.TABLE format
  #    - dbo.dept #Name of the table with SCHEMA.TABLE format
  pollingInterval: 5
  metricsKey: testdb-emp
  metricsEnabled: false
pipelineConfig:
  bufferSize: 1024
  eventTranslator: "${sourceValueTranslator}"
  checkpointConfig:
    providerId: RDB_CHECKPOINT_READER
    connectionId: srcConnection
    checkpoint: "${jobId}-${database}"
  stages:
    HashWriteStage:
      handlerId: REDIS_HASH_WRITER
      connectionId: srcConnection
      metricsEnabled: false
      prependTableNameToKeys: true
      deleteOnKeyUpdate: true
      async: true
    CheckpointStage:
      handlerId: REDIS_OP_CP_WRITER
      connectionId: srcConnection
      metricEnabled: false
      async: true
      checkpoint: "${jobId}-${database}"
```

</p>
</details>

<details><summary>Configure mapper.yml</summary>
<p>

#### mapper configuration file.

### Sample mapper.yml under redis-connect-sqlserver/config/samples/sqlserver/mappers folder

```yml
schema: dbo # Schema name e.g. dbo. One mapper file per schema and you can have multiple tables in the same mapper file as long as schema is same, otherwise create multiple mapper files e.g. mapper1.xml, mapper2.xml or <table_name>.xml etc. under mappers folder of your config dir.
tables:
  - table: emp # emp table under dbo schema
    mapper:
      id: Test
      processorID: Test
      publishBefore: false # publishBefore - Global setting, that specifies if before values have to be published for all columns. This setting could be overridden at each column level
      columns:
        - src: empno # key column on the source emp table
          target: EmployeeNumber
          type: INT
          publishBefore: false
        - src: fname
          target: FirstName
        - src: lname
          target: LastName
        - src: job
          target: Job
        - src: mgr
          target: Manager
          type: INT
        - src: hiredate
          target: HireDate
          type: DATE_TIME
        - src: sal
          target: Salary
          type: DOUBLE
        - src: comm
          target: Commission
          type: DOUBLE
        - src: dept
          target: Department
          type: INT
```

If you don't need any transformation of source columns then you can simply use passThrough option and you don't need to explicitly map each source columns to Redis target data structure.

```yml
schema: dbo # Schema name e.g. dbo. One mapper file per schema and you can have multiple tables in the same mapper file as long as schema is same, otherwise create multiple mapper files e.g. mapper1.xml, mapper2.xml or <table_name>.xml etc. under mappers folder of your config dir.
tables:
  - table: emp # emp table under dbo schema
    mapper:
      id: Test
      processorID: Test
      publishBefore: false # publishBefore - Global setting, that specifies if before values have to be published for all columns. This setting could be overridden at each column level
      passThrough: true # set it to true if you don't need to map individual columns. You always need to have the key column mappings.
      columns:
        - src: empno # key column on the source emp table
          target: empno
          type: INT
          publishBefore: false
```

</p>
</details>

## Start Redis Connect SQL Server Connector
<details><summary>Execute Redis Connect startup script to see all the options</summary>
<p>
    
```bash
redis-connect-sqlserver/bin$ ./redisconnect.sh    
-------------------------------
Redis Connect startup script.
*******************************
Please ensure that the value of REDISCONNECT_CONFIG points to the correct config directory in /home/viragtripathi/redis-connect-sqlserver/bin/redisconnect.conf before executing any of the options below
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
redis-connect-sqlserver/bin$ ./redisconnect.sh stage
```

<h4>Start Redis Connect Job</h4>
<br>Once staging is done, execute the same script with <i>start</i> option to start the configured Job(s) i.e. an instance of Redis Connect.

```bash
redis-connect-sqlserver/bin$ ./redisconnect.sh start
```
