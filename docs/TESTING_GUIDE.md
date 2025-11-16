# Testing Guide: Activity Number Grouping for Project Invoice Proposals

## Test Environment Setup

### Prerequisites

1. **Test Environment Requirements**
   - D365 Finance & Operations test/sandbox environment
   - Visual Studio with D365 development tools
   - Database backup capability
   - Test user accounts with appropriate privileges

2. **Test Data Setup**
   ```sql
   -- Create test projects
   INSERT INTO ProjTable (ProjId, ProjName, CustAccount, ProjGroupId)
   VALUES 
       ('TEST001', 'Activity Test Project 1', 'US-001', 'TIME'),
       ('TEST002', 'Activity Test Project 2', 'US-001', 'TIME');
   
   -- Create test activities
   INSERT INTO ProjActivity (ActivityNumber, ActivityName, ProjId)
   VALUES
       ('ACT001', 'Design Phase', 'TEST001'),
       ('ACT002', 'Development Phase', 'TEST001'),
       ('ACT003', 'Testing Phase', 'TEST001');
   ```

3. **Baseline Capture**
   - Capture standard invoice proposal creation time
   - Document current behavior
   - Save sample outputs

---

## Unit Testing

### Test Class Structure

```xpp
[TestMethod]
class ProjInvoiceActivityGroupingTest extends SysTestCase
{
    ProjTable projTable;
    ProjEmplTransSale emplTrans1, emplTrans2;
    ActivityNumber activity1, activity2;
    
    [TestInitialize]
    public void setup()
    {
        // Setup test data
        this.createTestProject();
        this.createTestActivities();
        this.createTestTransactions();
    }
    
    [TestCleanup]
    public void cleanup()
    {
        // Clean up test data
        this.deleteTestData();
    }
    
    // Test methods below
}
```

### Unit Test Cases

#### TEST-001: Single Activity Grouping

**Objective**: Verify transactions with same activity are grouped into one proposal

```xpp
[TestMethod]
public void testSingleActivityGrouping()
{
    // Arrange
    this.createEmplTransaction('TRANS001', 'ACT001', 100);
    this.createEmplTransaction('TRANS002', 'ACT001', 150);
    
    // Act
    ProjInvoiceProposalCreateLines batch = ProjInvoiceProposalCreateLines::construct();
    batch.parmProjInvoiceProjId(projTable.ProjId);
    batch.run();
    
    // Assert
    ProjProposalJour proposal;
    int proposalCount = 0;
    
    while select proposal
        where proposal.ProjInvoiceProjId == projTable.ProjId
           && proposal.ActivityNumber == 'ACT001'
    {
        proposalCount++;
    }
    
    this.assertEquals(1, proposalCount, "Should create exactly one proposal");
    
    // Verify both transactions are in the proposal
    ProjProposalEmplDetail detailLine;
    int lineCount = 0;
    
    while select detailLine
        where detailLine.ProjProposalId == proposal.ProjProposalId
    {
        lineCount++;
    }
    
    this.assertEquals(2, lineCount, "Should have two detail lines");
}
```

#### TEST-002: Multiple Activity Splitting

**Objective**: Verify transactions with different activities create separate proposals

```xpp
[TestMethod]
public void testMultipleActivitySplitting()
{
    // Arrange
    this.createEmplTransaction('TRANS001', 'ACT001', 100);
    this.createEmplTransaction('TRANS002', 'ACT002', 150);
    
    // Act
    ProjInvoiceProposalCreateLines batch = ProjInvoiceProposalCreateLines::construct();
    batch.parmProjInvoiceProjId(projTable.ProjId);
    batch.run();
    
    // Assert
    int proposalCount = 0;
    ProjProposalJour proposal;
    
    while select proposal
        where proposal.ProjInvoiceProjId == projTable.ProjId
    {
        proposalCount++;
    }
    
    this.assertEquals(2, proposalCount, "Should create two proposals");
    
    // Verify each proposal has correct activity
    select proposal where proposal.ActivityNumber == 'ACT001';
    this.assertNotEqual(0, proposal.RecId, "Should find proposal for ACT001");
    
    select proposal where proposal.ActivityNumber == 'ACT002';
    this.assertNotEqual(0, proposal.RecId, "Should find proposal for ACT002");
}
```

#### TEST-003: Null Activity Filtering

**Objective**: Verify transactions without activity are excluded

```xpp
[TestMethod]
public void testNullActivityFiltering()
{
    // Arrange
    this.createEmplTransaction('TRANS001', 'ACT001', 100);
    this.createEmplTransaction('TRANS002', '', 150); // No activity
    
    // Act
    ProjInvoiceProposalCreateLines batch = ProjInvoiceProposalCreateLines::construct();
    batch.parmProjInvoiceProjId(projTable.ProjId);
    batch.run();
    
    // Assert
    ProjProposalJour proposal;
    ProjProposalEmplDetail detailLine;
    int lineCount = 0;
    
    select proposal where proposal.ActivityNumber == 'ACT001';
    
    while select detailLine
        where detailLine.ProjProposalId == proposal.ProjProposalId
    {
        lineCount++;
    }
    
    this.assertEquals(1, lineCount, "Should only include transaction with activity");
    
    // Verify transaction without activity was not included
    ProjEmplTransSale trans;
    select trans where trans.TransId == 'TRANS002';
    this.assertEquals(ProjInvoiceStatus::Never, trans.InvoiceStatus, 
                     "Transaction without activity should remain uninvoiced");
}
```

#### TEST-004: Mixed Transaction Types

**Objective**: Verify multiple transaction types with same activity group correctly

```xpp
[TestMethod]
public void testMixedTransactionTypes()
{
    // Arrange
    this.createEmplTransaction('TRANS001', 'ACT001', 100);    // Hour
    this.createCostTransaction('TRANS002', 'ACT001', 50);     // Expense
    this.createItemTransaction('TRANS003', 'ACT001', 200);    // Item
    
    // Act
    ProjInvoiceProposalCreateLines batch = ProjInvoiceProposalCreateLines::construct();
    batch.parmProjInvoiceProjId(projTable.ProjId);
    batch.run();
    
    // Assert
    ProjProposalJour proposal;
    int proposalCount = 0;
    
    while select proposal
        where proposal.ActivityNumber == 'ACT001'
    {
        proposalCount++;
    }
    
    this.assertEquals(1, proposalCount, "Should create one proposal for all types");
    
    // Verify all transaction types are included
    ProjProposalEmpl emplProposal;
    select emplProposal where emplProposal.ProjProposalId == proposal.ProjProposalId;
    this.assertNotEqual(0, emplProposal.RecId, "Should have hour proposal");
    
    ProjProposalCost costProposal;
    select costProposal where costProposal.ProjProposalId == proposal.ProjProposalId;
    this.assertNotEqual(0, costProposal.RecId, "Should have expense proposal");
    
    ProjProposalItem itemProposal;
    select itemProposal where itemProposal.ProjProposalId == proposal.ProjProposalId;
    this.assertNotEqual(0, itemProposal.RecId, "Should have item proposal");
}
```

#### TEST-005: Existing Proposal Matching

**Objective**: Verify new transactions are added to existing proposals with same grouping

```xpp
[TestMethod]
public void testExistingProposalMatching()
{
    // Arrange - Create first proposal
    this.createEmplTransaction('TRANS001', 'ACT001', 100);
    ProjInvoiceProposalCreateLines batch = ProjInvoiceProposalCreateLines::construct();
    batch.parmProjInvoiceProjId(projTable.ProjId);
    batch.run();
    
    ProjProposalJour existingProposal;
    select existingProposal where existingProposal.ActivityNumber == 'ACT001';
    RecId existingRecId = existingProposal.RecId;
    
    // Act - Create second transaction with same activity
    this.createEmplTransaction('TRANS002', 'ACT001', 150);
    batch = ProjInvoiceProposalCreateLines::construct();
    batch.parmProjInvoiceProjId(projTable.ProjId);
    batch.run();
    
    // Assert - Should use same proposal
    int proposalCount = 0;
    ProjProposalJour proposal;
    
    while select proposal
        where proposal.ActivityNumber == 'ACT001'
    {
        proposalCount++;
    }
    
    this.assertEquals(1, proposalCount, "Should still have only one proposal");
    
    // Verify it's the same proposal
    select proposal where proposal.ActivityNumber == 'ACT001';
    this.assertEquals(existingRecId, proposal.RecId, "Should use existing proposal");
    
    // Verify both transactions are in the proposal
    ProjProposalEmplDetail detailLine;
    int lineCount = 0;
    
    while select detailLine
        where detailLine.ProjProposalId == proposal.ProjProposalId
    {
        lineCount++;
    }
    
    this.assertEquals(2, lineCount, "Should have two detail lines");
}
```

#### TEST-006: Funding Source Combination

**Objective**: Verify activity + funding source creates separate proposals

```xpp
[TestMethod]
public void testFundingSourceCombination()
{
    // Arrange
    this.createEmplTransaction('TRANS001', 'ACT001', 100, 'FUND1');
    this.createEmplTransaction('TRANS002', 'ACT001', 150, 'FUND2');
    
    // Act
    ProjInvoiceProposalCreateLines batch = ProjInvoiceProposalCreateLines::construct();
    batch.parmProjInvoiceProjId(projTable.ProjId);
    batch.run();
    
    // Assert - Should create two proposals (same activity, different funding)
    int proposalCount = 0;
    ProjProposalJour proposal;
    
    while select proposal
        where proposal.ActivityNumber == 'ACT001'
    {
        proposalCount++;
    }
    
    this.assertEquals(2, proposalCount, "Should create separate proposals per funding source");
}
```

#### TEST-007: Performance Test

**Objective**: Verify acceptable performance with large datasets

```xpp
[TestMethod]
public void testPerformanceWithLargeDataset()
{
    // Arrange - Create 1000 transactions across 10 activities
    for (int i = 1; i <= 1000; i++)
    {
        ActivityNumber activity = 'ACT' + (i mod 10 + 1);
        this.createEmplTransaction('TRANS' + int2Str(i), activity, 100);
    }
    
    // Act
    utcDateTime startTime = DateTimeUtil::utcNow();
    
    ProjInvoiceProposalCreateLines batch = ProjInvoiceProposalCreateLines::construct();
    batch.parmProjInvoiceProjId(projTable.ProjId);
    batch.run();
    
    utcDateTime endTime = DateTimeUtil::utcNow();
    
    // Assert
    int64 durationSeconds = DateTimeUtil::getDifference(endTime, startTime);
    
    // Should complete in under 60 seconds for 1000 transactions
    this.assertLessThan(60, durationSeconds, "Should complete in reasonable time");
    
    info(strFmt("Performance: 1000 transactions processed in %1 seconds", durationSeconds));
}
```

---

## Integration Testing

### INT-001: Full Invoice Lifecycle

**Scenario**: Create proposal → Post invoice → Verify

**Steps**:
1. Create test project with activities
2. Create transactions with ActivityNumber
3. Run invoice proposal creation
4. Verify proposals created with correct activities
5. Post invoices
6. Verify ActivityNumber carried through to posted invoice
7. Run financial reports
8. Verify activity appears correctly

**Expected Result**: ActivityNumber visible throughout lifecycle

---

### INT-002: Multiple Currency Handling

**Scenario**: Transactions in different currencies with same activity

**Steps**:
1. Create transactions: 100 USD, 100 EUR, both Activity ACT001
2. Run invoice proposal creation
3. Verify two proposals created (one per currency)
4. Verify both have ActivityNumber = 'ACT001'

**Expected Result**: Separate proposals per currency, each with activity

---

### INT-003: Credit Note with Activity

**Scenario**: Create credit note for activity-grouped invoice

**Steps**:
1. Create and post invoice with ActivityNumber
2. Create credit note for the invoice
3. Verify credit note proposal has same ActivityNumber
4. Post credit note
5. Verify activity reporting is correct

**Expected Result**: Credit note matches original invoice activity

---

### INT-004: Intercompany Invoice

**Scenario**: Intercompany project with activities

**Steps**:
1. Create intercompany project
2. Create transactions with ActivityNumber in borrowing company
3. Run invoice proposal in lending company
4. Verify ActivityNumber transferred correctly
5. Post both intercompany invoices

**Expected Result**: Activity consistent across companies

---

### INT-005: Retention Release

**Scenario**: Release retention with activity grouping

**Steps**:
1. Create project with retention enabled
2. Post invoice with ActivityNumber (retains 10%)
3. Release retention
4. Verify retention proposal has same ActivityNumber
5. Post retention invoice

**Expected Result**: Retention matched to original activity

---

## System Testing

### SYS-001: UI Form Testing

**Test**: Invoice proposal list page

**Steps**:
1. Navigate to Project management > Invoices > Invoice proposals
2. Verify ActivityNumber column visible
3. Filter by ActivityNumber
4. Sort by ActivityNumber
5. Open proposal details
6. Verify ActivityNumber displayed in header

**Expected**: Field visible and functional in all forms

---

### SYS-002: Reporting Integration

**Test**: Standard project reports

**Steps**:
1. Run "Invoice proposal" report
2. Verify ActivityNumber included
3. Run "Project invoicing status" report
4. Verify activity grouping
5. Run custom BI reports
6. Verify activity data available

**Expected**: ActivityNumber available in all reports

---

### SYS-003: Security Testing

**Test**: Role-based access

**Steps**:
1. Test with Project Manager role
2. Test with Accountant role
3. Test with Viewer role
4. Verify appropriate access to ActivityNumber field

**Expected**: Field security follows table security

---

### SYS-004: Batch Job Testing

**Test**: Scheduled batch execution

**Steps**:
1. Set up recurring batch job
2. Configure parameters
3. Run batch
4. Monitor execution
5. Review batch log
6. Verify proposals created correctly

**Expected**: Batch runs successfully, log shows activity processing

---

## Regression Testing

### REG-001: Standard Grouping Still Works

**Test**: Verify customer/project/currency grouping unchanged

**Expected**: All standard grouping logic still applies

---

### REG-002: Non-Activity Scenarios

**Test**: Projects without activities still invoice

**Note**: With extension, only transactions with activities will invoice

**Expected**: Behavior change documented and communicated

---

### REG-003: Existing Customizations

**Test**: Verify other extensions still work

**Expected**: No conflicts with existing customizations

---

## User Acceptance Testing (UAT)

### UAT Scenario 1: Design Phase Invoicing

**Business Scenario**:  
Project manager completes design phase activities and wants to invoice customer.

**Steps**:
1. User enters hours/expenses for "Design Phase" activity
2. User runs invoice proposal creation
3. User reviews proposals
4. User posts invoice

**Success Criteria**:
- Only design phase transactions invoiced
- Separate proposal created for design phase
- Other activities remain uninvoiced
- Customer receives clear invoice for design phase

---

### UAT Scenario 2: Multi-Activity Project

**Business Scenario**:  
Large project with 5 activities, want to invoice 3 completed activities.

**Steps**:
1. User marks activities ACT001, ACT002, ACT003 as ready to invoice
2. User runs proposal creation
3. System creates 3 proposals (one per activity)
4. User reviews and posts

**Success Criteria**:
- 3 proposals created
- Each proposal has correct activity
- Activities ACT004, ACT005 not invoiced
- Clear activity breakdown for customer

---

### UAT Scenario 3: Missing Activity Handling

**Business Scenario**:  
User forgot to assign activity to some transactions.

**Steps**:
1. User enters transactions (some with activity, some without)
2. User runs proposal creation
3. System shows warning: "X transactions skipped"
4. User investigates missing activities
5. User assigns activities
6. User reruns proposal creation

**Success Criteria**:
- Clear warning message
- User can identify missing activities
- After assignment, all transactions invoiced

---

## Performance Testing

### Load Test Scenarios

| Scenario | Transactions | Activities | Expected Time | Max Time |
|----------|--------------|------------|---------------|----------|
| Small | 100 | 3 | 5 sec | 10 sec |
| Medium | 1,000 | 10 | 30 sec | 60 sec |
| Large | 10,000 | 50 | 5 min | 10 min |
| Extra Large | 50,000 | 100 | 30 min | 60 min |

### Performance Metrics

```xpp
// Add to code for performance monitoring
class PerfCounter
{
    int transactionsProcessed;
    int proposalsCreated;
    int cacheHits;
    int cacheMisses;
    int64 executionTimeMs;
    
    public void logMetrics()
    {
        info(strFmt("Performance Metrics:"));
        info(strFmt("  Transactions: %1", transactionsProcessed));
        info(strFmt("  Proposals: %1", proposalsCreated));
        info(strFmt("  Cache Hit Rate: %1%%", 
                   (cacheHits * 100) / (cacheHits + cacheMisses)));
        info(strFmt("  Execution Time: %1 ms", executionTimeMs));
        info(strFmt("  Avg Time per Transaction: %1 ms", 
                   executionTimeMs / transactionsProcessed));
    }
}
```

---

## Validation Queries

### Query 1: Verify All Proposals Have Activity

```sql
SELECT 
    ProjProposalId,
    ProjInvoiceProjId,
    ActivityNumber,
    CurrencyCode,
    CASE WHEN ActivityNumber IS NULL THEN 'MISSING' ELSE 'OK' END AS Status
FROM ProjProposalJour
WHERE Posted = 0
  AND CREATEDDATETIME > DATEADD(DAY, -7, GETUTCDATE())
ORDER BY Status DESC, ProjProposalId;
```

### Query 2: Verify Proposal-Transaction Activity Match

```sql
-- Check hour transactions
SELECT 
    ppj.ProjProposalId,
    ppj.ActivityNumber AS ProposalActivity,
    ets.ActivityNumber AS TransactionActivity,
    CASE WHEN ppj.ActivityNumber = ets.ActivityNumber 
         THEN 'MATCH' ELSE 'MISMATCH' END AS Status
FROM ProjProposalJour ppj
JOIN ProjProposalEmpl ppe ON ppj.ProjProposalId = ppe.ProjProposalId
JOIN ProjProposalEmplDetail pped ON ppe.RecId = pped.RefRecId
JOIN ProjEmplTransSale ets ON pped.TransId = ets.TransId
WHERE ppj.Posted = 0
  AND ppj.ActivityNumber <> ets.ActivityNumber;
-- Should return 0 rows
```

### Query 3: Activity Distribution Report

```sql
SELECT 
    ActivityNumber,
    COUNT(DISTINCT ProjProposalId) AS ProposalCount,
    SUM(InvoiceAmount) AS TotalAmount,
    AVG(InvoiceAmount) AS AvgAmount
FROM ProjProposalJour
WHERE Posted = 0
  AND ActivityNumber IS NOT NULL
GROUP BY ActivityNumber
ORDER BY TotalAmount DESC;
```

### Query 4: Transactions Without Activity

```sql
SELECT 
    'Hour' AS TransType,
    ProjId,
    TransId,
    SalesPrice * Qty AS Amount
FROM ProjEmplTransSale
WHERE ActivityNumber = ''
  AND InvoiceStatus IN (0, 1) -- Ready to invoice
UNION ALL
SELECT 
    'Expense',
    ProjId,
    TransId,
    SalesPrice * Qty
FROM ProjCostTransSale
WHERE ActivityNumber = ''
  AND InvoiceStatus IN (0, 1)
UNION ALL
SELECT 
    'Item',
    ProjId,
    TransId,
    SalesPrice * Qty
FROM ProjItemTransSale
WHERE ActivityNumber = ''
  AND InvoiceStatus IN (0, 1)
ORDER BY ProjId, TransType;
```

---

## Test Data Cleanup

```sql
-- Clean up test proposals
DELETE FROM ProjProposalJour
WHERE ProjInvoiceProjId LIKE 'TEST%'
  AND Posted = 0;

-- Clean up test transactions
DELETE FROM ProjEmplTransSale WHERE ProjId LIKE 'TEST%';
DELETE FROM ProjCostTransSale WHERE ProjId LIKE 'TEST%';
DELETE FROM ProjItemTransSale WHERE ProjId LIKE 'TEST%';

-- Clean up test projects
DELETE FROM ProjTable WHERE ProjId LIKE 'TEST%';
```

---

## Test Sign-Off

### Test Completion Checklist

- [ ] All unit tests passed
- [ ] All integration tests passed
- [ ] System tests passed
- [ ] Regression tests passed
- [ ] UAT scenarios completed
- [ ] Performance tests meet SLAs
- [ ] Security testing passed
- [ ] Documentation reviewed
- [ ] Training materials validated
- [ ] Rollback procedure tested

### Sign-Off

| Role | Name | Signature | Date |
|------|------|-----------|------|
| QA Lead | ____________ | ____________ | ______ |
| Technical Lead | ____________ | ____________ | ______ |
| Business Owner | ____________ | ____________ | ______ |
| Project Manager | ____________ | ____________ | ______ |

---

**Document Version**: 1.0  
**Last Updated**: 2025-11-16  
**Test Environment**: [Specify environment]  
**Test Period**: [Specify dates]
