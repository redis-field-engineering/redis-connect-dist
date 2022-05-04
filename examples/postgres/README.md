## Setting up PostgreSQL (Source)

Please see <a href="https://debezium.io/documentation/reference/stable/connectors/postgresql.html#setting-up-postgresql" target="_blank">PostgreSQL Setup</a> for reference.

Please see an example under [Demo](demo/setup_postgres.sh).

## Setting up Redis Enterprise Databases (Target)

Before using the PostgreSQL connector (redis-connect-postgres) to capture the changes committed on PostgreSQL into Redis Enterprise Database, first create a database for the metadata management and metrics provided by Redis Connect by creating a database with [RedisTimeSeries](https://redis.com/modules/redis-timeseries/) module enabled, see [Create Redis Enterprise Database](https://docs.redis.com/latest/rs/administering/creating-databases/#creating-a-new-redis-database) for reference. Then, create (or use an existing) another Redis Enterprise database (Target) to store the changes coming from PostgreSQL. Additionally, you can enable [RediSearch 2.0](https://redis.com/blog/introducing-redisearch-2-0/) module on the target database to enable secondary index with full-text search capabilities on the existing hashes where PostgreSQL changed events are being written at then [create an index, and start querying](https://oss.redis.com/redisearch/Commands/) the document in hashes.

## Download and Setup

---

### Minimum Hardware Requirements

* 1GB of RAM
* 4 CPU cores
* 20GB of disk space
* 1G Network

### Runtime Requirements

* JRE 11+
* PostgreSQL 10+ (see [Debezium's doc](https://debezium.io/documentation/reference/stable/connectors/postgresql.html#postgresql-pgoutput) or an example [here](https://github.com/redis-field-engineering/redis-connect-dist/blob/main/connectors/postgres/demo/setup_postgres.sh))

**NOTE**

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

Copy the _sample_ directory and it's contents i.e. _yml_ files, _mappers_ and templates folder under _config_ directory to the name of your choice e.g. `redis-connect-postgres$ cp -R config/samples/postgres config/<project_name>` or reuse sample folder as is and edit/update the configuration values according to your setup.

#### Configuration files

<details><summary>Configure logback.xml [OPTIONAL]</summary>
<p>

#### logging configuration file.

### Sample logback.xml under redis-connect-postgres/config folder

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

<details><summary>Configure env.yml [MANDATORY]</summary>
<p>

#### Environment configuration file with source and target connection information.

Redis URI syntax is described [here](https://github.com/lettuce-io/lettuce-core/wiki/Redis-URI-and-connection-details#uri-syntax).

### Sample env.yml under redis-connect-postgres/config/samples/[postgres|loader] folder. Any of these fields (values) can be replaced by environment variables.
| :memo:        |
|---------------|
If you encounter <a href="https://debezium.io/documentation/reference/stable/connectors/postgresql.html#postgresql-wal-disk-space" target="_blank">WAL disk space consumption</a> issue with Postgres then <a href="https://github.com/redis-field-engineering/redis-connect-dist/blob/main/connectors/postgres/demo/postgres_cdc.sql#L18-L20" target="_blank">Create a heartbeat table</a> and uncomment the `heartbeat.interval.ms` and `heartbeat.action.query` properties below.

```yml
connections:
  - id: jobManagerConnection #Redis Connect Job Metadata connection
    type: Redis
    url: redis://127.0.0.1:14001 #this is based on lettuce uri syntax
    jobmanager.username: ${REDISCONNECT_JOBMANAGER_USERNAME} #this can be overridden by an env variable or a property file
    jobmanager.password: ${REDISCONNECT_JOBMANAGER_PASSWORD} #this can be overridden by an env variable or a property file
    #credentials.file.path: <path to <redisconnect_credentials_jobmanager_<job_name> e.g. /var/secrets/jobmanager> when username and password are not provided here
  - id: targetConnection #target Redis connection
    type: Redis
    url: redis://127.0.0.1:14000 #this is based on lettuce uri syntax
    target.username: ${REDISCONNECT_TARGET_USERNAME} #this can be overridden by an env variable or a property file
    target.password: ${REDISCONNECT_TARGET_PASSWORD} #this can be overridden by an env variable or a property file
    #credentials.file.path: <path to <redisconnect_credentials_redis_<job_name> e.g. /var/secrets/redis> when username and password are not provided here
  - id: RDBConnection
    type: RDB
    name: RedisConnect #database pool name
    database: RedisConnect #database
    url: "jdbc:postgresql://127.0.0.1:5432/RedisConnect" #this is jdbc client driver specific, and it can contain any supported parameters
    host: 127.0.0.1
    port: 5432
    source.username: ${REDISCONNECT_SOURCE_USERNAME} #this can be overridden by an env variable or a property file
    source.password: ${REDISCONNECT_SOURCE_PASSWORD} #this can be overridden by an env variable or a property file
    #credentials.file.path: <path to <redisconnect_credentials_postgresql_<job_name> e.g. /var/secrets/postgresql> when username and password are not provided here
    #heartbeat.interval.ms: 10000 #Workaround for AWS RDS PG WAL space issue
    #heartbeat.action.query: "INSERT INTO heartbeat (id, ts) VALUES (1, NOW()) ON CONFLICT(id) DO UPDATE SET ts=EXCLUDED.ts;" #Workaround for AWS RDS PG WAL space issue    
```

</p>
</details>

<details><summary>Configure Setup.yml [MANDATORY]</summary>
<p>

#### Environment level configurations.

### Sample Setup.yml under redis-connect-postgres/config/samples/postgres folder

```yml
connectionId: jobManagerConnection
job:
  #metrics:
    #connectionId: metricsConnection
    #retentionInHours: 12
    #keys:
      #- key: "public:emp:C:Throughput"
        #retentionInHours: 4
        #labels:
          #schema: public
          #table: emp
          #op: C
      #- key: "public:emp:U:Throughput"
        #retentionInHours: 4
        #labels:
          #schema: public
          #table: emp
          #op: U
      #- key: "public:emp:D:Throughput"
        #retentionInHours: 4
        #labels:
          #schema: public
          #table: emp
          #op: D
      #- key: "public:emp:Latency"
        #retentionInHours: 4
        #labels:
          #schema: public
          #table: emp
  jobConfig:
    - name: postgres-job
      config: JobConfig.yml
      variables:
        database: RedisConnect
        sourceValueTranslator: SOURCE_RECORD_TO_OP_TRANSLATOR
```

</p>
</details>

<details><summary>Configure JobManager.yml [OPTIONAL]</summary>
<p>

#### Configuration for Job Reaper and Job Claimer processes.

### Sample JobManager.yml under redis-connect-postgres/config/samples/postgres folder

```yml
connectionId: jobManagerConnection
#metricsReporter:
  #- REDIS_TS_METRICS_REPORTER
```

</p>
</details>

<details><summary>Configure JobConfig.yml [MANDATORY]</summary>
<p>

#### Job level details. Please see [writers](../../docs/writers.md) for other write stage usages.

### Sample JobConfig.yml under redis-connect-postgres/config/samples/postgres folder

You can have one or more JobConfig.yml (or with any name e.g. JobConfig-<table_name>.yml) and specify them in the Setup.yml under jobConfig: tag. If specifying more than one table (as below) then make sure maxNumberOfJobs: tag under JobManager.yml is set accordingly e.g. if maxNumberOfJobs: tag is set to 2 then Redis Connect will start 2 cdc jobs under the same JVM instance. If the workload is more and you want to spread out (scale) the cdc jobs then create multiple JobConfig's and specify them in the Setup.yml under jobConfig: tag.

```yml
jobId: ${jobId}
producerConfig:
  producerId: RDB_EVENT_PRODUCER
  connectionId: RDBConnection
  tables:
    - public.emp #schema.table
  metricsEnabled: false
pipelineConfig:
  eventTranslator: "${sourceValueTranslator}"
  checkpointConfig:
    providerId: RDB_SQL_CHECKPOINT_READER
    connectionId: targetConnection
    checkpoint: "${jobId}-${database}"
    rdbType: "postgres"
  stages:
    HashWriteStage:
      handlerId: REDIS_HASH_WRITER
      connectionId: targetConnection
      metricsEnabled: false
      prependTableNameToKeys: true
      deleteOnKeyUpdate: true
      async: true
    CheckpointStage:
      handlerId: REDIS_HASH_CHECKPOINT_WRITER
      connectionId: targetConnection
      metricEnabled: false
      async: true
      checkpoint: "${jobId}-${database}"
```

</p>
</details>

<details><summary>Configure mapper.yml [MANDATORY]</summary>
<p>

#### mapper configuration file.

### Sample mapper.yml under redis-connect-postgres/config/samples/postgres/mappers folder

```yml
schema: public
tables:
  - table: emp
    mapper:
      id: Test # mapper Id
      processorID: Test # processor ID for the mapper
      publishBefore: false # false (default) Global setting, that specifies if before values have to be published for all columns - This setting could be overridden at each column level
      passThrough: false # false (default) If this is set to true, all the Columns will be in the output without individual mappings. You still need to map the PK column.
      columns:
        - src: empno
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
          type: DATE
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
schema: public # Schema name e.g. dbo. One mapper file per schema and you can have multiple tables in the same mapper file as long as schema is same, otherwise create multiple mapper files e.g. mapper1.xml, mapper2.xml or <table_name>.xml etc. under mappers folder of your config dir.
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

## Start Redis Connect PostgreSQL Connector
<details><summary>Execute Redis Connect startup script to see all the options</summary>
<p>

```bash
redis-connect-postgres/bin$ ./redisconnect.sh    
-------------------------------
Redis Connect startup script.
*******************************
Please ensure that the value of REDISCONNECT_CONFIG points to the correct config directory in /home/viragtripathi/redis-connect-postgres/bin/redisconnect.conf before executing any of the options below
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
redis-connect-postgres/bin$ ./redisconnect.sh stage
```

<h4>Start Redis Connect Job</h4>
Once staging is done, execute the same script with <i>start</i> option to start the configured Job(s) i.e. an instance of Redis Connect.

```bash
redis-connect-postgres/bin$ ./redisconnect.sh start
```

| ℹ️                                         |
|:-------------------------------------------|
| Quick Start: Follow the [demo](demo)       |
| K8s Setup: Follow the [k8s-docs](k8s-docs) |
