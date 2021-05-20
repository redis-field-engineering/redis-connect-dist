#!/bin/sh

# Set archive log mode and enable GG replication
ORACLE_SID=ORCLCDB
export ORACLE_SID
sqlplus /nolog <<- EOF
	CONNECT sys/Redis123 AS SYSDBA
	alter system set db_recovery_file_dest_size = 10G;
	alter system set db_recovery_file_dest = '/opt/oracle/oradata/recovery_area' scope=spfile;
	shutdown immediate
	startup mount
	alter database archivelog;
	alter database open;
        -- Should show "Database log mode: Archive Mode"
	archive log list
	exit;
EOF

# Enable LogMiner required database features/settings
sqlplus sys/Redis123@//localhost:1521/ORCLCDB as sysdba <<- EOF
  ALTER DATABASE ADD SUPPLEMENTAL LOG DATA;
  ALTER PROFILE DEFAULT LIMIT FAILED_LOGIN_ATTEMPTS UNLIMITED;
  exit;
EOF

# Create Log Miner Tablespace and User
sqlplus sys/Redis123@//localhost:1521/ORCLCDB as sysdba <<- EOF
  CREATE TABLESPACE LOGMINER_TBS DATAFILE '/opt/oracle/oradata/ORCLCDB/logminer_tbs.dbf' SIZE 25M REUSE AUTOEXTEND ON MAXSIZE UNLIMITED;
  exit;
EOF

sqlplus sys/Redis123@//localhost:1521/ORCLPDB1 as sysdba <<- EOF
  CREATE TABLESPACE LOGMINER_TBS DATAFILE '/opt/oracle/oradata/ORCLCDB/ORCLPDB1/logminer_tbs.dbf' SIZE 25M REUSE AUTOEXTEND ON MAXSIZE UNLIMITED;
  exit;
EOF

sqlplus sys/Redis123@//localhost:1521/ORCLCDB as sysdba <<- EOF
  CREATE USER c##cdcuser IDENTIFIED BY cdcuser DEFAULT TABLESPACE LOGMINER_TBS QUOTA UNLIMITED ON LOGMINER_TBS CONTAINER=ALL;

  GRANT CREATE SESSION TO c##cdcuser CONTAINER=ALL;
  GRANT SET CONTAINER TO c##cdcuser CONTAINER=ALL;
  GRANT SELECT ON V_\$DATABASE TO c##cdcuser CONTAINER=ALL;
  GRANT FLASHBACK ANY TABLE TO c##cdcuser CONTAINER=ALL;
  GRANT SELECT ANY TABLE TO c##cdcuser CONTAINER=ALL;
  GRANT SELECT_CATALOG_ROLE TO c##cdcuser CONTAINER=ALL;
  GRANT EXECUTE_CATALOG_ROLE TO c##cdcuser CONTAINER=ALL;
  GRANT SELECT ANY TRANSACTION TO c##cdcuser CONTAINER=ALL;
  GRANT SELECT ANY DICTIONARY TO c##cdcuser CONTAINER=ALL;
  GRANT LOGMINING TO c##cdcuser CONTAINER=ALL;

  GRANT CREATE TABLE TO c##cdcuser CONTAINER=ALL;
  GRANT ALTER ANY TABLE TO c##cdcuser CONTAINER=ALL;
  GRANT LOCK ANY TABLE TO c##cdcuser CONTAINER=ALL;
  GRANT CREATE SEQUENCE TO c##cdcuser CONTAINER=ALL;

  GRANT EXECUTE ON DBMS_LOGMNR TO c##cdcuser CONTAINER=ALL;
  GRANT EXECUTE ON DBMS_LOGMNR_D TO c##cdcuser CONTAINER=ALL;
  GRANT SELECT ON V_\$LOGMNR_LOGS TO c##cdcuser CONTAINER=ALL;
  GRANT SELECT ON V_\$LOGMNR_CONTENTS TO c##cdcuser CONTAINER=ALL;
  GRANT SELECT ON V_\$LOGFILE TO c##cdcuser CONTAINER=ALL;
  GRANT SELECT ON V_\$ARCHIVED_LOG TO c##cdcuser CONTAINER=ALL;
  GRANT SELECT ON V_\$ARCHIVE_DEST_STATUS TO c##cdcuser CONTAINER=ALL;

  exit;
EOF

sqlplus sys/Redis123@//localhost:1521/ORCLPDB1 as sysdba <<- EOF
  CREATE USER cdcuser IDENTIFIED BY cdcuser;
  GRANT CONNECT TO cdcuser;
  GRANT CREATE SESSION TO cdcuser;
  GRANT CREATE TABLE TO cdcuser;
  GRANT CREATE SEQUENCE to cdcuser;
  ALTER USER cdcuser QUOTA 100M on users;
  exit;
EOF

sqlplus sys/Redis123@ORCLPDB1 as sysdba <<- EOF
  @?/demo/schema/human_resources/hr_main.sql hr users temp $ORACLE_HOME/demo/schema/log/

  connect hr/hr@ORCLPDB1
  select count(*) from employees;
  exit;
EOF
