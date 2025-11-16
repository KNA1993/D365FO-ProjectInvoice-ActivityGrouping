-- Validation Script: Verify ActivityNumber Field Exists on All Required Tables
-- Run this BEFORE deploying the extension to ensure prerequisites are met

-- Check ProjEmplTransSale (Hour transactions)
SELECT 
    'ProjEmplTransSale' AS TableName,
    CASE WHEN EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_NAME = 'PROJEMPLTRANSSALE' 
        AND COLUMN_NAME = 'ACTIVITYNUMBER'
    ) THEN 'OK' ELSE 'MISSING' END AS Status;

-- Check ProjCostTransSale (Expense transactions)
SELECT 
    'ProjCostTransSale' AS TableName,
    CASE WHEN EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_NAME = 'PROJCOSTTRANSSALE' 
        AND COLUMN_NAME = 'ACTIVITYNUMBER'
    ) THEN 'OK' ELSE 'MISSING' END AS Status;

-- Check ProjItemTransSale (Item transactions)
SELECT 
    'ProjItemTransSale' AS TableName,
    CASE WHEN EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_NAME = 'PROJITEMTRANSSALE' 
        AND COLUMN_NAME = 'ACTIVITYNUMBER'
    ) THEN 'OK' ELSE 'MISSING' END AS Status;

-- Check ProjRevenueTransSale (Revenue/Fee transactions)
SELECT 
    'ProjRevenueTransSale' AS TableName,
    CASE WHEN EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_NAME = 'PROJREVENUETRANSSALE' 
        AND COLUMN_NAME = 'ACTIVITYNUMBER'
    ) THEN 'OK' ELSE 'MISSING' END AS Status;

-- Check ProjOnAccTransSale (On-Account transactions) - Optional
SELECT 
    'ProjOnAccTransSale' AS TableName,
    CASE WHEN EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_NAME = 'PROJONACCTRANSSALE' 
        AND COLUMN_NAME = 'ACTIVITYNUMBER'
    ) THEN 'OK' ELSE 'MISSING (OPTIONAL)' END AS Status;

-- Summary: All tables should show 'OK' except ProjOnAccTransSale which is optional
