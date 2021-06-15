USE master
GO
-- Create the new database if it does not exist already
IF NOT EXISTS (
       SELECT [name]
              FROM sys.databases
              WHERE [name] = N'RedisConnect'
)
CREATE DATABASE RedisConnect
GO
-- Check and enable database for CDC
SELECT is_cdc_enabled
FROM sys.databases
WHERE name = 'RedisConnect'

use RedisConnect
EXEC sys.sp_cdc_enable_db

SELECT is_cdc_enabled
FROM sys.databases
WHERE name = 'RedisConnect'

-- Create emp table (Please note that MSSQL table names are case sensitive so this name must match the table name in RedisConnect JobConfig.yml)
CREATE TABLE [RedisConnect].[dbo].[emp] (
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
-- Use this Stored proc to return the change data capture configuration for each table enabled for change data capture in the current database.
USE RedisConnect;
EXEC sys.sp_cdc_help_change_data_capture;
