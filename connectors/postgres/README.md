# redis-connect-postgres

redis-connect-postgres is a Redis Connect connector for capturing changes (INSERT, UPDATE and DELETE) from PostgreSQL (source) and writing them to a Redis Enterprise database (Target). redis-connect-postgres implementation is based on [Debezium](https://debezium.io/documentation/reference/stable/connectors/postgresql.html), which is an open source distributed platform for change data capture.

<p>
The first time redis-connect-postgres connects to a PostgreSQL database, it reads a consistent snapshot of all of the schemas.
When that snapshot is complete, the connector continuously streams the changes that were committed to PostgreSQL and generates a corresponding insert, update or delete event.
All of the events for each tables are recorded in a separate Redis data structure or module of your choice, where they can be easily consumed by applications and services.

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