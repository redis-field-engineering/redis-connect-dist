## Setting up Gemfire (Source)

Please see an example under [Demo](demo/setup_gemfire.sh).

**or**

Use your existing VMware Gemfire installation

### Configuring SSL

* Create server keystore e.g. GemfireServer.jks.<p>
````shell
keytool -genkey -alias GemfireServer -keyalg RSA -validity 3650 -keystore "GemfireServer.jks" -storetype JKS -dname "CN=trusted" -keypass password -storepass password
````

* Export server's public certificate. This will be kept in client's truststore for client to authC server.
````shell
keytool -exportcert -alias GemfireServer -keystore GemfireServer.jks -file GemfireServer.cer
````

* Create client keystore e.g. GemfireClient.jks
````shell
keytool -genkey -alias GemfireClient -keyalg RSA -validity 3650 -keystore GemfireClient.jks -storetype JKS -dname "CN=trusted" -keypass password -storepass password
````

* Export client's public certificate. This will be kept in server's truststore for server to authC client.
````shell
keytool -exportcert -alias GemfireClient -keystore GemfireClient.jks -file GemfireClientPublic.cer
````

* Add Server certificate to client trust store
````shell
keytool -importcert -alias GemfireServer -keystore GemfireClient.jks -file GemfireServer.cer
````

* Add client certificate to server truststore
````shell
keytool -importcert -alias GemfireClient -keystore GemfireServer.jks -file GemfireClientPublic.cer
````

#### Create secured (SSL enabled) gemfire cluster

gemfire.properties
````shell
ssl-enabled-components=all
mcast-port=0
locators=localhost[10334]
````

gfsecurity.properties
````shell
ssl-enabled-components=all
ssl-keystore-type=jks
ssl-keystore=/home/virag/gemfire/vmware-gemfire-9.15.1/config/certs/GemfireServer.jks
ssl-keystore-password=password
ssl-truststore=/home/virag/gemfire/vmware-gemfire-9.15.1/config/certs/GemfireServer.jks
ssl-truststore-password=password
````

#### Steps to start secure cluster

* Start locator
````shell
start locator --name=mylocator --properties-file=/path/to/your/gemfire.properties --security-properties-file=/path/to/your/gfsecurity.properties
````

* Start cache-server
````shell
start server --name=myserver --properties-file=/path/to/your/gemfire.properties --security-properties-file=/path/to/your/gfsecurity.properties
````

#### Connecting to ssl secured cluster from gfsh
````shell
connect --locator=localhost[10334] --use-ssl --security-properties-file=/path/to/your/gfsecurity.properties
````

**or**

````shell
~/vmware-gemfire-9.15.1/bin$ ./gfsh
    _________________________     __
   / _____/ ______/ ______/ /____/ /
  / /  __/ /___  /_____  / _____  /
 / /__/ / ____/  _____/ / /    / /
/______/_/      /______/_/    /_/    9.15.1

Monitor and Manage VMware Tanzu GemFire
gfsh>connect --locator=10.142.0.20[10334] --use-ssl
key-store: /home/virag/gemfire/vmware-gemfire-9.15.1/config/certs/GemfireClient.jks
key-store-password: ********
key-store-type(default: JKS):
trust-store: /home/virag/gemfire/vmware-gemfire-9.15.1/config/certs/GemfireClient.jks
trust-store-password: ********
trust-store-type(default: JKS):
ssl-ciphers(default: any):
ssl-protocols(default: any):
ssl-enabled-components(default: all):
Connecting to Locator at [host=10.142.0.20, port=10334] ..
Connecting to Manager at [host=fe-dev.c.central-beach-194106.internal, port=1099] ..
Successfully connected to: [host=fe-dev.c.central-beach-194106.internal, port=1099]

You are connected to a cluster of version: 9.15.1
````

#### Load redis-connect-query Function

Redis Connect depends on the `redis-connect-query` function to perform load jobs. The jar containing this function must be deployed to GemFire prior to starting the load job. You can get this jar either by building the [redis-connect-gemfire-function](https://github.com/redis-field-engineering/redis-connect-gemfire-function?tab=readme-ov-file#building-the-project) project, or simply by using the [gemfire-initial-load-function-0.10.1.jar](/examples/gemfire/demo/gemfire-initial-load-function-0.10.1.jar) file in the `demo` folder. Once you have that file, from a `gfsh` shell connected to your locator, execute the following command.

```sh
deploy --jar=./gemfire-initial-load-function-0.10.1.jar
```

## Setting up Redis Enterprise Databases (Target)

Before using Redis Connect to capture the changes committed on Gemfire into Redis Enterprise Databases, first create a database for the metadata management and metrics provided by Redis Connect by creating a database with [RedisTimeSeries](https://redis.com/modules/redis-timeseries/) module enabled, see [Create Redis Enterprise Database](https://docs.redis.com/latest/rs/administering/creating-databases/#creating-a-new-redis-database) for reference. Then, create (or use an existing) another Redis Enterprise database (Target) to store the changes coming from PostgreSQL. Additionally, you can enable [RediSearch 2.0](https://redis.com/blog/introducing-redisearch-2-0/) module on the target database to enable secondary index with full-text search capabilities on the existing hashes where PostgreSQL changed events are being written at then [create an index, and start querying](https://oss.redis.com/redisearch/Commands/) the document in hashes.

| ℹ️                                               |
|:-------------------------------------------------|
| Docker demo: Follow the [Docker demo](demo)      |
| K8s Setup: Follow the [k8s-docs](../../k8s-docs) |
