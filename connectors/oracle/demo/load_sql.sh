#!/usr/bin/env bash

help()
{
   # Display help
   echo "Load SQL scripts to Oracle PDB."
   echo "Usage: [-h|insert|update|delete]"
   echo "options:"
   echo "-h: Print this help message and exit."
   echo "insert: Inserts rows in the database table."
   echo "update: Update rows in the database table."
   echo "delete: Delete rows from database table."
   echo -------------------------------
   echo
}

echo -------------------------------

while [ $# -eq 0 ] || [ $# -gt 0 ]
do
options="$1"
case ${options} in
-h)
help
exit;;
insert1k)
sqlplus hr/hr@ORCLPDB1 <<- EOF
  select count(*) from employees;
  Prompt ******  Populating EMPLOYEES table with 1K records ....

  @/tmp/employees1k_insert.sql

  commit;
  select count(*) from employees;

  exit;
EOF
break;;
insert10k)
sqlplus hr/hr@ORCLPDB1 <<- EOF
  select count(*) from employees;
  Prompt ******  Populating EMPLOYEES table with 10K records ....

  @/tmp/employees1k_insert.sql

  commit;
  select count(*) from employees;

  exit;
EOF
break;;
update)
sqlplus hr/hr@ORCLPDB1 <<- EOF
  select count(*) from employees;
  Prompt ******  Updating EMPLOYEES table ....

  @/tmp/update.sql
  ;

  commit;
  select count(*) from employees;

  exit;
EOF
break;;
delete)
sqlplus hr/hr@ORCLPDB1 <<- EOF
  select count(*) from employees;
  Prompt ******  Deleting from EMPLOYEES table ....

  @/tmp/delete.sql
  ;

  commit;
  select count(*) from employees;

  exit;
EOF
break;;
*)
help
exit;;

esac
done
echo -------------------------------
