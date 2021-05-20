#!/bin/sh

# Set archive log mode and enable GG replication
ORACLE_SID=ORCLCDB
export ORACLE_SID

sqlplus sys/Redis123@ORCLPDB1 as sysdba <<- EOF
  @?/demo/schema/human_resources/hr_main.sql hr users temp $ORACLE_HOME/demo/schema/log/

  connect hr/hr@ORCLPDB1
  select count(*) from employees;
  exit;
EOF
