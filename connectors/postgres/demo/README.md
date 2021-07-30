# Prerequisites
TBD

## Setup PostgreSQL 10+ database (Source)

<b>_PostgreSQL on Docker_</b>
<br>Execute [setup_postgres.sh](setup_postgres.sh)</br>
```bash
$ ./setup_postgres.sh 12.5 (or latest or any supported 10+ version)
```
<b>_PostgreSQL on Amazon RDS_</b>
* Set the instance parameter `rds.logical_replication` to `1`.
* Verify that the `wal_level` parameter is set to `logical` by running the query `SHOW wal_level` as the database RDS master user.
  This might not be the case in multi-zone replication setups.
  You cannot set this option manually.
  It is [automatically changed](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_WorkingWithParamGroups.html) when the `rds.logical_replication` parameter is set to `1`.
  If the `wal_level` is not set to `logical` after you make the preceding change, it is probably because the instance has to be restarted after the parameter group change.
  Restarts occur during your maintenance window, or you can initiate a restart manually.
* Initiate logical replication from an AWS account that has the `rds_replication` role.
  The role grants permissions to manage logical slots and to stream data using logical slots.
  By default, only the master user account on AWS has the `rds_replication` role on Amazon RDS.
  To enable a user account other than the master account to initiate logical replication, you must grant the account the `rds_replication` role.
  For example, `grant rds_replication to _<my_user>_`. You must have `superuser` access to grant the `rds_replication` role to a user.
  To enable accounts other than the master account to create an initial snapshot, you must grant `SELECT` permission to the accounts on the tables to be captured.
  For more information about security for PostgreSQL logical replication, see the [PostgreSQL documentation](https://www.postgresql.org/docs/current/logical-replication-security.html).


## Start Redis Connect Postgres Connector

```bash
docker run \
-it --rm --privileged=true \
--name redis-connect-postgres \
-e LOGBACK_CONFIG=/opt/redislabs/redis-connect-postgres/config/logback.xml \
-e REDIS_CONNECT_CONFIG=/opt/redislabs/redis-connect-postgres/config/samples/postgres \
-e REST_API_ENABLED=true \
-e REST_API_PORT=8282 \
-e REDISCONNECT_SOURCE_PASSWORD=Redis@123 \
-e JAVA_OPTIONS="-Xms256m -Xmx1g" \
-v $(pwd)/../config:/opt/redislabs/redis-connect-postgres/config \
-p 8282:8282 \
redislabs/redis-connect-postgres:pre-release-alpine
-------------------------------
Redis Connect Connector wrapper script for Docker containers.

Usage: [-h|-v|start_cli|stage_cdc|stage_loader|start_cdc|start_loader]
options:
-h: Print this help message and exit.
-v: Print version information and exit.
start_cli: starts redis-connect-cli.
stage_cdc: clean and stage redis database with cdc job configurations.
stage_loader: clean and stage redis database with initial loader job configurations.
start_cdc: start Redis Connect connector instance.
start_loader: start Redis Connect initial loader instance.
-------------------------------
```
