## Setting up SQL Server (Source)

Please see <a href="https://debezium.io/documentation/reference/stable/connectors/sqlserver.html#setting-up-sqlserver" target="_blank">SQL Server Setup</a> for reference.

Please see an example under [Demo](demo/setup_mssql.sh).

## Setting up Redis Enterprise Databases (Target)

Before using the SQL Server connector to capture the changes committed on SQL Server into Redis Enterprise Database, first create a database for the metadata management and metrics provided by Redis Connect by creating a database with [RedisTimeSeries](https://redislabs.com/modules/redis-timeseries/) module enabled, see [Create Redis Enterprise Database](https://docs.redislabs.com/latest/rs/administering/creating-databases/#creating-a-new-redis-database) for reference. Then, create (or use an existing) another Redis Enterprise database (Target) to store the changes coming from SQL Server. Additionally, you can enable [RediSearch 2.0](https://redislabs.com/blog/introducing-redisearch-2-0/) module on the target database to enable secondary index with full-text search capabilities on the existing hashes where SQL Server changed events are being written at then [create an index, and start querying](https://oss.redislabs.com/redisearch/Commands/) the document in hashes.

| ℹ️                                          |
|:--------------------------------------------|
| Docker demo: Follow the [Docker demo](demo) |
| K8s Setup: Follow the [k8s-docs](k8s-docs)  |