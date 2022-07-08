# redisEnterpriseVault - Redis Enterprise integrated with Hashicorp Vault to migrate data from postgresql using redis connect

## Purpose

Describe steps to deploy redis-connect inside kubernetes and (optionally) Hashicorp Vault

&nbsp;

## Outline

- [Overview](#overview)
- [Important Links](#important-links)
- [Technical Overview](#technical-overview)
- [Instructions](#instructions)
  - [Verify k8s cluster](#verify-kubernetes-cluster)
  - [Verify Redis Enterprise](#verify-redis-enterprise)
  - [Verify Source Database](#verify-source-database)
  - [Vault](#vault)
  - [Redis Connect](#redis-connect-configuration)
    - [Redis Connect with Vault](#redis-connect-with-vault)
    - [Redis Connect without Vault](#redis-connect-without-vault)
- [Debug Ideas](#debug-ideas)
  
&nbsp;

## Overview
Ensure proper environment exists for running redis connect inside kubernetes and (optionally) Hashicorp Vault.  Inside this
environment, add redis connect and configure a simple replication.
![Solution Diagram](../images/deployments/Postgres%20K8s%20HashiCorp%20Vault%20Deployment.png)
Note:   Need a metadata and a target redis enterprise database connection.  These can be the same database if desired.

## Important Links

* [Set up vault on GKE](https://learn.hashicorp.com/tutorials/vault/kubernetes-google-cloud-gke)
* [Redis Connect Tips](https://github.com/Redislabs-Solution-Architects/redis-connect-k8s-helpers)
* [Redis Enterprise k8s](https://github.com/RedisLabs/redis-enterprise-k8s-docs)
* [Hashicorp Vault plugin on Redis Enterprise k8s](https://github.com/RedisLabs/vault-plugin-database-redis-enterprise/blob/main/docs/guides/using-the-plugin-on-k8s.md)
* [Redis Connect Postgres Sample](https://github.com/redis-field-engineering/redis-connect-dist/tree/main/examples/postgres)
* [Kubernetes Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
* [Install RedisInsights on k8s](https://docs.redis.com/latest/ri/installing/install-k8s/)
* [Vault k8 injector](https://www.vaultproject.io/docs/platform/k8s/injector)
* [Github with full installation steps](https://github.com/jphaugla/redisEnterpriseVault.git)
* [Github for redis enterprise kubernetes](git clone https://github.com/RedisLabs/redis-enterprise-k8s-docs.git)

## Technical Overview

* Verify kubernetes Redis Enterprise setup with/without vault has required prerequisites
* If using Vault, Setup Vault and "Hashicorp Vault plugin on Redis Enterprise k8s"
* Work through Redis Connect using "With" or "Without" vault

&nbsp;

---

&nbsp;

## Instructions
&nbsp;

### Verify kubernetes cluster 
Need to have working kubernetes cluster with:
* sufficient privileges
* minimum of three nodes for redis enterprise
* additional resources needed for redis insights, vault, source database, and redis connect


### Verify Redis Enterprise

* Verify these [Redis Enterprise k8s installation instructions](https://github.com/RedisLabs/redis-enterprise-k8s-docs#installation) were followed through step 4
* Need two redis enterprise databases.  The first database is the Target database for redis connect and the second stores meta-data for redis-connect
  * The metadata database must have the timeseries module installed
  * If, the redis-meta database doesn't create, it may be the version of the timeseries module as it must fit with the deployed version.  Verify the module version for this redis enterprise version using [the release notes](https://docs.redis.com/latest/rs/release-notes/)
  * Sample yaml files for the redis enterprise databases are available
    * ![target database](demo/redis-enterprise-database.yml)
    * ![metadata database](demo/redis-meta.yml)
  * Sample scripts to get the redis enterprise cluster username and password as well as the database username and passwords are also available
    * ![get database username and password](demo/getDatabasePw.sh)
    * ![get cluster username and password](demo/getClusterUnPw.sh)
  * Consider using redisinsights
    * [Install RedisInsights on k8s](https://docs.redis.com/latest/ri/installing/install-k8s/)

### Verify Source Database
Closely verify:
* replication requirements for the source database
  * ensure replication logs are cleaning up properly
* User permissions to access the source system

### Vault
Can skip this section if not using vault skip to [Redis Connect without Vault](#redis-connect-without-vault)

* Reference both of these links
  * [Set up vault on GKE](https://learn.hashicorp.com/tutorials/vault/kubernetes-google-cloud-gke)
  * [Hashicorp Vault plugin on Redis Enterprise k8s](https://github.com/RedisLabs/vault-plugin-database-redis-enterprise/blob/main/docs/guides/using-the-plugin-on-k8s.md)
* Ensure plugin directory and volume is configured for kubernetes for the Redis Enterprise Vault plug-in
* Have all the kubernetes tools available:  kubectl and jq
* Must be able to unseal the vault to run the commands-simple steps in link below as part of the GKE guide
  * [Set up vault on GKE](https://learn.hashicorp.com/tutorials/vault/kubernetes-google-cloud-gke). 
* The operator init writes pertinent keys to the cluster-keys.json file for safe keeping, obtain unseal key, unseal the vault and display status

#### Unseal Vault
```bash
cd vault
kubectl exec vault-0 -- vault operator init -key-shares=1 -key-threshold=1 -format=json > cluster-keys.json
export VAULT_UNSEAL_KEY=$(cat cluster-keys.json | jq -r ".unseal_keys_b64[]")
kubectl exec vault-0 -- vault operator unseal $VAULT_UNSEAL_KEY
kubectl exec vault-0 -- vault status
```
* To use the vault, a token is needed.  For this exercise, use the root token to login

```bash
cat cluster-keys.json | jq -r ".root_token"
export CLUSTER_ROOT_TOKEN=$(cat cluster-keys.json | jq -r ".root_token")
kubectl exec vault-0 -- vault login $CLUSTER_ROOT_TOKEN
```
#### Download the plugin file
Make sure you grab the correct file-many similarly named files
* download vault-plugin-database-redis-enterprise_0.1.3_linux_amd64
https://github.com/RedisLabs/vault-plugin-database-redis-enterprise/releases
* need to change the permissions, copy the file to the vault container, and pull the shasum for used later
* this assumes the plugin directory is /usr/local/libexec/vault.  Adjust command accordingly for plugin directory naming
```bash
mv ~/Downloads/vault-plugin-database-redis-enterprise_0.1.3_linux_amd64 $VAULT
kubectl cp -n vault $VAULT/vault-plugin-database-redis-enterprise_0.1.3_linux_amd64 vault-0:/usr/local/libexec/vault
shasum -a 256 $VAULT/vault-plugin-database-redis-enterprise_0.1.3_linux_amd64| awk '{print $1}'
```
* get the cluster and database password information for use while logged into vault
```bash
../demo/getDatabasePw.sh
../demo/getClusterUnPw.sh
```
####  log to vault container and enable vault plugin
Use the shasum value pulled from above and not the current value set equal to sha256
```bash
kubectl exec --stdin=true --tty=true vault-0 -- /bin/sh
vault write sys/plugins/catalog/database/redisenterprise-database-plugin command=vault-plugin-database-redis-enterprise_0.1.3_linux_amd64 sha256=739421599adfe3cdc53c8d6431a3066bfc0062121ba8c9c68e49119ab62a5759
```
#### Create database configurations in vault
Using the information from the getClusterUnPw.sh script from above and using the username and password valued for redis enterprise cluster authentication.   
For additional explanations peruse [Hashicorp Vault plugin on Redis Enterprise k8s](https://github.com/RedisLabs/vault-plugin-database-redis-enterprise/blob/main/docs/guides/using-the-plugin-on-k8s.md)
```bash
chmod 755 /usr/local/libexec/vault/vault-plugin-database-redis-enterprise_0.1.3_linux_amd64
vault secrets enable database
vault write database/config/demo-rec-redis-enterprise-database plugin_name="redisenterprise-database-plugin" url="https://rec.demo.svc:9443" allowed_roles="*" database=redis-enterprise-database username=demo@redislabs.com password=vubYurxK
vault write database/config/demo-rec-redis-meta plugin_name="redisenterprise-database-plugin" url="https://rec.demo.svc:9443" allowed_roles="*" database=redis-meta username=demo@redislabs.com password=vubYurxK
```
#### Create database roles
```bash
vault write database/roles/redis-enterprise-database db_name=demo-rec-redis-enterprise-database creation_statements="{\"role\":\"Admin\"}" default_ttl=90m max_ttl=100m
vault write database/roles/redis-meta db_name=demo-rec-redis-meta creation_statements="{\"role\":\"Admin\"}" default_ttl=90m max_ttl=100m
```
#### test the database connections
Using the information from getDatabasePw.sh above.  Read the authentication parameters and use the returned values for subsequent authentication step, substituting returned values for the password and port
Grab another new terminal window to runt the port forward command.  (note, need the actual port from getDatabasePw.sh)

```bash
kubectl port-forward -n demo service/redis-enterprise-database 18154:18154
kubectl port-forward -n demo service/redis-meta 16254:16254
```
NOTES:  
* the redis-cli command is using the username and password from the output of the read database command
* the vault read command must be done from the vault terminal 
  * can log in to the vault container using  ```kubectl exec --stdin=true --tty=true vault-0 -- /bin/sh```
* From vault for redis-enterprise-database
```bash

vault read database/creds/redis-enterprise-database
      Key                Value
      ---                -----
      lease_id           database/creds/redis-enterprise-database/JVsEvOrtZfK46dMO7GWRxjTW
      lease_duration     90m
      lease_renewable    true
      password           blZxlE10AS-zy-UBbjdh
      username           v_root_redis-enterprise-database_sruv9v0fewy2rv4m1oxq_1646252982
```
* From vault for redis-meta 
```bash
vault read database/creds/redis-meta
      Key                Value
      ---                -----
      lease_id           database/creds/redis-meta/iahGKJ9XNkisGsyLgW89Ohpt
      lease_duration     90m
      lease_renewable    true
      password           Vfo2ajqBvWAVKFyI-ojR
      username           v_root_redis-meta_n2dkafecjttws9mzj9eg_1646411445
```
Open a new terminal window  and test each database using the username and password values from the vault read database output
* redis-enterprise-database
```bash
redis-cli -p 18154
>AUTH v_root_redis-enterprise-database_sruv9v0fewy2rv4m1oxq_1646252982 blZxlE10AS-zy-UBbjdh
```
* redis-meta
```bash
redis-cli -p 16254
>AUTH v_root_redis-meta_n2dkafecjttws9mzj9eg_1646411445 Vfo2ajqBvWAVKFyI-ojR
```

#### Authorize kubernetes
* using vault terminal connection...   
```bash
vault auth enable kubernetes
vault secrets enable kubernetes
vault write auth/kubernetes/config \
token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" \
kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
```
* don't log out of vault, keep vault connection in a separate terminal and use the vault terminal as directed

### Redis Connect Configuration
* create service account and namespace
```bash
cd redis-connect
kubectl create sa redis-connect
kubectl create namespace redis-connect
kubectl config set-context --current --namespace=redis-connect
```
#### Redis Connect With Vault
not needed if not doing vault (skip to [Redis Connect Without Vault](#redis-connect-without-vault))
* go to vault terminal
* This is a sample statement that could be used with postgres as a source database
```bash
vault write database/config/kube-postgres \
    plugin_name=postgresql-database-plugin \
    allowed_roles="redis-connect" \
    username="postgres" \
    password="jasonrocks" \
    connection_url="postgresql://{{username}}:{{password}}@mypostgres.postgres.svc:5432/RedisConnect?sslmode=disable"
vault write database/roles/redis-connect \
    db_name=kube-postgres \
    creation_statements="CREATE ROLE \"{{name}}\" WITH REPLICATION LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
         GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\"; \
         ALTER USER \"{{name}}\" WITH SUPERUSER;" \
    default_ttl="60m" \
    max_ttl="60m"
```
* create redis-connect policy and role
  * This policy allows reading from all three databases
```bash
vault policy write redis-connect-policy - <<EOF
 path "database/creds/redis-enterprise-database" {
   capabilities = ["read"]
 }
 path "database/creds/redis-meta" {
   capabilities = ["read"]
 }
path "database/creds/redis-connect" {
  capabilities = ["read"]
}
EOF

vault write auth/kubernetes/role/redis-connect \
    bound_service_account_names=redis-connect \
    bound_service_account_namespaces=redis-connect \
    policies=redis-connect-policy \
    ttl=24h
```
* Edit the jobmanager.properties file for the correct connection parameters in redis.connection.url
  * these parameters can be retrieved using ```$DEMO/getDatabasePw.sh```
* create configmap with jobmanager.properties
  * this configmap is used in the redis-connect-start.yaml to mount files appropriately
* start the redis-connect server
```bash
cd redis-connect
vi jobmanager.properties
kubectl create configmap redis-connect-config \
  --from-file=jobmanager.properties=jobmanager.properties 
kubectl apply -f vault/redis-connect-start.yaml
```
#### Redis Connect Without Vault
* Edit the jobmanager.properties file for the correct connection parameters in redis.connection.url
  * these parameters can be retrieved using ```$DEMO/getDatabasePw.sh```
* Edit each credentials file for the appropriate connection information
  * For redisconnect_credentials_jobmanager.properties (redis-meta) and redisconnect_credentials_redis_postgres-job.properties (redis-enterprise-db) can use a null username and the password from getDatabasePw.sh
* create configmap with jobmanager.properties and the credentials files
  * this configmap is used in the redis-connect-start.yaml to mount files appropriately
* start the redis-connect server
```bash
cd redis-connect
vi jobmanager.properties
kubectl create configmap redis-connect-config \
  --from-file=jobmanager.properties=jobmanager.properties \
  --from-file=redisconnect_credentials_jobmanager.properties=non-vault/redisconnect_credentials_jobmanager.properties \
  --from-file=redisconnect_credentials_redis_postgres-job.properties=non-vault/redisconnect_credentials_redis_postgres-job.properties \
  --from-file=redisconnect_credentials_postgresql_postgres-job.properties=non-vault/redisconnect_credentials_postgresql_postgres-job.properties 
kubectl apply -f non-vault/redis-connect-start.yaml
```


### Test replication
This section will define the redis-connect job using an API approach.  For more detail on the redis-connect swagger interface, see this
[demo section](https://github.com/redis-field-engineering/redis-connect-dist/examples/postgres/demo) in redis connection github
In another terminal, need to port-forward the rest API interface to set up the actual job
```bash
kubectl port-forward pod/redis-connect-59475bcdd4-nwv5v 8282:8282
```
Use the [swagger interface]( http://localhost:8282/swagger-ui/index.html) to define the job and control the job execution
* Save the job configuration using swagger interface ![swagger](../images/deployments/swagger1.png)
  * click on *POST* Save Job Configuration to bring up the API interface ![API](../images/deployments/swagger-save-job.png)
  * click on *Try It Out*
  * Enter the jobname of *postgres-job*
  * Click on *browse* and select the redis-connect/postgres-job.json
  * Click on *Execute*
* Insert rows using postgres container
```bash
kubectl -n postgres exec --stdin --tty  mypostgres-1-0 -- /bin/sh
psql -Upostgres -W
\c "RedisConnect"
INSERT INTO public.emp (empno, fname, lname, job, mgr, hiredate, sal, comm, dept) VALUES (1, 'Allen', 'Terleto', 'FieldCTO', 1, '2018-08-06', 20000, 10, 1);
INSERT INTO public.emp (empno, fname, lname, job, mgr, hiredate, sal, comm, dept) VALUES (2, 'Brad', 'Barnes', 'SA Manager', 1, '2019-08-06', 20000, 10, 1);
INSERT INTO public.emp (empno, fname, lname, job, mgr, hiredate, sal, comm, dept) VALUES (3, 'Virag', 'Tripathi', 'Troublemaker', 1, '2020-08-06', 20000, 10, 1);
INSERT INTO public.emp (empno, fname, lname, job, mgr, hiredate, sal, comm, dept) VALUES (4, 'Jason', 'Haugland', 'SA', 1, '2021-08-06', 20000, 10, 1);
INSERT INTO public.emp (empno, fname, lname, job, mgr, hiredate, sal, comm, dept) VALUES (5, 'Ryan', 'Bee', 'Field Sales', 1, '2005-08-06', 20000, 10, 1);
```
* Run the initial bulk load of the job ![swagger start](../images/deployments/swaggerStartjob.png)
  * Click on *POST* START Job to biring up the API interface ![API start](../images/deployments/swagger-run-load.png)
  * click on *Try It Out*
  * Enter the jobname of *postgres-job*
  * Enter the jobtype of *load*
* Test the results
* Run the stream load ![swagger start](../images/deployments/swaggerStartjob.png)
  * Click on *POST* START Job to bring up the API interface ![API start](../images/deployments/swagger-run-load.png)
```bash
INSERT INTO public.emp (empno, fname, lname, job, mgr, hiredate, sal, comm, dept) VALUES (111, 'Simon', 'Prickett', 'Tech Advocate', 1, '2016-08-06', 20000, 10, 1);
INSERT INTO public.emp (empno, fname, lname, job, mgr, hiredate, sal, comm, dept) VALUES (112, 'Doug', 'Snyder','Territory Manager', 1, '2021-08-06', 20000, 10, 1);
INSERT INTO public.emp (empno, fname, lname, job, mgr, hiredate, sal, comm, dept) VALUES (113, 'Jason', 'Plotch', 'Territory Manager', 1, '2021-08-06', 20000, 10, 1);
INSERT INTO public.emp (empno, fname, lname, job, mgr, hiredate, sal, comm, dept) VALUES (114, 'Nail', 'Sirazitdinov', 'TAM', 1, '2010-08-06', 20000, 10, 1);
INSERT INTO public.emp (empno, fname, lname, job, mgr, hiredate, sal, comm, dept) VALUES (115, 'Manish', 'Arora', 'SA', 1, '2021-08-06', 20000, 10, 1);
```
* Test the results
  
### Debug Ideas
* Redis-connect job [documentation link](https://github.com/redis-field-engineering/redis-connect-dist/tree/main/examples/postgres/demo#start-redis-connect)
* look for resulting rows in redis enterprise using redisinsight (see directions above)
* There are multiple methods to debug the running job.  Here are a few:
  * Find the pod name(s) for redis connect
  * get the logs for init and main container

```bash
kubectl -n redis-connect get pods
kubectl -n redis-connect logs redis-connect-postgres-595d6fb5f4-54c6v -c vault-agent-init
kubectl -n redis-connect logs redis-connect-postgres-595d6fb5f4-54c6v -c vault-agent
kubectl -n redis-connect logs redis-connect-postgres-595d6fb5f4-54c6v -c redis-connect
kubectl -n redis-connect exec --stdin --tty  redis-connect-687bd546fc-44kvc -- /bin/sh
```
  * log in to the pod and look at log files 
  * there is a debug line in redis-connect-start.yaml that keeps the pod running even if there are connection errors-this is great for debug
  * NOTE: check the swagger UI for API commands that are easier to use than redisconnect.sh
  * Check the file systems mounted correctly
```bash
cd logs
# investigate the log files 
vi *
# login to cli
cd ../bin
./redisconnect.sh cli
> validate connection -t JDBCConnectionProvider -i RDBConnection
exit
df -h
```
this should be output from the df -h
![df ouput](../images/deployments/redis-connect-mounts.png)
  * Ensure each credential file is named correctly
  * Test the username/password from the credential file to ensure the connection works from the respective database
