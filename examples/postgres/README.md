## Setting up PostgreSQL (Source)

Please see <a href="https://debezium.io/documentation/reference/stable/connectors/postgresql.html#setting-up-postgresql" target="_blank">PostgreSQL Setup</a> for reference.

Please see an example under [Demo](demo/setup_postgres.sh).

## Setting up Redis Enterprise Databases (Target)

Before using the PostgreSQL connector (redis-connect) to capture the changes committed on PostgreSQL into Redis Enterprise Databases, first create a database for the metadata management and metrics provided by Redis Connect by creating a database with [RedisTimeSeries](https://redis.com/modules/redis-timeseries/) module enabled, see [Create Redis Enterprise Database](https://docs.redis.com/latest/rs/administering/creating-databases/#creating-a-new-redis-database) for reference. Then, create (or use an existing) another Redis Enterprise database (Target) to store the changes coming from PostgreSQL. Additionally, you can enable [RediSearch 2.0](https://redis.com/blog/introducing-redisearch-2-0/) module on the target database to enable secondary index with full-text search capabilities on the existing hashes where PostgreSQL changed events are being written at then [create an index, and start querying](https://oss.redis.com/redisearch/Commands/) the document in hashes.

## Start Redis Connect
<details><summary>Execute Redis Connect startup script to see all the options</summary>
<p>

```bash
redis-connect-postgres/bin$ ./redisconnect.sh    
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

</p>
</details>

```bash
redis-connect-postgres/bin$ ./redisconnect.sh start
```

| ℹ️                                          |
|:--------------------------------------------|
| Docker demo: Follow the [Docker demo](demo) |
| K8s Setup: Follow the [k8s-docs](k8s-docs)  |
