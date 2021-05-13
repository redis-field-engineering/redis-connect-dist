select version();
CREATE SCHEMA IF NOT EXISTS RedisLabsCDC DEFAULT CHARACTER SET utf8;
SHOW DATABASES;


SELECT variable_value as "BINARY LOGGING STATUS (log-bin) ::" FROM performance_schema.global_variables WHERE variable_name='log_bin';

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

SET GLOBAL show_compatibility_56 = ON;
