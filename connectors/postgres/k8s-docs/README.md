# Redis Connect for PostgreSQL in K8s

This repository describes the steps involved to deploy Redis Connect for PostgreSQL in K8s. 

Overall flow:
1. Clone the Redis Connect for Postgres repository.
2. Configure Redis Connect as in this set of docs.
3. Deploy the Redis Connect configuration to Kubernetes.
4. Configure the Redis Connect deployment manifests.
5. Stage the Redis Connect job.
6. Start the Redis Connect job.

**Note:** This doc uses `kubectl` and `oc` interchangably.

## 1. Clone the Redis Connect for Postgres Repository
```
$ git clone https://github.com/RedisLabs-Field-Engineering/redis-connect-dist.git
...
$ cd redis-connect-dist/connectors/postgres/
```

## 2. Configure Redis Connect 

Configure the files in `config/` to describe your Redis Connect Job. One sample configuration is <a href="config/">here</a>. 

Redis Connect is a Java application which is a client of both the source RDBMS and the target Redis. As such, you will need:
* Source database details (endpoint, port, credentials)
  * *WAL and replication configuration* completed on the source database system
* Source schema details
* Target Redis details and instances (one for the data, one for the Job configuration)

Details for configurating Redis Connect for Postgres are <a href="../" target="_blank"><here</a>. 

## 3. Deploy the Redis Connect Configuration to Kubernetes

This deployment requires the use of K8s ConfigMaps. The necessary config maps will be uploaded from your local directories using the commands below. 

Here is an example of creating the ConfigMap. This command should be run from the directory containing your config files:
```
kubectl create configmap redis-connect-postgres-config \
  --from-file=JobConfig.yml=JobConfig.yml \
  --from-file=JobManager.yml=JobManager.yml \
  --from-file=env.yml=env.yml \
  --from-file=Setup.yml=Setup.yml \
  --from-file=mapper1.yml=mappers/mapper1.yml
```
The outcome is:
```
$ oc get configmap/redis-connect-postgres-config
NAME                            DATA   AGE
redis-connect-postgres-config   5      5s
```

If you need to add a custom stage jar file then you can append that to the ConfigMap creation as follows:
```
kubectl create configmap redis-connect-postgres-config \
  --from-file=JobConfig.yml=JobConfig.yml \
  --from-file=JobManager.yml=JobManager.yml \
  --from-file=env.yml=env.yml \
  --from-file=Setup.yml=Setup.yml \
  --from-file=mapper1.yml=mappers/mapper1.yml \
  --from-file=redis-connect-custom-stage-demo-1.0-SNAPSHOT.0.jar=redis-connect-custom-stage-demo-1.0-SNAPSHOT.0.jar
```
The outcome is:
```
$ oc get configmap/redis-connect-postgres-config
NAME                            DATA   AGE
redis-connect-postgres-config   6      12s
```

If the ConfigMap did not get created, it's likely that one of more of the source configuration files was not found (eg. JobConfig.yml) 

The details of the the command above are:
`kubectl create configmap <configmap_name>  --from-file=<key_name>=<path-to/file_name>`

**Note:** ConfigMaps are immutable so if you are making changes to an existing configuration, you need to delete the existing configuration first.

### How Does the ConfigMap get used?

The values of keys in the ConfigMap will be mounted directly to the pod's filesystem. 

The following volume mount is defined in the manifests. The a will mount the resource `config-volume` to that `mountPath`.
```
        volumeMounts:
        ...
        - name: config-volume
          mountPath: /opt/redislabs/redis-connect-postgres/config/fromconfigmap
```
The volume is defined through the following `volume` directive. It will mount the file/pth `JobConfig.yml` using the contents of the key named `JobConfig.yml` from the ConfigMap `redis-connect-postgres-config` in the `mountPath` define above.  
```
      volumes:
      - name: config-volume
        configMap:
          name: redis-connect-postgres-config
          items:
          - key: JobConfig.yml
            path: JobConfig.yml
```
The effect of this mapping in the pod's filesystem is the following:
```
root@redis-connect-postgres-7b7ccf87b9-sqshl> pwd
/opt/redislabs/redis-connect-postgres/config/fromconfigmap
root@redis-connect-postgres-7b7ccf87b9-sqshl> ls -al
total 0
drwxrwxrwx    3 root     root           149 Aug 12 15:52 .
drwxr-xr-x    1 root     root            27 Aug 12 15:52 ..
drwxr-xr-x    3 root     root            96 Aug 12 15:52 ..2021_08_12_15_52_06.258096011
lrwxrwxrwx    1 root     root            31 Aug 12 15:52 ..data -> ..2021_08_12_15_52_06.258096011
lrwxrwxrwx    1 root     root            20 Aug 12 15:52 JobConfig.yml -> ..data/JobConfig.yml
lrwxrwxrwx    1 root     root            21 Aug 12 15:52 JobManager.yml -> ..data/JobManager.yml
lrwxrwxrwx    1 root     root            16 Aug 12 15:52 Setup.yml -> ..data/Setup.yml
lrwxrwxrwx    1 root     root            14 Aug 12 15:52 env.yml -> ..data/env.yml
lrwxrwxrwx    1 root     root            14 Aug 12 15:52 mappers -> ..data/mappers
```
The final link is the environment variable that instructs Redis Connect to use these mapped files:
```
        env:
        ...
          - name: REDISCONNECT_CONFIG
            value: "/opt/redislabs/redis-connect-postgres/config/fromconfigmap"
```

## 4. Configure the Redis Connect Deployment Manifests

Update both the `redis-connect-postgres-stage.yaml` and `redis-connect-postgres-start.yaml` to map the appropriate environment variables in the `env:` section. Notable, the `REDISCONNECT_SOURCE_USERNAME`, `REDISCONNECT_SOURCE_PASSWORD`, `REDISCONNECT_TARGET_USERNAME` and `REDISCONNECT_TARGET_PASSWORD`. 


## Stage the Redis Connect Job

Apply the stage manifest as follows: `oc apply -f redis-connect-postgres-stage.yaml`. The outcome will be a k8s batch/Job which will run once and exit. 
```
$ oc get po -w 
NAME                                         READY   STATUS      RESTARTS   AGE
redis-connect-postgres-stage-lkvp2           0/1     Completed   0          44s
``` 
  
The effect of this stage operation is the configuration keys are loaded in to the target Redis instance defined in `env.yml`:`jobConfigConnection`. The Job should have an `UNASSIGNED` owner.

## Start the Redis Connect Job

Apply the stage manifest as follows: `oc apply -f redis-connect-postgres-start.yaml`. The outcome will be a k8s apps/Deployment which will run continually. 
```
$ oc get po -w
NAME                                         READY   STATUS      RESTARTS   AGE
redis-connect-postgres-cbc7dcd9d-k9mxj       1/1     Running     0          4s
redis-connect-postgres-stage-lkvp2           0/1     Completed   0          3m10s
``` 

The effect of the above is that the Redis Connect job has started. The Job Owner should be specified in the in `env.yml`:`jobConfigConnection` Redis DB as `JC-xx@redis-connect-postgres-cbc7dcd9d-k9mxj` indicating that the pod created is the Redis Connect job owner. You should see your changes propagate to the `targetConnection` Redis database as defined in `env.yml`. 

### Troubleshooting Options

To be detailed:
1. Adjust log level in logback.xml, tail logs.
2. Start the pods in interactive mode.

