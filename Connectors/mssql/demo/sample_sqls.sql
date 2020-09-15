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
