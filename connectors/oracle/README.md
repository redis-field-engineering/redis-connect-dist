# redis-connect-oracle

redis-connect-oracle is a Redis Connect connector for capturing changes (INSERT, UPDATE and DELETE) from Oracle Database (source) and writing them to a Redis Enterprise database (Target). The connector uses [Oracle LogMiner](https://docs.oracle.com/cd/B19306_01/server.102/b14215/logminer.htm#i1010243) to read the database redo log.

<p>
The first time redis-connect-oracle connects to a Oracle database, it reads a consistent snapshot of all of the schemas.
When that snapshot is complete, the connector continuously streams the changes that were committed to Oracle and generates a corresponding insert, update or delete event.
All of the events for each tables are recorded in a separate Redis data structure or module of your choice, where they can be easily consumed by applications and services.

| ℹ️ |
|:---------------------------|
| Quick Start: Follow the [demo](demo)|
| K8s Setup: Follow the [k8s-docs](k8s-docs)|

<h3 class="section" id="compatibility">:rocket: Tested Versions</h3>
<table class="releases-compatibility">
    <tbody>
        <tr>
            <td>Java</td>
            <td>11+</td>
        </tr>
        <tr>
            <td>Redis Connect</td>
            <td>0.8.x</td> 
        </tr> 
        <tr>
            <td>Oracle</td>
            <td>
                <span class="test-with-subcategory"> Database: </span> 12c, 19c (currently only supported for initial load / batch / snapshots) <br/> 
                <span class="test-with-subcategory"> JDBC Driver: </span> 12.2.0.1, 19.8.0.0, 21.1.0.0 <br/>
            </td>
        </tr>
    </tbody>
</table>