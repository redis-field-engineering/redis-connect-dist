#!/bin/sh

ORACLE_SID=ORCLCDB
export ORACLE_SID

sqlplus c##rcuser/rcpwd@ORCLPDB1 <<- EOF
  create table C##RCUSER.EMP(  
  empno		number(6,0),
  fname		varchar2(30),
  lname		varchar2(30),  
  job		varchar2(40),
  mgr		number(4,0),
  hiredate	date,
  sal		number(10,2),
  comm		number(10,2),
  dept		number(4,0),
  constraint pk_emp primary key (empno)
  );

  ALTER TABLE C##RCUSER.EMP ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;
  SELECT table_name, owner, LOGICAL_REPLICATION FROM all_tables WHERE owner='C##RCUSER' AND table_name='EMP'; 
  select count(*) from C##RCUSER.EMP;

  create table C##RCUSER.CLOB_DATA1(
  id          number(8) not null primary key,
  clob_data1  clob
  );

 create table C##RCUSER.CLOB_DATA2(
  id          number(8)	not null primary key,
  clob_data2	clob
  );

 create table C##RCUSER.BLOB_DATA1(
  id          number(8)	not null primary key,
  blob_data1	blob
  );

  ALTER TABLE C##RCUSER.CLOB_DATA1 ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;
  SELECT table_name, owner, LOGICAL_REPLICATION FROM all_tables WHERE owner='C##RCUSER' AND table_name='CLOB_DATA1';
  select count(*) from C##RCUSER.CLOB_DATA1;

  ALTER TABLE C##RCUSER.CLOB_DATA2 ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;
  SELECT table_name, owner, LOGICAL_REPLICATION FROM all_tables WHERE owner='C##RCUSER' AND table_name='CLOB_DATA2';
  select count(*) from C##RCUSER.CLOB_DATA2;

  ALTER TABLE C##RCUSER.BLOB_DATA1 ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;
  SELECT table_name, owner, LOGICAL_REPLICATION FROM all_tables WHERE owner='C##RCUSER' AND table_name='BLOB_DATA1';
  select count(*) from C##RCUSER.BLOB_DATA1;

  exit;
EOF

