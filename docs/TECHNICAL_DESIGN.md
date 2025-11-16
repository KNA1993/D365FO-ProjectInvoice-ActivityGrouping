# Technical Design: Activity Number Grouping for Project Invoice Proposals

## Architecture Overview

### System Context

```
┌─────────────────────────────────────────┐
│   Standard D365 F&O Invoice Proposal      │
│                                           │
│  ┌─────────────────────────────────┐  │
│  │ Transaction Selection          │  │
│  │ (ProjInvoiceProposalCreate)   │  │
│  └─────────────┬──────────────────┘  │
│                 │                       │
│       ┌─────────┴─────────┐           │
│       │  EXTENSION POINT   │           │
│       │  Filter by Activity │           │
│       └─────────┬─────────┘           │
│                 │                       │
│  ┌────────────────┴─────────────────┐  │
│  │ Proposal Line Creation         │  │
│  │ (ProjInvoiceProposalInsert)    │  │
│  └─────────────┬──────────────────┘  │
│                 │                       │
│       ┌─────────┴─────────┐           │
│       │  EXTENSION POINT   │           │
│       │  Group by Activity  │           │
│       └─────────┬─────────┘           │
│                 │                       │
│                 v                       │
│        ProjProposalJour                 │
│        + ActivityNumber                 │
└─────────────────────────────────────────┘
```

---

## Data Model

### Table Extensions

#### ProjProposalJour (Enhanced)

```
ProjProposalJour
├── ProjProposalId (PK)
├── ProjInvoiceProjId
├── CurrencyCode
├── CustAccount
├── InvoiceDate
├── Posted
└── ActivityNumber ⭐ NEW FIELD

Indexes:
- ActivityNumberIdx (ActivityNumber)
- Existing standard indexes remain
```

### Transaction Tables (Source of ActivityNumber)

```
ProjEmplTransSale        ProjCostTransSale
├── RecId               ├── RecId
├── TransId             ├── TransId
├── ProjId              ├── ProjId
├── ActivityNumber      ├── ActivityNumber
└── ...                 └── ...

ProjItemTransSale        ProjRevenueTransSale
├── RecId               ├── RecId
├── TransId             ├── TransId
├── ProjId              ├── ProjId
├── ActivityNumber      ├── ActivityNumber
└── ...                 └── ...
```

---

## Class Architecture

### Extension Pattern: Chain of Command (CoC)

#### Why Chain of Command?

✅ **Advantages:**
- Non-intrusive: Doesn't modify base code
- Upgrade-safe: Survives platform updates
- Maintainable: Clear separation of concerns
- Microsoft recommended pattern

❌ **Not Using:**
- Event handlers (less flexible for this use case)
- Overlayering (deprecated, breaks upgrades)
- Direct modification (impossible in cloud)

### Class Extension 1: ProjInvoiceProposalCreateLines_ActivityExtension

**Purpose**: Filter transactions during selection phase

```xpp
[ExtensionOf(classStr(ProjInvoiceProposalCreateLines))]
final class ProjInvoiceProposalCreateLines_ActivityExtension
{
    // State
    private int skippedTransactionsCount;
    
    // Extended Methods:
    // - runEmplQuery()      : Add ActivityNumber filter
    // - runCostQuery()      : Add ActivityNumber filter
    // - runItemQuery()      : Add ActivityNumber filter
    // - runRevenueQuery()   : Add ActivityNumber filter
    // - runOnAccountQuery() : Add ActivityNumber filter
    // - run()              : Provide summary
}
```

**Key Logic:**

```xpp
public int runEmplQuery(Query _query)
{
    QueryBuildDataSource qbds;
    QueryBuildRange qbr;
    
    qbds = _query.dataSourceTable(tableNum(ProjEmplTransSale));
    
    if (qbds)
    {
        // Only select transactions WITH ActivityNumber
        qbr = qbds.addRange(fieldNum(ProjEmplTransSale, ActivityNumber));
        qbr.value(SysQuery::valueNotEmpty());
        qbr.status(RangeStatus::Locked);
    }
    
    return next runEmplQuery(_query);
}
```

### Class Extension 2: ProjInvoiceProposalInsertLines_ActivityExtension

**Purpose**: Group proposals by ActivityNumber

```xpp
[ExtensionOf(classStr(ProjInvoiceProposalInsertLines))]
final class ProjInvoiceProposalInsertLines_ActivityExtension
{
    // State
    private ActivityNumber currentActivityNumber;
    private Map activityProposalMap; // Cache
    
    // Extended Methods:
    // - initPreRun()                         : Initialize state
    // - isSetProjProposalJour()              : Check if new proposal needed
    // - setProjProposalJour()                : Create/find proposal
    // - getActivityNumberFromTransaction()   : Extract activity from transaction
    // - validateProposalActivityConsistency(): Validate consistency
    // - updateInvoice()                      : Run validation
}
```

**Key Logic Flow:**

```
1. Transaction arrives
   ↓
2. getActivityNumberFromTransaction()
   - Check transaction type
   - Retrieve ActivityNumber from appropriate Sale table
   ↓
3. isSetProjProposalJour()
   - Compare with currentActivityNumber
   - Return true if changed (need new proposal)
   ↓
4. setProjProposalJour()
   - Check cache for existing proposal
   - If not found, check database
   - If still not found, create new
   - Set ActivityNumber on proposal
   - Add to cache
   ↓
5. Process transaction lines
   ↓
6. updateInvoice()
   - Validate all lines have same activity
   - Validate header matches lines
```

---

## Process Flow

### Standard vs Enhanced Flow

#### Standard Flow:

```
User: Create Invoice Proposals
  ↓
Select all eligible transactions
  ↓
Group by: Customer + Project + Currency + Funding
  ↓
Create proposals
  ↓
Done
```

#### Enhanced Flow:

```
User: Create Invoice Proposals
  ↓
Select transactions WITH ActivityNumber only ⭐
  ↓
Group by: Customer + Project + Currency + Funding + ActivityNumber ⭐
  ↓
Create proposals (one per activity) ⭐
  ↓
Validate activity consistency ⭐
  ↓
Report skipped transactions ⭐
  ↓
Done
```

### Detailed Sequence Diagram

```
User          CreateLines          InsertLines         Database
 |                |                      |                  |
 |--Run()-------->|                      |                  |
 |                |                      |                  |
 |                |--Query Empl Trans--->|                  |
 |                |  + Filter Activity   |                  |
 |                |                      |                  |
 |                |--Query Cost Trans--->|                  |
 |                |  + Filter Activity   |                  |
 |                |                      |                  |
 |                |--[Repeat for all]-->|                  |
 |                |                      |                  |
 |                |--Process Lines------>|                  |
 |                |                      |                  |
 |                |                      |--Get Activity--->|
 |                |                      |  from Trans      |
 |                |                      |<-----------------||
 |                |                      |                  |
 |                |                      |--Check if------->|
 |                |                      |  new proposal    |
 |                |                      |  needed          |
 |                |                      |                  |
 |                |                      |--Create/Find---->|
 |                |                      |  Proposal        |
 |                |                      |<-----------------||
 |                |                      |                  |
 |                |                      |--Set Activity--->|
 |                |                      |  on Proposal     |
 |                |                      |<-----------------||
 |                |                      |                  |
 |                |                      |--Validate------->|
 |                |                      |  Consistency     |
 |                |                      |<-----------------||
 |                |<---------------------|                  |
 |                |                      |                  |
 |<--Complete-----|                      |                  |
 |  (with summary)|                      |                  |
```

---

## Algorithm Details

### Transaction Filtering Algorithm

```
FOR EACH transaction type (Hour, Cost, Item, Revenue, OnAccount)
  GET query for transaction type
  
  FIND data source in query
  
  IF data source found THEN
    ADD range to query:
      - Field: ActivityNumber
      - Value: NOT EMPTY
      - Status: LOCKED (user cannot modify)
  END IF
  
  EXECUTE query
  
  COUNT results
  
  IF count = 0 THEN
    LOG info: "No transactions with Activity Number"
  END IF
  
  RETURN count
END FOR
```

### Activity Grouping Algorithm

```
INITIALIZE:
  currentActivityNumber = ''
  activityProposalMap = new Map()

FOR EACH transaction in temporary table
  
  // Extract activity from transaction
  transActivity = GetActivityFromTransaction(transaction)
  
  IF transActivity is empty THEN
    WARNING: Transaction skipped
    CONTINUE to next transaction
  END IF
  
  // Check if activity changed
  IF transActivity != currentActivityNumber THEN
    needNewProposal = TRUE
    currentActivityNumber = transActivity
  ELSE
    needNewProposal = FALSE
  END IF
  
  IF needNewProposal THEN
    // Build cache key
    cacheKey = projInvoiceProjId + currency + fundingSource + activity
    
    // Check cache
    IF cacheKey exists in activityProposalMap THEN
      proposal = GET from cache
    ELSE
      // Check database
      proposal = FIND in database WHERE
        - ProjInvoiceProjId matches
        - CurrencyCode matches
        - ActivityNumber matches
        - Not posted
      
      IF proposal not found THEN
        // Create new
        proposal = CREATE new proposal
        SET proposal.ActivityNumber = transActivity
        SAVE proposal
      END IF
      
      // Add to cache
      activityProposalMap.INSERT(cacheKey, proposal)
    END IF
  END IF
  
  // Add transaction lines to proposal
  ADD transaction to proposal
  
END FOR

// Validation
FOR EACH created proposal
  VALIDATE all lines have same ActivityNumber
  VALIDATE header ActivityNumber matches lines
END FOR
```

### GetActivityFromTransaction Algorithm

```
FUNCTION GetActivityFromTransaction(tmpTransaction)
  
  SWITCH tmpTransaction.TransType
    
    CASE Hour:
      emplTrans = FIND ProjEmplTransSale BY tmpTransaction.RefRecId
      RETURN emplTrans.ActivityNumber
    
    CASE Expense:
      costTrans = FIND ProjCostTransSale BY tmpTransaction.RefRecId
      RETURN costTrans.ActivityNumber
    
    CASE Item:
      itemTrans = FIND ProjItemTransSale BY tmpTransaction.RefRecId
      RETURN itemTrans.ActivityNumber
    
    CASE Revenue:
      revenueTrans = FIND ProjRevenueTransSale BY tmpTransaction.RefRecId
      RETURN revenueTrans.ActivityNumber
    
    CASE OnAccount:
      // Check if field exists first
      IF ActivityNumber field exists on ProjOnAccTransSale THEN
        onAccTrans = FIND ProjOnAccTransSale BY tmpTransaction.RefRecId
        RETURN onAccTrans.ActivityNumber
      END IF
    
  END SWITCH
  
  // Should never reach here due to filtering
  WARNING: "Transaction missing ActivityNumber"
  RETURN ''
  
END FUNCTION
```

---

## Performance Considerations

### Caching Strategy

**Problem**: Multiple database queries to find existing proposals

**Solution**: In-memory Map cache

```xpp
private Map activityProposalMap;
// Key: "ProjInvoiceProjId|Currency|FundingSource|Activity"
// Value: ProjProposalJour.RecId
```

**Benefits**:
- O(1) lookup time
- Reduces database round-trips
- Cleared on each job run (no stale data)

### Index Strategy

**New Index on ProjProposalJour**:

```xml
<AxTableIndex>
  <Name>ActivityNumberIdx</Name>
  <Fields>
    <Field>ActivityNumber</Field>
  </Fields>
</AxTableIndex>
```

**Query Pattern**:
```sql
SELECT * FROM ProjProposalJour
WHERE ProjInvoiceProjId = ?
  AND CurrencyCode = ?
  AND ActivityNumber = ?
  AND Posted = 0;
```

**Optimization**: Consider compound index if queries always include multiple fields:

```xml
<AxTableIndex>
  <Name>ActivityCurrencyPostedIdx</Name>
  <Fields>
    <Field>ActivityNumber</Field>
    <Field>CurrencyCode</Field>
    <Field>Posted</Field>
  </Fields>
</AxTableIndex>
```

### Query Optimization

**Transaction Selection**:
- Filters applied at query level (SQL WHERE clause)
- No post-fetch filtering in X++
- Locked range prevents user override

**Batch Processing**:
- Existing batch framework used
- No additional threading needed
- Natural pause points for large volumes

---

## Error Handling

### Validation Layers

1. **Query Level** (First line of defense)
   - Filter transactions without ActivityNumber
   - Cannot be bypassed by user

2. **Business Logic Level**
   - Verify ActivityNumber before creating proposal
   - Throw error if missing (should never happen)

3. **Data Integrity Level**
   - Validate all lines match header
   - Validate no mixed activities in one proposal

### Error Messages

```xpp
// Information
info("Processing transactions with Activity Number");
info(strFmt("%1 transactions processed", count));

// Warning
warning(strFmt("%1 transactions skipped (no Activity Number)", skipped));
warning("Transaction %1 missing Activity Number - skipped");

// Error (stops processing)
error("Cannot create proposal without Activity Number");
error("Proposal %1 contains multiple Activity Numbers");
error("Proposal %1 activity mismatch between header and lines");
```

---

## Security

### No Additional Privileges Required

- Uses existing `ProjInvoiceProposalCreate` privilege
- ActivityNumber field inherits table-level security
- No new security roles needed

### Audit Trail

- ActivityNumber stored on proposal (auditable)
- Standard D365 change tracking applies
- Infolog provides operation history

---

## Integration Points

### Upstream Dependencies

- Transaction entry (must populate ActivityNumber)
- Project setup (ActivityNumber must be valid)

### Downstream Dependencies

- Invoice posting (reads ActivityNumber from proposal)
- Reporting (can filter/group by ActivityNumber)
- Analytics (ActivityNumber available for BI)

### External Systems

- **None directly affected**
- If integrations read invoice proposals, they will see new field
- Backward compatible (field can be null/empty)

---

## Scalability

### Volume Handling

**Small Volume** (<1000 transactions)
- No special handling needed
- Direct processing

**Medium Volume** (1000-10000 transactions)
- Cache provides benefit
- Batch processing helps

**Large Volume** (>10000 transactions)
- Consider splitting by project/date range
- Monitor memory usage
- Use batch recurrence for scheduling

### Concurrency

**Single User**: No issues

**Multiple Users**:
- Standard D365 locking applies
- Optimistic concurrency control
- Last-write-wins for proposal creation

---

## Monitoring & Observability

### Key Metrics to Track

```xpp
// Log these in production
- Number of proposals created per run
- Number of transactions processed
- Number of transactions skipped
- Execution time
- Number of unique activities processed
- Cache hit rate
```

### Logging Strategy

```xpp
info("Starting invoice proposal creation with Activity grouping");
info(strFmt("Processed: %1 | Skipped: %2 | Proposals: %3", 
           processed, skipped, proposalsCreated));
info(strFmt("Execution time: %1 seconds", executionTime));
```

---

## Future Enhancements

### Potential Improvements

1. **Configuration Parameter**
   - Allow enable/disable via parameters
   - Project-type specific rules

2. **Bulk Activity Assignment**
   - Tool to assign activities to existing transactions
   - Validation before assignment

3. **Activity Hierarchy**
   - Support parent-child activity relationships
   - Roll-up invoicing

4. **Advanced Filtering**
   - Include/exclude specific activities
   - Activity-based invoice templates

5. **Analytics Dashboard**
   - Invoice readiness by activity
   - Activity-based revenue recognition

---

## Technical Debt

### Known Limitations

1. **No backward population**
   - Existing proposals won't have ActivityNumber
   - Requires manual update or accept gap

2. **OnAccount handling**
   - Assumes ActivityNumber field exists
   - Needs runtime check

3. **No activity validation**
   - Doesn't validate if ActivityNumber is valid/active
   - Assumes data integrity upstream

### Recommended Future Work

- Add activity validation against master data
- Create activity assignment wizard
- Implement activity-based approval workflows
- Add activity to proposal posting integration

---

**Document Version**: 1.0  
**Last Updated**: 2025-11-16  
**Author**: Technical Architecture Team
