# Prerequisites

Docker compatible [*nix OS](https://en.wikipedia.org/wiki/Unix-like) and Docker installed.
<br>Execute the following commands (copy & paste) to download and setup RedisCDC MSSQL Connector and demo scripts.
i.e.</br>
```bash
wget -c https://github.com/RedisLabs-Field-Engineering/RedisCDC/archive/master.zip && wget https://github.com/RedisLabs-Field-Engineering/RedisCDC/releases/download/v1.0.2/rl-connector-rdb-1.0.2.126.tar.gz && tar -xvf rl-connector-rdb-1.0.2.126.tar.gz && rm rl-connector-rdb-1.0.2.126.tar.gz && unzip -j master.zip "RedisCDC-master/Connectors/mssql/demo/*" -d rl-connector-rdb/demo && rm -rf master.zip RedisCDC-master && cd rl-connector-rdb && chmod a+x demo/*.sh
```

## Setup MSSQL 2017 database in docker (Source)

<br>Execute [setup_mssql.sh](setup_mssql.sh)</br>
```bash
rl-connector-rdb$ cd demo
demo$ ./setup_mssql.sh
```
---
**NOTE**

The above script will start a [MSSQL 2017 docker](https://hub.docker.com/layers/microsoft/mssql-server-linux/2017-latest/images/sha256-314918ddaedfedc0345d3191546d800bd7f28bae180541c9b8b45776d322c8c2?context=explore) instance, create RedisLabsCDC database, enable cdc on the database, create emp table and enable cdc on the table.

---

## Setup Redis Enterprise cluster, databases and RedisInsight in docker (Target)
<br>Execute [create_re-cdc_databases.sh](create_re-cdc_databases.sh)</br>
```bash
demo$ ./create_re-cdc_databases.sh
```
---
**NOTE**

The above script will create a 1-node Redis Enterprise cluster in a docker container, [Create a target database with RediSearch module](https://docs.redislabs.com/latest/modules/add-module-to-database/), [Create a job management and metrics database with RedisTimeSeries module](https://docs.redislabs.com/latest/modules/add-module-to-database/), [Create a RediSearch index for emp Hash](https://redislabs.com/blog/getting-started-with-redisearch-2-0/) and [Start an instance of RedisInsight](https://docs.redislabs.com/latest/ri/installing/install-docker/).

---
