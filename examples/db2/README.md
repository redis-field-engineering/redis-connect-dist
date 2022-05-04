# redis-connect-db2

redis-connect-db2 is a Redis Connect connector for intra-day real-time ETL. In this case, Redis Connect is used more as an initial loader, which requires it to partition its consumption of source-side transactional data. For initial load jobs, Redis Connect can spawn child processes, which can in parallel consume partitioned data from the source. The partitioning strategy can be configured to fit the SLA window for the ETL job.


### Minimum Hardware Requirements

* 1GB of RAM
* 4 CPU cores
* 20GB of disk space
* 1G Network
* JRE 11+
