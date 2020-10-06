USE master
GO
-- Create the new database if it does not exist already
IF NOT EXISTS (
       SELECT [name]
              FROM sys.databases
              WHERE [name] = N'RedisLabsCDC'
)
CREATE DATABASE RedisLabsCDC
GO
-- Check and enable database for CDC
SELECT is_cdc_enabled
FROM sys.databases
WHERE name = 'RedisLabsCDC'

use RedisLabsCDC
EXEC sys.sp_cdc_enable_db

SELECT is_cdc_enabled
FROM sys.databases
WHERE name = 'RedisLabsCDC'

-- Create emp table (Please note that MSSQL table names are case sensitive so this name must match the table name in RedisCDC JobConfig.yml)
CREATE TABLE [RedisLabsCDC].[dbo].[emp] (
    [empno] int NOT NULL,
    [fname] varchar(50),
    [lname] varchar(50),
    [job] varchar(50),
    [mgr] int,
    [hiredate] datetime,
    [sal] money,
    [comm] money,
    [dept] int,
    PRIMARY KEY ([empno])
);

-- Enable emp table for CDC
EXEC sys.sp_cdc_enable_table @source_schema = 'dbo'
       , @source_name = 'emp'
       , @role_name = NULL
       , @capture_instance = 'cdcauditing_emp'

-- Query and check the CDC setup
SELECT s.name AS Schema_Name, tb.name AS Table_Name
, tb.object_id, tb.type, tb.type_desc, tb.is_tracked_by_cdc
FROM sys.tables tb
INNER JOIN sys.schemas s on s.schema_id = tb.schema_id
WHERE tb.is_tracked_by_cdc = 1

-- Or use this Stored prod 
USE RedisLabsCDC;
EXEC sys.sp_cdc_help_change_data_capture;
