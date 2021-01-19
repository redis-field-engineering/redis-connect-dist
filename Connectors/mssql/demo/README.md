# Prerequisites

Docker compatible [*nix OS](https://en.wikipedia.org/wiki/Unix-like) and Docker installed.
<br>Please have 8 vCPU*, 8GB RAM and 50GB storage for this demo to function properly. Adjust the resources based on your requirements. For HA, at least have 2 RedisCDC instances deployed on separate hosts.</br>
<br>Execute the following commands (copy & paste) to download and setup RedisCDC MSSQL Connector and demo scripts.
i.e.</br>
```bash
wget -c https://github.com/RedisLabs-Field-Engineering/RedisCDC/archive/master.zip && \
wget https://github.com/RedisLabs-Field-Engineering/RedisCDC/releases/download/v1.0.2/rl-connector-rdb-1.0.2.126.tar.gz && \
tar -xvf rl-connector-rdb-1.0.2.126.tar.gz && \
unzip -j master.zip "RedisCDC-master/Connectors/mssql/demo/*" -d rl-connector-rdb/demo && \
rm -rf rl-connector-rdb-1.0.2.126.tar.gz master.zip RedisCDC-master && \
cd rl-connector-rdb && \
chmod a+x demo/*.sh
```
Expected output:
```bash
rl-connector-rdb$ ls
bin	config	demo	lib
```

## Setup MSSQL 2017 database in docker (Source)

<br>Execute [setup_mssql.sh](setup_mssql.sh)</br>
```bash
rl-connector-rdb$ cd demo
demo$ ./setup_mssql.sh
```
Validate MS SQL Server database is running as expected:
```bash
demo$ docker ps -a | grep mssql
62de3e1d01c6        microsoft/mssql-server-linux:2017-latest   "/opt/mssql/bin/sqls…"   2 hours ago         Up 2 hours          0.0.0.0:1433->1433/tcp                                                                                                                                                                                                                                                                                          mssql2017-virag-cdc

demo$ docker exec -it mssql2017-virag-cdc /opt/mssql-tools/bin/sqlcmd -S 127.0.0.1 -U sa -P Redis@123 -y80 -Y 40 -Q 'use RedisLabsCDC;exec sys.sp_cdc_help_change_data_capture;'
Changed database context to 'RedisLabsCDC'.
source_schema                            source_table                             capture_instance                         object_id   source_object_id start_lsn              end_lsn                supports_net_changes has_drop_pending role_name                                index_name                               filegroup_name                           create_date             index_column_list                                                                captured_column_list                                                            
---------------------------------------- ---------------------------------------- ---------------------------------------- ----------- ---------------- ---------------------- ---------------------- -------------------- ---------------- ---------------------------------------- ---------------------------------------- ---------------------------------------- ----------------------- -------------------------------------------------------------------------------- --------------------------------------------------------------------------------
dbo                                      emp                                      cdcauditing_emp                           1269579561       1237579447 0x0000002400000B200060 NULL                                      1             NULL NULL                                     PK__emp__AF4C318ADDC5713D                NULL                                     2021-01-18 16:04:09.857 [empno]                                                                          [empno], [fname], [lname], [job], [mgr], [hiredate], [sal], [comm], [dept]
```
---
**NOTE**

The above script will start a [MSSQL 2017 docker](https://hub.docker.com/layers/microsoft/mssql-server-linux/2017-latest/images/sha256-314918ddaedfedc0345d3191546d800bd7f28bae180541c9b8b45776d322c8c2?context=explore) instance, create RedisLabsCDC database, enable cdc on the database, create emp table and enable cdc on the table.

---

## Setup Redis Enterprise cluster, databases and RedisInsight in docker (Target)
<br>Execute [setup_re.sh](setup_re.sh)</br>
```bash
demo$ ./setup_re.sh
```
Validate Redis databases and RedisInsight is running as expected:
```bash
demo$ docker ps -a | grep redislabs
8c008000ff5c        redislabs/redisinsight:latest              "bash ./docker-entry…"   2 hours ago         Up 2 hours          0.0.0.0:18001->8001/tcp                                                                                                                                                                                                                                                                                         redisinsight
8fe702a340a9        redislabs/redis:latest                     "/opt/start.sh"          2 hours ago         Up 2 hours          53/tcp, 5353/tcp, 8001/tcp, 8080/tcp, 10000-11999/tcp, 12006-19999/tcp, 0.0.0.0:18070->8070/tcp, 0.0.0.0:18443->8443/tcp, 0.0.0.0:19443->9443/tcp, 0.0.0.0:14000->12000/tcp, 0.0.0.0:14001->12001/tcp, 0.0.0.0:14002->12002/tcp, 0.0.0.0:14003->12003/tcp, 0.0.0.0:14004->12004/tcp, 0.0.0.0:14005->12005/tcp   re-node1

demo$ docker exec -it re-node1 bash -c "rladmin status"
CLUSTER NODES:
NODE:ID    ROLE     ADDRESS        EXTERNAL_ADDRESS       HOSTNAME    SHARDS   CORES          FREE_RAM            PROVISIONAL_RAM       VERSION      STATUS  
*node:1    master   172.17.0.5                            re-node1    2/100    16             54.2GB/58.88GB      41.75GB/48.28GB       6.0.12-49    OK      

DATABASES:
DB:ID       NAME                               TYPE   MODULE  STATUS  SHARDS  PLACEMENT  REPLICATION   PERSISTENCE   ENDPOINT                                
db:1        RedisCDC-Target-db                 redis  yes     active  1       dense      disabled      disabled      redis-12000.re-cluster.local:12000      
db:2        RedisCDC-JobConfig-Metrics-db      redis  yes     active  1       dense      disabled      disabled      redis-12001.re-cluster.local:12001      

ENDPOINTS:
DB:ID         NAME                                                                  ID                            NODE            ROLE            SSL        
db:1          RedisCDC-Target-db                                                    endpoint:1:1                  node:1          single          No         
db:2          RedisCDC-JobConfig-Metrics-db                                         endpoint:2:1                  node:1          single          No         

SHARDS:
DB:ID          NAME                                                   ID            NODE         ROLE         SLOTS         USED_MEMORY           STATUS     
db:1           RedisCDC-Target-db                                     redis:1       node:1       master       0-16383       7.58MB                OK         
db:2           RedisCDC-JobConfig-Metrics-db                          redis:2       node:1       master       0-16383       1.93MB                OK
```
---
**NOTE**

The above script will create a 1-node Redis Enterprise cluster in a docker container, [Create a target database with RediSearch module](https://docs.redislabs.com/latest/modules/add-module-to-database/), [Create a job management and metrics database with RedisTimeSeries module](https://docs.redislabs.com/latest/modules/add-module-to-database/), [Create a RediSearch index for emp Hash](https://redislabs.com/blog/getting-started-with-redisearch-2-0/) and [Start an instance of RedisInsight](https://docs.redislabs.com/latest/ri/installing/install-docker/).

---

## Setup RedisCDC

* Update the connection parameters to match with the demo environment. Execute the following commands:
```bash
demo$ sed -i -e '/jobConfigConnection:/{n;s/20504/14001/}' -e '/srcConnection:/{n;s/20505/14000/}' -e '/metricsConnection:/{n;s/20505/14001/}' -e 's/35.185.69.89/127.0.0.1/g' ../config/samples/cdc/env.yml

demo$ cat ../config/samples/cdc/env.yml
```
<details><summary>Expected output:</summary>
<p>

```yml
connections:
  jobConfigConnection:
    redisUrl: redis://127.0.0.1:14001
  srcConnection:
    redisUrl: redis://127.0.0.1:14000
  metricsConnection:
    redisUrl: redis://127.0.0.1:14001
  msSQLServerConnection:
    database:
      name: testdb #database name
      db: RedisLabsCDC #database
      hostname: 127.0.0.1
      port: 1433
      username: sa
      password: Redis@123
      type: mssqlserver #this value has cannot be changed for mssqlserver
      jdbcUrl: "jdbc:sqlserver://127.0.0.1:1433;database=RedisLabsCDC"
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

* Execute RedisCDC job and see all the options

```bash
demo$ docker run \
-it --rm \
--name rl-connector-rdb \
-e LOGBACK_CONFIG=/opt/redislabs/rl-connector-rdb/config/logback.xml \
-e JAVA_OPTIONS="-Xms256m -Xmx512m -Divoyant.cdc.configLocation=/opt/redislabs/rl-connector-rdb/config/samples/cdc" \
-v $(pwd)/../config:/opt/redislabs/rl-connector-rdb/config \
--net host \
virag/rl-connector-rdb
```
<details><summary>Expected output:</summary>
<p>

```bash
-------------------------------
RedisCDC startup script.

Usage: [-h|-v|cleansetup_cdc|cleansetup_loader|start_cdc|start_cdc_true|start_loader|start_loader_true]
options:
-h: Print this help message and exit.
-v: Print version information and exit.
cleansetup_cdc: cleanup and seed redis database with cdc job configurations.
cleansetup_loader: cleanup and seed redis database with initial loader job configurations.
start_cdc: start cdc connector process without job management.
start_cdc_true: start cdc connector process with job management.
start_loader: start initial loader process without job management.
start_loader_true: start initial loader process with job management.
-------------------------------
```
</p>
</details>

* Seed Config Data
<p>Before starting a RedisCDC instance, job config data needs to be seeded into Redis Config database from a Job Configuration file. This step will delete existing configs from Redis job config database and reload them from Setup.yml, see sample rl-connector-rdb/config/samples/cdc/Setup.yml configuration file for reference.</p>

```bash
demo$ docker run \
-it --rm \
--name rl-connector-rdb \
-e LOGBACK_CONFIG=/opt/redislabs/rl-connector-rdb/config/logback.xml \
-e JAVA_OPTIONS="-Xms256m -Xmx512m -Divoyant.cdc.configLocation=/opt/redislabs/rl-connector-rdb/config/samples/cdc" \
-v $(pwd)/../config:/opt/redislabs/rl-connector-rdb/config \
--net host \
virag/rl-connector-rdb \
cleansetup_cdc
```

* Start RedisCDC 
<p>Execute with start_cdc_true parameter to start a RedisCDC instance with job management enabled.</p>

```bash
demo$ docker run \
-d -it --rm \
--name rl-connector-rdb \
-e LOGBACK_CONFIG=/opt/redislabs/rl-connector-rdb/config/logback.xml \
-e JAVA_OPTIONS="-Xms256m -Xmx512m -Divoyant.cdc.configLocation=/opt/redislabs/rl-connector-rdb/config/samples/cdc" \
-v $(pwd)/../config:/opt/redislabs/rl-connector-rdb/config \
--net host \
virag/rl-connector-rdb \
start_cdc_true
```
Validate RedisCDC instance is running as expected:
```bash
demo$ docker container top rl-connector-rdb -aef | grep java
root                10410               10408               9                   01:16               pts/0               00:00:03            java -Xms256m -Xmx512m -Divoyant.cdc.configLocation=/opt/redislabs/rl-connector-rdb/config/samples/cdc -Divoyant.cdc.jobManagement.enabled=true -Dlogback.configurationFile=/opt/redislabs/rl-connector-rdb/config/logback.xml -XX:+UseParallelGC -XX:GCTimeRatio=4 -XX:AdaptiveSizePolicyWeight=90 -XX:MinHeapFreeRatio=20 -XX:MaxHeapFreeRatio=40 -XX:+ExitOnOutOfMemoryError -cp .:/opt/redislabs/rl-connector-rdb/bin/../lib/*:/opt/redislabs/rl-connector-rdb/bin/* com.ivoyant.cdc.CDCMain
```
