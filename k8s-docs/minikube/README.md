# Demo Outline

:white_check_mark: Setup and start minikube<br>
:white_check_mark: Setup and start Source<br>
:white_check_mark: Setup and start Target (Redis Enterprise database)<br>
:white_check_mark: Setup and start Redis Connect<br>
:white_check_mark: Perform Initial load (load job) with Redis Connect<br>
:white_check_mark: Perform CDC (stream job) with Redis Connect<br>

# Prerequisites

Docker compatible [*nix OS](https://en.wikipedia.org/wiki/Unix-like) and [Docker](https://docs.docker.com/get-docker) installed.

### Setup and start minikube
https://minikube.sigs.k8s.io/docs/start/

### Setup and start Source

For this demo, lets use Postgres, but you can use any of the supported source by Redis Connect.
<br>Execute the following commands (copy & paste) to download and setup Redis Connect and demo scripts.
i.e.</br>

```bash
wget -c https://github.com/redis-field-engineering/redis-connect-dist/archive/main.zip && \
mkdir -p redis-connect/demo && \
unzip main.zip "redis-connect-dist-main/examples/postgres/*" -d redis-connect && \
cp -R redis-connect/redis-connect-dist-main/examples/postgres/demo/* redis-connect/demo && \
rm -rf main.zip redis-connect/redis-connect-dist-main && \
cd redis-connect && \
chmod a+x demo/*.sh && \
cd demo
```

## Setup PostgreSQL 10+ database (Source)
<b>_PostgreSQL on Docker_</b>
<br>Execute [setup_postgres.sh](../../examples/postgres/demo/setup_postgres.sh)</br>
```bash
demo$ ./setup_postgres.sh 12.3 5432
(or latest or any supported 10+ version from postgres dockerhub)
```

<details><summary>Validate Postgres database is running as expected:</summary>
<p>

```bash
demo$ sudo docker ps -a | grep postgres
b5adf162d133        postgres:12.3                                "docker-entrypoint.s…"   4 hours ago         Up 4 hours              0.0.0.0:5432->5432/tcp                                                                                                                                                                                                                                                                                          postgres-12.3-virag-cdc-5432

demo$ sudo docker exec -it postgres-12.3-$(hostname)-5432 bash -c 'psql -U"redisconnect" -d"RedisConnect" -c "select count(*) from emp;"'
 count
-------
     0
(1 row)  
```
</p>
</details>

Coming soon..