options (skip=1, rows=50)
load data
 infile '/tmp/emp.csv'
 truncate into table c##rcuser.emp
 fields terminated by "," optionally enclosed by '"'
 ( empno,
   fname,
   lname,
   job,
   mgr,
   hiredate "to_date(:hiredate, 'YYYY-MM-DD HH24:MI:SS')",
   sal,
   comm,
   dept
 )