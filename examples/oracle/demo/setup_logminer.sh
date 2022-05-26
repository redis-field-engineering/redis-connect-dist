#!/bin/sh

# Set archive log mode and enable GG replication
ORACLE_SID=ORCLCDB
export ORACLE_SID
sqlplus /nolog <<- EOF
	CONNECT sys/Redis123 AS SYSDBA
	alter system set db_recovery_file_dest_size = 50G;
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
  CREATE TABLESPACE LOGMINER_TBS DATAFILE '/opt/oracle/oradata/ORCLCDB/logminer_tbs.dbf' SIZE 400M REUSE AUTOEXTEND ON MAXSIZE UNLIMITED;
  exit;
EOF

sqlplus sys/Redis123@//localhost:1521/ORCLPDB1 as sysdba <<- EOF
  CREATE TABLESPACE LOGMINER_TBS DATAFILE '/opt/oracle/oradata/ORCLCDB/ORCLPDB1/logminer_tbs.dbf' SIZE 400M REUSE AUTOEXTEND ON MAXSIZE UNLIMITED;
  exit;
EOF

sqlplus sys/Redis123@//localhost:1521/ORCLCDB as sysdba <<- EOF
  CREATE USER c##rcuser IDENTIFIED BY rcpwd DEFAULT TABLESPACE LOGMINER_TBS QUOTA UNLIMITED ON LOGMINER_TBS CONTAINER=ALL;

  GRANT CREATE SESSION TO c##rcuser CONTAINER=ALL;
  GRANT SET CONTAINER TO c##rcuser CONTAINER=ALL;
  GRANT SELECT ON V_\$DATABASE TO c##rcuser CONTAINER=ALL;
  GRANT FLASHBACK ANY TABLE TO c##rcuser CONTAINER=ALL;
  GRANT SELECT ANY TABLE TO c##rcuser CONTAINER=ALL;
  GRANT SELECT_CATALOG_ROLE TO c##rcuser CONTAINER=ALL;
  GRANT EXECUTE_CATALOG_ROLE TO c##rcuser CONTAINER=ALL;
  GRANT SELECT ANY TRANSACTION TO c##rcuser CONTAINER=ALL;
  GRANT SELECT ANY DICTIONARY TO c##rcuser CONTAINER=ALL;
  GRANT LOGMINING TO c##rcuser CONTAINER=ALL;

  GRANT CREATE TABLE TO c##rcuser CONTAINER=ALL;
  GRANT LOCK ANY TABLE TO c##rcuser CONTAINER=ALL;
  GRANT CREATE SEQUENCE TO c##rcuser CONTAINER=ALL;

  GRANT EXECUTE ON DBMS_LOGMNR TO c##rcuser CONTAINER=ALL;
  GRANT EXECUTE ON DBMS_LOGMNR_D TO c##rcuser CONTAINER=ALL;
  GRANT SELECT ON V_\$LOGMNR_LOGS TO c##rcuser CONTAINER=ALL;
  GRANT SELECT ON V_\$LOGMNR_CONTENTS TO c##rcuser CONTAINER=ALL;
  GRANT SELECT ON V_\$LOGFILE TO c##rcuser CONTAINER=ALL;
  GRANT SELECT ON V_\$ARCHIVED_LOG TO c##rcuser CONTAINER=ALL;
  GRANT SELECT ON V_\$ARCHIVE_DEST_STATUS TO c##rcuser CONTAINER=ALL;
  GRANT SELECT ON V_\$TRANSACTION TO c##rcuser CONTAINER=ALL;

  exit;
EOF
