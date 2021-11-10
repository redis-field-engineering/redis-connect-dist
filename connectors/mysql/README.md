# redis-connect-mysql

redis-connect-mysql is a Redis Connect connector for capturing changes (INSERT, UPDATE and DELETE) from MySQL (source) and writing them to a Redis Enterprise database (Target). redis-connect-mysql cdc connector implementation is based on [Debezium](https://debezium.io/documentation/reference/stable/connectors/mysql.html), which is an open source distributed platform for change data capture.

<p>
The first time redis-connect-mysql connects to a MySQL database, it reads a consistent snapshot of all of the schemas.
When that snapshot is complete, the connector continuously streams the changes that were committed to MySQL and generates a corresponding insert, update or delete event.
All of the events for each tables are recorded in a separate Redis data structure or module of your choice, where they can be easily consumed by applications and services.
