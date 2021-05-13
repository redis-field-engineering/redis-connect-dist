CREATE SCHEMA IF NOT EXISTS RedisLabsCDC DEFAULT CHARACTER SET utf8;
SHOW DATABASES;

use RedisLabsCDC;

CREATE TABLE IF NOT EXISTS emp (
    empno int NOT NULL,
    fname varchar(50),
    lname varchar(50),
    job varchar(50),
    mgr int,
    hiredate datetime,
    sal decimal(13, 4),
    comm decimal(13, 4),
    dept int,
    PRIMARY KEY (empno)
    )
    ENGINE = InnoDB;

desc emp;
