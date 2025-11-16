-- Validation Script: Identify Transactions Without Activity Numbers
-- Run this BEFORE creating invoice proposals to identify potential issues

-- Hour transactions without activity
SELECT 
    'Hour' AS TransType,
    ProjId,
    TransId,
    TransDate,
    Worker,
    Qty AS Hours,
    SalesPrice,
    LineAmount,
    InvoiceStatus
FROM ProjEmplTransSale
WHERE (ActivityNumber IS NULL OR ActivityNumber = '')
  AND InvoiceStatus IN (0, 1) -- Ready or On hold
ORDER BY ProjId, TransDate;

-- Expense transactions without activity
SELECT 
    'Expense' AS TransType,
    ProjId,
    TransId,
    TransDate,
    CategoryId,
    Qty,
    SalesPrice,
    LineAmount,
    InvoiceStatus
FROM ProjCostTransSale
WHERE (ActivityNumber IS NULL OR ActivityNumber = '')
  AND InvoiceStatus IN (0, 1)
ORDER BY ProjId, TransDate;

-- Item transactions without activity
SELECT 
    'Item' AS TransType,
    ProjId,
    TransId,
    TransDate,
    ItemId,
    Qty,
    SalesPrice,
    LineAmount,
    InvoiceStatus
FROM ProjItemTransSale
WHERE (ActivityNumber IS NULL OR ActivityNumber = '')
  AND InvoiceStatus IN (0, 1)
ORDER BY ProjId, TransDate;

-- Fee/Revenue transactions without activity
SELECT 
    'Revenue' AS TransType,
    ProjId,
    TransId,
    TransDate,
    CategoryId,
    LineAmount,
    InvoiceStatus
FROM ProjRevenueTransSale
WHERE (ActivityNumber IS NULL OR ActivityNumber = '')
  AND InvoiceStatus IN (0, 1)
ORDER BY ProjId, TransDate;

-- Summary by project
SELECT 
    ProjId,
    COUNT(*) AS UnassignedCount,
    SUM(LineAmount) AS UnassignedAmount
FROM (
    SELECT ProjId, LineAmount FROM ProjEmplTransSale 
    WHERE (ActivityNumber IS NULL OR ActivityNumber = '') AND InvoiceStatus IN (0, 1)
    UNION ALL
    SELECT ProjId, LineAmount FROM ProjCostTransSale 
    WHERE (ActivityNumber IS NULL OR ActivityNumber = '') AND InvoiceStatus IN (0, 1)
    UNION ALL
    SELECT ProjId, LineAmount FROM ProjItemTransSale 
    WHERE (ActivityNumber IS NULL OR ActivityNumber = '') AND InvoiceStatus IN (0, 1)
    UNION ALL
    SELECT ProjId, LineAmount FROM ProjRevenueTransSale 
    WHERE (ActivityNumber IS NULL OR ActivityNumber = '') AND InvoiceStatus IN (0, 1)
) AS AllTrans
GROUP BY ProjId
ORDER BY UnassignedAmount DESC;
