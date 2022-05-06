<p align="center"><img src="/images/Redis_Connect_Intro.JPG" alt="Redis Connect" width = 750px height = 200px></p>

**Redis Connect** :rocket: is a distributed platform that enables real-time event streaming, transformation, and enrichment of changed-data events from heterogeneous data platforms to the various data models supported by Redis Enterprise.
<br><br> :white_check_mark: No Code :white_check_mark: Seamless Integration :white_check_mark: Multi-Tenant :white_check_mark: Linear-Scalability :white_check_mark: High-Availability :white_check_mark: Support
<br><br>
<p align="center"><img src="/images/Redis_Connect_Source_Sink.JPG" alt="Redis Connect Source and Sinks" width = 750px height = 350px"></p>

**Demo** -> https://redis.com/webinars/rapid-data-ingestion-with-redis-enterprise/)

##  Highlights
<table style="width:100%">
    <tr>
        <td> <b>Cloud-Native Architecture</b> <br> Redis Connect has a cloud-native and shared-nothing architecture which allows any node to operate stand-alone or as a cluster member. Its platform-agnostic and lightweight design requires minimal infrastructure and avoids complex dependencies on 3rd-party platforms. All you need is Redis Enterprise.</td>
        <td style="width:50%"> <img src="/images/Redis_Enterprise_Architecture.png" width=400 height=200 align="center" ></td>
    </tr>
</table>

<td width="33%">
    <span style="float: left;">Support the efforts of companies that are enrolled in the Non-GMO Project Verification</span>
    <img src="/images/Redis_Enterprise_Architecture.png" style="float: right;" width="300" height="200"/>
</td>


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
