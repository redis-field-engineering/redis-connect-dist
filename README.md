# RedisCDC (Redis Enterprise Changed Data Capture)

## Technical Overview

Redis Enterprise Changed Data Capture (“RedisCDC”) is a distributed platform that enables near real-time replication and transformation (data pipelines) of row-level changed-data events (Create, Update, Delete operations) from heterogeneous platforms to Redis Enterprise databases/modules. RedisCDC Jobs migrate source-database operations in the same time-order they were committed using event-driven workflows. It has a modular, extendable, and configurable architecture which provides the flexibility to deploy in a variety of topologies and cover multiple use-cases.

RedisCDC can also perform the function of event-sourcing, acting as both the message broker and event-store, so time-ordered history of changed-data events are captured for auditing and/or replay purposes. In the occurrence of target-database downtime, changed-data events will not be lost but instead resume replication, upon recovery, from the last committed checkpoint.

RedisCDC has a cloud-native shared-nothing architecture which allows any cluster node (RedisCDC Instance) to perform either/both Job Management and Job Execution functions. It is implemented and compiled in JAVA, which deploys on a platform-independent JVM, allowing RedisCDC instances to be agnostic of the underlying operating system (Linux, Windows, Docker Containers, etc.) Its lightweight design and minimal use of infrastructure-resources avoids complex dependencies on other distributed platforms such as Kafka and ZooKeeper. In fact, most uses of RedisCDC will only require the deployment of a few JVMs to handle Job Execution with high-availability.

Integration with source and target databases is handled by an extendable connector framework. Each RedisCDC Connector uniquely interfaces with its source database’s supported and built-in change data capture process. While there are multiple patterns to implement change data capture (polling-publisher, dual-writes, transaction-log tailing, etc.), RedisCDC connectors prioritize integration with source-database transaction-logs (when supported) to avoid impacting performance and availability.
