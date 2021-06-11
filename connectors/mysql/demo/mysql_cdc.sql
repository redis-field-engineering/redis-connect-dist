select version();
CREATE SCHEMA IF NOT EXISTS RedisConnect DEFAULT CHARACTER SET utf8;
SHOW DATABASES;


SELECT variable_value as "BINARY LOGGING STATUS (log-bin) ::" FROM performance_schema.global_variables WHERE variable_name='log_bin';

-- create a demo user for bin_log based replication
CREATE USER 'redisconnectuser'@'localhost' IDENTIFIED BY 'redisconnectpassword';
-- Grant the required permissions to the user
GRANT SELECT, RELOAD, SHOW DATABASES, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'redisconnectuser' IDENTIFIED BY 'redisconnectpassword';
-- check the permissions
SELECT * from mysql.`user` where user='redisconnectuser';

use RedisConnect;

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
