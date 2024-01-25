select version();

CREATE USER testuser WITH PASSWORD 'testpassword';

ALTER USER testuser WITH SUPERUSER;

CREATE TABLE IF NOT EXISTS emp (
    empno int NOT NULL,
    fname varchar(50),
    lname varchar(50),
    job varchar(50),
    mgr int,
    hiredate timestamp with time zone,
    sal decimal(13, 2),
    comm decimal(13, 2),
    dept int,
    PRIMARY KEY (empno)
    );

ALTER TABLE emp REPLICA IDENTITY FULL;

CREATE TABLE IF NOT EXISTS heartbeat (id SERIAL PRIMARY KEY, ts TIMESTAMP WITH TIME ZONE);

ALTER TABLE heartbeat REPLICA IDENTITY FULL;

SELECT CASE relreplident
          WHEN 'd' THEN 'default'
          WHEN 'n' THEN 'nothing'
          WHEN 'f' THEN 'full'
          WHEN 'i' THEN 'index'
       END AS replica_identity
FROM pg_class
WHERE oid = 'emp'::regclass;

SELECT CASE relreplident
          WHEN 'd' THEN 'default'
          WHEN 'n' THEN 'nothing'
          WHEN 'f' THEN 'full'
          WHEN 'i' THEN 'index'
       END AS replica_identity
FROM pg_class
WHERE oid = 'heartbeat'::regclass;

COPY emp(empno, fname, lname, job, mgr, hiredate, sal, comm, dept)
FROM '/tmp/emp.csv'
DELIMITER ','
CSV HEADER;