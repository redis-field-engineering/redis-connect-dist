select version();

CREATE TABLE IF NOT EXISTS emp (
    empno int NOT NULL,
    fname varchar(50),
    lname varchar(50),
    job varchar(50),
    mgr int,
    hiredate date,
    sal decimal(13, 4),
    comm decimal(13, 4),
    dept int,
    PRIMARY KEY (empno)
    );

ALTER TABLE emp REPLICA IDENTITY FULL;

CREATE TABLE IF NOT EXISTS heartbeat (id SERIAL PRIMARY KEY, ts TIMESTAMP WITH TIME ZONE);

ALTER TABLE heartbeat REPLICA IDENTITY FULL;

\d emp;

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

\du+;

\dt+;