-- Data Migration Script: Backfill ActivityNumber on Existing Proposals
-- WARNING: Run this only if you need to populate existing proposals
-- RECOMMENDATION: Test in non-production environment first

-- IMPORTANT: This script assumes that all transactions in a proposal 
-- have the same activity. If not, it will use the most common activity.

-- Backup first!
-- SELECT * INTO ProjProposalJour_Backup FROM ProjProposalJour;

-- Update proposals based on hour transactions
UPDATE pp
SET pp.ActivityNumber = activity.ActivityNumber
FROM ProjProposalJour pp
CROSS APPLY (
    SELECT TOP 1 ets.ActivityNumber
    FROM ProjProposalEmpl ppe
    JOIN ProjProposalEmplDetail pped ON ppe.RecId = pped.RefRecId
    JOIN ProjEmplTransSale ets ON pped.TransId = ets.TransId
    WHERE ppe.ProjProposalId = pp.ProjProposalId
      AND ets.ActivityNumber IS NOT NULL
      AND ets.ActivityNumber <> ''
    GROUP BY ets.ActivityNumber
    ORDER BY COUNT(*) DESC -- Use most common activity
) activity
WHERE pp.ActivityNumber IS NULL
  AND pp.Posted = 0; -- Only unposted proposals

PRINT CAST(@@ROWCOUNT AS NVARCHAR(10)) + ' proposals updated with ActivityNumber from hour transactions';

-- Update proposals based on expense transactions (if no hour transactions)
UPDATE pp
SET pp.ActivityNumber = activity.ActivityNumber
FROM ProjProposalJour pp
CROSS APPLY (
    SELECT TOP 1 cts.ActivityNumber
    FROM ProjProposalCost ppc
    JOIN ProjProposalCostDetail ppcd ON ppc.RecId = ppcd.RefRecId
    JOIN ProjCostTransSale cts ON ppcd.TransId = cts.TransId
    WHERE ppc.ProjProposalId = pp.ProjProposalId
      AND cts.ActivityNumber IS NOT NULL
      AND cts.ActivityNumber <> ''
    GROUP BY cts.ActivityNumber
    ORDER BY COUNT(*) DESC
) activity
WHERE pp.ActivityNumber IS NULL
  AND pp.Posted = 0;

PRINT CAST(@@ROWCOUNT AS NVARCHAR(10)) + ' proposals updated with ActivityNumber from expense transactions';

-- Validation: Check for proposals still without activity
SELECT 
    ProjProposalId,
    ProjInvoiceProjId,
    InvoiceDate,
    InvoiceAmount,
    'NEEDS REVIEW' AS Status
FROM ProjProposalJour
WHERE ActivityNumber IS NULL
  AND Posted = 0
  AND CREATEDDATETIME > DATEADD(DAY, -30, GETUTCDATE());

PRINT 'Review proposals without ActivityNumber shown above';
