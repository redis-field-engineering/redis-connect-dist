<p align="left"><img src="/images/Redis_Connect_Intro.JPG" alt="Redis Connect" width = 1000px height = 300px></p>

# Redis Connect <br> _Event Streaming and Change Data Capture_ :rocket:
Redis Connect is a distributed platform that enables real-time event streaming, transformation, and enrichment of changed-data events from heterogeneous data platforms to the various data models supported by Redis Enterprise.
<br> :white_check_mark: No Code :white_check_mark: Seamless Integration :white_check_mark: Multi-Tenancy :white_check_mark: Linear-Scalability :white_check_mark: High-Availability :white_check_mark: Enterprise Support
<p align="left"><img src="/images/Redis_Connect_Source_Sink.JPG" alt="Redis Connect Source and Sinks" width = 1000px height = 750px"></p>

## Table of contents
- [Capabilities](#capabilities)
- [Download and Setup](#download-and-setup)
- [Quick Start](/examples)
- [Demo](https://redis.com/webinars/rapid-data-ingestion-with-redis-enterprise/)

##  Capability Highlights

<table style="width:100%">
    <tr>
        <td style="width:40%"> **Cloud-Native Architecture** <br> Redis Connect has a cloud-native and shared-nothing architecture which allows any node to operate stand-alone or as a cluster member. Its platform-agnostic and lightweight design requires minimal infrastructure and avoids complex dependencies on 3rd-party platforms. All you need is Redis Enterprise.</td>
        <td style="width:60%"> <img src="/images/Redis_Enterprise_Architecture.png" width = 500px height = 250px align="center" ></td>
    </tr>
    <tr>
        <td style="width:60%"> <img src="/images/Redis_Insight.png" width = 500px height = 250px ></td>
        <td style="width:40%"> **Multi-Tenancy | Linear Scalability** <br> Redis Connect can manage multi-tenant data replication pipelines (jobs) end-to-end within a single cluster node. Jobs support a variety of different source databases which can be collocated without becoming noisy neighbors. For linear scalability, streaming and initial load jobs can be partitioned across a single or multiple cluster node(s).</td>
    </tr>
    <tr>
        <td style="width:40%"> **High-Availability | Recovery** <br> Redis Connect jobs update their checkpoint for each committed changed-data event. In the occurrence of node failure, or network split, a job would failover to another node and seamlessly begin replication from the last committed checkpoint. Data would not be lost, and order would be maintained.</td>
        <td style="width:60%"> <img src="/images/HA.png" width = 500px height = 250px ></td>
    </tr>
    <tr>
        <td style="width:60%"> <img src="/images/Workflow.png" width = 500px height = 250px ></td>
        <td style="width:40%"> **Custom Transformations** <br> Redis Connect Jobs support user-defined business logic simply by adding a JAR to the /extlib directory. Users can create custom workflows that include user-defined stages for proprietary business rules, custom transformations, de-tokenization, and more. Users can also extend the supported list of Target Sinks.</td> 
    </tr>
    <tr>
        <td style="width:40%"> **REST API | CLI | Swagger UI** <br> Redis Connect is entirely data-driven and relies on Redis Enterprise as its metadata store. Users can configure, start, stop, migrate, and restart jobs via its built-in REST API and/or interactive CLI. Redis Connect also exposes a swagger UI to simplify the user and administration experience.</td>
        <td style="width:60%"> <img src="/images/Redis_Connect_Swagger_UI.png" width = 500px height = 250px ></td>
    </tr>
    <tr>
        <td style="width:60%"> <img src="/images/ACL.png" width = 500px height = 250px ></td>
        <td style="width:40%"> **Enterprise-Grade Security** <br> Redis Connect jobs are stateless and therefore always execute changed-data events in-transit. Redis Connect benefits from Redis Enterprise’s enterprise-grade security capabilities including RBAC, TLS, and more. Credentials, secrets, and trust-store passwords are never persisted in Redis Connect and can be dynamically rotated including integration with HashiCorp Vault. </td>
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
