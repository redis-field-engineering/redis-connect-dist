<p align="center"><img src="/images/Redis_Connect_Intro.JPG" alt="Redis Connect" width = 650px height = 200px></p>

**Redis Connect** :rocket: is a distributed platform that enables real-time event streaming, transformation, and enrichment of changed-data events from heterogeneous data platforms to the various data models supported by Redis Enterprise.
<br><br> :white_check_mark: No Code :white_check_mark: Seamless Integration :white_check_mark: Multi-Tenancy :white_check_mark: Linear-Scalability :white_check_mark: High-Availability :white_check_mark: Support
<br><br>
<p align="center"><img src="/images/Redis_Connect_Source_Sink.JPG" alt="Redis Connect Source and Sinks" width = 750px height = 350px"></p>

**Demo** -> https://redis.com/webinars/rapid-data-ingestion-with-redis-enterprise/)

<table cellspacing="0" cellpadding="0">
    <tr>
        <td> <b>Cloud-Native Architecture</b> <br><br> Redis Connect has a cloud-native and shared-nothing architecture which allows any node to operate stand-alone or as a cluster member. Its platform-agnostic and lightweight design requires minimal infrastructure and avoids complex dependencies on 3rd-party platforms. All you need is Redis Enterprise.</td>
        <td width="50%"><img src="/images/Redis_Connect_Architecture.png" style="float: right;" width="500" height="250"/></td>
    </tr>
    <tr>
        <td width="50%"><img src="/images/Redis_Insight.png" style="float: right;" width="500" height="200"/></td> 
        <td> <b>Multi-Tenancy | Linear Scalability</b> <br><br> Redis Connect can manage multi-tenant data replication pipelines (jobs) end-to-end within a single cluster node. Jobs support a variety of different source databases which can be collocated without becoming noisy neighbors. Streaming and initial load jobs can be partitioned for linear scalability across a single or multiple cluster node(s).</td>
    </tr>
    <tr>
        <td> <b>High-Availability | Recovery</b> <br><br> Redis Connect jobs update their checkpoint for each committed changed-data event. In the occurrence of node failure, or network split, a job would failover to another node and seamlessly begin replication from the last committed checkpoint. Data would not be lost, and order would be maintained. It is supported on Kubernetes environments including OpenShift.</td>
        <td width="50%"><img src="/images/Redis_Connect_Cluster.png" style="float: right;" width="500" height="200"/></td>
    </tr>
    <tr>
        <td width="50%"><img src="/images/Redis_Connect_Pipeline.png" style="float: right;" width="500" height="150"/></td>
        <td> <b>Custom Transformations</b> <br><br> Redis Connect Jobs support user-defined business logic simply by adding a JAR to the /extlib directory. Users can create custom workflows that include user-defined stages for proprietary business rules, custom transformations, de-tokenization, and more. Users can also extend the supported list of Target Sinks.</td> 
    </tr>
    <tr>
        <td> <b>REST API | CLI | Swagger UI</b> <br><br> Redis Connect is entirely data-driven and relies on Redis Enterprise as its metadata store. Users can configure, start, stop, migrate, and restart jobs via its built-in REST API and/or interactive CLI. Redis Connect also exposes a swagger UI to simplify the user and administration experience.</td>
        <td width="50%"><img src="/images/Redis_Connect_Swagger_UI.png" style="float: right;" width="500" height="200"/></td>
    </tr>
    <tr>
        <td width="50%"><img src="/images/Redis_Enterprise_ACL.png" style="float: right;" width="500" height="200"/></td>
        <td> <b>Enterprise-Grade Security</b> <br><br> Redis Connect jobs are stateless so changed-data events are always in-transit. Redis Connect benefits from Redis Enterprise’s enterprise-grade security capabilities including RBAC, TLS, and more. Credentials, secrets, and trust-store passwords are never persisted however can be dynamically rotated with minimal disruption to the replication pipeline. Vault integration is supported.</td>
    </tr>
</table>

## Download and Setup

---
### Minimum Production Hardware Requirements

* 1GB of RAM
* 4 CPU cores
* 20GB of disk space
* 1G Network

### Runtime Requirements

* JRE 11+ e.g. [Azul OpenJDK](https://www.azul.com/downloads/?package=jdk#download-openjdk)
---

Download the [latest release](https://github.com/redis-field-engineering/redis-connect-dist/releases) and un-tar redis-connect-`<version>.<build>`.tar.gz archive.

All the contents would be extracted under redis-connect directory

Contents of redis-connect directory
<br>• bin – contains startup script files
<br>• lib – contains java libraries
<br>• config – contains jobmanager.properties, credentials files and job payload samples
<br>• extlib – directory to copy any external dependencies such as [custom stage](https://github.com/redis-field-engineering/redis-connect-custom-stage-demo), source drivers etc.
