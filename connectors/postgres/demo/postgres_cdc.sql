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

\d emp;

\du+;

\dt+;
