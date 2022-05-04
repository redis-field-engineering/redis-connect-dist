-- Insert into emp table
INSERT INTO [dbo].[emp] (empno, fname, lname, job, mgr, hiredate, sal, comm, dept) VALUES ('1', 'Basanth', 'Gowda', 'FOUNDER', '1', '2018-08-09 00:00:00.000', '200000', '10', '1');
INSERT INTO [dbo].[emp] (empno, fname, lname, job, mgr, hiredate, sal, comm, dept) VALUES ('2', 'Virag', 'Tripathi', 'SA', '1', '2018-08-06 00:00:00.000', '2000', '10', '1');
INSERT INTO [dbo].[emp] (empno, fname, lname, job, mgr, hiredate, sal, comm, dept) VALUES ('3', 'Drake', 'Albee', 'RSM', '1', '2017-08-09 00:00:00.000', '5000', '10', '1');
INSERT INTO [dbo].[emp] (empno, fname, lname, job, mgr, hiredate, sal, comm, dept) VALUES ('4', 'Nick', 'Doyle', 'DIR', '1', '2019-07-09 00:00:00.000', '10000', '10', '1');
INSERT INTO [dbo].[emp] (empno, fname, lname, job, mgr, hiredate, sal, comm, dept) VALUES ('5', 'Allen', 'Terleto', 'DIR', '1', '2017-06-09 00:00:00.000', '500000', '10', '1');
INSERT INTO [dbo].[emp] (empno, fname, lname, job, mgr, hiredate, sal, comm, dept) VALUES ('6', 'Marco', 'Shkedi', 'SA', '1', '2018-06-09 00:00:00.000', '2000', '10', '1');
INSERT INTO [dbo].[emp] (empno, fname, lname, job, mgr, hiredate, sal, comm, dept) VALUES ('7', 'Brad', 'Barnes', 'SA', '1', '2018-07-09 00:00:00.000', '2000', '10', '1');
INSERT INTO [dbo].[emp] (empno, fname, lname, job, mgr, hiredate, sal, comm, dept) VALUES ('8', 'Quinton', 'Gingras', 'SDR', '1', '2019-07-09 00:00:00.000', '200000', '10', '1');
INSERT INTO [dbo].[emp] (empno, fname, lname, job, mgr, hiredate, sal, comm, dept) VALUES ('9', 'Yuval', 'Mankerious', 'SA', '1', '2019-07-09 00:00:00.000', '200000', '10', '1');

-- Update emp records
update emp set sal=1000000 where empno=5

-- Delete emp records
delete emp where empno=4

-- Monitor changes on MSSQL from CDC audit table
DECLARE @begin binary(10), @end binary(10);
SET @begin = sys.fn_cdc_get_min_lsn('cdcauditing_emp');
SET @end   = sys.fn_cdc_get_max_lsn();
 
SELECT __$start_lsn
       --, __$seqval
       , CASE
              WHEN __$operation = 1 THEN 'DELETE'
              WHEN __$operation = 2 THEN 'INSERT'
              WHEN __$operation = 3 THEN 'PRE-UPDATE'
              WHEN __$operation = 4 THEN 'POST-UPDATE'
              ELSE 'UNKNOWN'
       END AS Operation
       --, __$update_mask
       , empno
       , fname
       , lname
       , job
       , hiredate
FROM cdc.fn_cdc_get_all_changes_cdcauditing_EMP(@begin, @end, N'all update old')

-- Debugging CDC (Audit CDC tables)

DECLARE @begin_time datetime, @end_time datetime, @begin_lsn binary(10), @end_lsn binary(10);

SET @begin_time = '2020-12-01 00:00:00.000';

SET @end_time = '2021-01-06 10:00:00.000';

SELECT @begin_lsn = sys.fn_cdc_map_time_to_lsn('smallest greater than', @begin_time);

SELECT @end_lsn = sys.fn_cdc_map_time_to_lsn('largest less than or equal', @end_time);

select sys.fn_cdc_map_lsn_to_time(__$start_lsn) startlsn, sys.fn_cdc_map_lsn_to_time(__$end_lsn) endlsn,
empno,fname,lname,job,sal from cdc.cdcauditing_emp_CT order by startlsn desc
