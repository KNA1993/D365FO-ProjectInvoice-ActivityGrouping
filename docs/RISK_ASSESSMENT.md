# Risk Assessment: Activity Number Grouping for Project Invoice Proposals

## Executive Summary

| Risk Level | Count | Percentage |
|-----------|-------|------------|
| 🔴 Critical | 3 | 15% |
| 🟠 High | 5 | 25% |
| 🟡 Medium | 8 | 40% |
| 🟢 Low | 4 | 20% |
| **Total** | **20** | **100%** |

**Overall Risk Rating**: 🟠 **HIGH**

**Recommendation**: Proceed with caution. Extensive testing required before production deployment.

---

## Critical Risks (🔴)

### RISK-001: Breaking Change in Business Logic

**Category**: Business Impact  
**Likelihood**: 🔴 Certain  
**Impact**: 🔴 Severe

**Description**:  
The extension fundamentally changes invoice proposal behavior. Transactions **without** ActivityNumber will be **excluded** from proposals.

**Before**:
```
All eligible transactions → Invoice proposal
```

**After**:
```
Only transactions with ActivityNumber → Invoice proposal
Transactions without ActivityNumber → SKIPPED
```

**Impact**:
- Users may not invoice all transactions
- Revenue recognition could be delayed
- Month-end close could be blocked
- Customer invoicing delayed

**Mitigation**:
1. ✅ **User Communication**
   - Send notification 2 weeks before deployment
   - Explain new requirement
   - Provide training

2. ✅ **Data Preparation**
   - Run report: Transactions without ActivityNumber
   - Assign activities before go-live
   - Set deadline for activity assignment

3. ✅ **Validation Report**
   ```sql
   -- Identify at-risk transactions
   SELECT 
       ProjId,
       TransType,
       COUNT(*) AS UnassignedCount,
       SUM(SalesPrice * Qty) AS TotalAmount
   FROM (
       SELECT ProjId, 'Hour' AS TransType, SalesPrice, Qty 
       FROM ProjEmplTransSale 
       WHERE ActivityNumber = '' AND InvoiceStatus = 'Ready'
       UNION ALL
       SELECT ProjId, 'Expense', SalesPrice, Qty 
       FROM ProjCostTransSale 
       WHERE ActivityNumber = '' AND InvoiceStatus = 'Ready'
       -- Add other transaction types
   ) AS AllTrans
   GROUP BY ProjId, TransType
   HAVING COUNT(*) > 0;
   ```

4. ✅ **Fallback Option**
   - Implement feature flag to disable if needed
   - Document rollback procedure

**Residual Risk**: 🟡 **MEDIUM** (after mitigation)

---

### RISK-002: ActivityNumber Field Missing on Transaction Tables

**Category**: Technical  
**Likelihood**: 🟡 Possible  
**Impact**: 🔴 Critical

**Description**:  
Code assumes ActivityNumber field exists on all transaction sale tables. If missing, code will throw runtime errors.

**Affected Tables**:
- ProjEmplTransSale
- ProjCostTransSale
- ProjItemTransSale
- ProjRevenueTransSale
- ProjOnAccTransSale

**Impact**:
- Runtime errors during invoice creation
- Job fails completely
- No invoices created

**Mitigation**:
1. ✅ **Pre-Deployment Validation**
   ```sql
   -- Run this BEFORE deploying
   SELECT 
       TABLE_NAME,
       CASE WHEN EXISTS (
           SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
           WHERE TABLE_NAME = t.TABLE_NAME 
           AND COLUMN_NAME = 'ACTIVITYNUMBER'
       ) THEN 'OK' ELSE 'MISSING' END AS Status
   FROM (
       SELECT 'PROJEMPLTRANSSALE' AS TABLE_NAME
       UNION SELECT 'PROJCOSTTRANSSALE'
       UNION SELECT 'PROJITEMTRANSSALE'
       UNION SELECT 'PROJREVENUETRANSSALE'
       UNION SELECT 'PROJONACCTRANSSALE'
   ) t;
   ```

2. ✅ **Runtime Field Check**
   ```xpp
   // Add to code
   DictTable dt = new DictTable(tableNum(ProjEmplTransSale));
   if (!dt.fieldObject(fieldNum(ProjEmplTransSale, ActivityNumber)))
   {
       throw error("ActivityNumber field missing on ProjEmplTransSale");
   }
   ```

3. ✅ **Graceful Degradation**
   ```xpp
   // For optional tables like OnAccount
   if (DictTable::new(tableNum(ProjOnAccTransSale))
       .fieldObject(fieldNum(ProjOnAccTransSale, ActivityNumber)))
   {
       // Use ActivityNumber
   }
   else
   {
       // Skip ActivityNumber logic for this table
       info("ActivityNumber not available on OnAccount transactions");
   }
   ```

**Residual Risk**: 🟢 **LOW** (after validation)

---

### RISK-003: Data Inconsistency in Existing Proposals

**Category**: Data Integrity  
**Likelihood**: 🔴 Certain  
**Impact**: 🟠 High

**Description**:  
Proposals created before extension deployment won't have ActivityNumber. Queries filtering by ActivityNumber will miss these records.

**Impact**:
- Incomplete reporting
- Analytics gaps
- Historical data not comparable
- Reconciliation issues

**Mitigation**:
1. ✅ **Accept Gap** (Recommended for most)
   - Document cutoff date
   - Note in reports: "ActivityNumber available from [date]"
   - Keep separate queries for historical data

2. ✅ **Backfill Data** (If needed)
   ```sql
   -- Backfill script
   UPDATE pp
   SET pp.ActivityNumber = (
       SELECT TOP 1 t.ActivityNumber
       FROM (
           SELECT pps.ProjProposalId, ets.ActivityNumber
           FROM ProjProposalEmpl ppe
           JOIN ProjProposalEmplDetail pped ON ppe.RecId = pped.RefRecId
           JOIN ProjEmplTransSale ets ON pped.TransId = ets.TransId
           WHERE ppe.ProjProposalId = pp.ProjProposalId
           UNION
           SELECT pps.ProjProposalId, cts.ActivityNumber
           FROM ProjProposalCost ppc
           JOIN ProjProposalCostDetail ppcd ON ppc.RecId = ppcd.RefRecId
           JOIN ProjCostTransSale cts ON ppcd.TransId = cts.TransId
           WHERE ppc.ProjProposalId = pp.ProjProposalId
           -- Add other transaction types
       ) t
       WHERE t.ProjProposalId = pp.ProjProposalId
   )
   FROM ProjProposalJour pp
   WHERE pp.ActivityNumber IS NULL
     AND pp.Posted = 0; -- Only unposted proposals
   ```

3. ✅ **Mixed Activity Handling**
   - If proposal has multiple activities, choose most common
   - Or flag for manual review
   - Or skip backfill for mixed proposals

**Residual Risk**: 🟡 **MEDIUM** (accept gap) or 🟢 **LOW** (backfill)

---

## High Risks (🟠)

### RISK-004: Performance Degradation

**Category**: Performance  
**Likelihood**: 🟡 Possible  
**Impact**: 🟠 High

**Description**:  
Additional filtering and grouping logic may slow down invoice proposal creation, especially for high-volume projects.

**Baseline Performance** (Standard):
```
1,000 transactions: 30 seconds
10,000 transactions: 5 minutes
50,000 transactions: 30 minutes
```

**Expected Performance** (With Extension):
```
1,000 transactions: 35 seconds (+17%)
10,000 transactions: 6.5 minutes (+30%)
50,000 transactions: 45 minutes (+50%)
```

**Impact**:
- Longer processing times
- Batch job timeouts
- User frustration
- Month-end delays

**Mitigation**:
1. ✅ **Indexing**
   ```xml
   <!-- On ProjProposalJour -->
   <AxTableIndex>
     <Name>ActivityCurrencyPostedIdx</Name>
     <Fields>
       <Field>ActivityNumber</Field>
       <Field>CurrencyCode</Field>
       <Field>Posted</Field>
     </Fields>
   </AxTableIndex>
   
   <!-- On transaction tables (if not exist) -->
   <AxTableIndex>
     <Name>ActivityStatusIdx</Name>
     <Fields>
       <Field>ActivityNumber</Field>
       <Field>InvoiceStatus</Field>
     </Fields>
   </AxTableIndex>
   ```

2. ✅ **Caching**
   - Already implemented: `activityProposalMap`
   - Cache hit rate target: >80%

3. ✅ **Query Optimization**
   ```xpp
   // Use exists joins instead of full joins
   qbr.value(SysQuery::valueNotEmpty()); // Optimized for SQL
   ```

4. ✅ **Batch Size Tuning**
   - Split large jobs into smaller batches
   - Process by date range
   - Process by project

5. ✅ **Performance Testing**
   - Load test with production volumes
   - Measure before/after
   - Set performance SLAs

**Monitoring**:
```xpp
// Add to code
StartDateTime start = DateTimeUtil::utcNow();
// ... processing ...
int64 duration = DateTimeUtil::getDifference(DateTimeUtil::utcNow(), start);
info(strFmt("Processing time: %1 seconds", duration));
```

**Residual Risk**: 🟡 **MEDIUM**

---

### RISK-005: User Training & Adoption

**Category**: Business/User  
**Likelihood**: 🟠 Likely  
**Impact**: 🟡 Medium

**Description**:  
Users may not understand:
- Why transactions are skipped
- Need to assign ActivityNumber
- New proposal grouping behavior

**Impact**:
- Support tickets
- Workarounds
- Data quality issues
- User frustration

**Mitigation**:
1. ✅ **Training Materials**
   - User guide (see docs/USER_GUIDE.md)
   - Video tutorials
   - Quick reference card

2. ✅ **Communication Plan**
   ```
   Week -2: Announcement email
   Week -1: Training sessions
   Day 0:   Go-live support
   Week +1: Follow-up training
   Week +2: Feedback collection
   ```

3. ✅ **Help Text & Messages**
   - Clear infolog messages
   - Helpful error messages
   - Link to documentation

4. ✅ **Support Readiness**
   - FAQ document
   - Known issues list
   - Escalation path

**Residual Risk**: 🟡 **MEDIUM**

---

### RISK-006: Funding Source + Activity Conflicts

**Category**: Business Logic  
**Likelihood**: 🟡 Possible  
**Impact**: 🟠 High

**Description**:  
One activity might span multiple funding sources, or one funding source might have multiple activities. Current implementation creates separate proposals for each combination.

**Example**:
```
Activity A + Funding Source 1 → Proposal 1
Activity A + Funding Source 2 → Proposal 2
Activity B + Funding Source 1 → Proposal 3
Activity B + Funding Source 2 → Proposal 4
```

**Impact**:
- More proposals than expected
- Complex invoice management
- Customer confusion (multiple invoices)

**Decision Points**:

**Option A**: Current Implementation (Most Restrictive)
- Group by: Customer + Project + Currency + Funding + **Activity**
- Result: Maximum proposal splitting

**Option B**: Activity Priority
- Group by: Customer + Project + Currency + **Activity** only
- Result: One proposal per activity (ignores funding source)
- Risk: Funding source reporting issues

**Option C**: Funding Priority
- Group by: Customer + Project + Currency + **Funding Source** only
- Result: Activity split across proposals
- Risk: Defeats purpose of activity grouping

**Recommendation**: **Option A** (Current)
- Maintains all standard grouping
- Adds activity as additional dimension
- Most conservative approach
- Can be changed later if needed

**Mitigation**:
1. ✅ Document business rules clearly
2. ✅ Set user expectations
3. ✅ Provide proposal consolidation report
4. ✅ Consider configuration option for grouping priority

**Residual Risk**: 🟡 **MEDIUM**

---

### RISK-007: Intercompany Scenarios

**Category**: Business Logic  
**Likelihood**: 🟡 Possible  
**Impact**: 🟠 High

**Description**:  
Intercompany projects involve borrowing and lending legal entities. ActivityNumber might not synchronize across entities.

**Scenario**:
```
Lending Company (Project Owner):
  - Transaction 1: Activity = "ACT001"
  
Borrowing Company (Resource Provider):
  - Intercompany transaction: Activity = ?
```

**Questions**:
- Does intercompany transaction have ActivityNumber?
- Should it match original activity?
- Which activity takes precedence?

**Impact**:
- Mismatched proposals
- Intercompany reconciliation issues
- Incorrect activity reporting

**Mitigation**:
1. ✅ **Standard Approach**
   - Use lending company's ActivityNumber
   - Copy during intercompany creation

2. ✅ **Validation**
   ```xpp
   // During intercompany transaction creation
   if (isIntercompany)
   {
       intercompanyTrans.ActivityNumber = originalTrans.ActivityNumber;
   }
   ```

3. ✅ **Reconciliation Report**
   - Compare activities across entities
   - Flag mismatches

**Residual Risk**: 🟡 **MEDIUM**

---

### RISK-008: Credit Note Handling

**Category**: Business Logic  
**Likelihood**: 🟡 Possible  
**Impact**: 🟠 High

**Description**:  
Credit notes must reference original invoice. If original invoice has ActivityNumber, credit note proposal must match.

**Impact**:
- Credit note assigned to wrong proposal
- Activity reporting incorrect
- Revenue recognition issues

**Mitigation**:
1. ✅ **Copy from Original**
   ```xpp
   // During credit note creation
   creditNoteProposal.ActivityNumber = originalInvoice.ActivityNumber;
   ```

2. ✅ **Validation**
   - Verify credit note activity matches original
   - Block if mismatch

3. ✅ **Testing**
   - Test credit note scenarios explicitly
   - Various transaction types

**Residual Risk**: 🟢 **LOW** (with validation)

---

## Medium Risks (🟡)

### RISK-009: Partial Activity Assignment

**Description**: Project has some transactions with activities, some without  
**Mitigation**: Validation report + user training  
**Residual Risk**: 🟡 **MEDIUM**

### RISK-010: Multiple Proposals per Customer

**Description**: Customer receives multiple invoices instead of one  
**Mitigation**: User communication + explanation in proposal  
**Residual Risk**: 🟡 **MEDIUM**

### RISK-011: Reporting & Analytics Gaps

**Description**: Existing reports don't include ActivityNumber  
**Mitigation**: Update key reports + provide new activity reports  
**Residual Risk**: 🟡 **MEDIUM**

### RISK-012: Testing Coverage

**Description**: Cannot test all possible combinations  
**Mitigation**: Risk-based testing + production monitoring  
**Residual Risk**: 🟡 **MEDIUM**

### RISK-013: Integration Impact

**Description**: External systems reading proposals see new field  
**Mitigation**: Review integrations + update as needed  
**Residual Risk**: 🟡 **MEDIUM**

### RISK-014: Retention Transactions

**Description**: Retention release must match original activity  
**Mitigation**: Copy activity during retention creation  
**Residual Risk**: 🟡 **MEDIUM**

### RISK-015: Manual Proposal Editing

**Description**: Users manually add/remove lines, breaking activity consistency  
**Mitigation**: Validation on save + clear warnings  
**Residual Risk**: 🟡 **MEDIUM**

### RISK-016: Upgrade Compatibility

**Description**: Future D365 updates might conflict  
**Mitigation**: Use CoC pattern + test after each update  
**Residual Risk**: 🟡 **MEDIUM**

---

## Low Risks (🟢)

### RISK-017: Form Layout Issues

**Description**: ActivityNumber field doesn't fit in form  
**Mitigation**: Adjust form layout  
**Residual Risk**: 🟢 **LOW**

### RISK-018: Label Translation

**Description**: Labels only in English  
**Mitigation**: Add translations as needed  
**Residual Risk**: 🟢 **LOW**

### RISK-019: Security Privilege Updates

**Description**: New field might need security updates  
**Mitigation**: Review and adjust privileges  
**Residual Risk**: 🟢 **LOW**

### RISK-020: Documentation Maintenance

**Description**: Documentation gets outdated  
**Mitigation**: Regular reviews + update process  
**Residual Risk**: 🟢 **LOW**

---

## Risk Mitigation Timeline

### Pre-Deployment (Weeks -4 to -1)

**Week -4:**
- ☐ Run field validation query
- ☐ Identify transactions without activity
- ☐ Create activity assignment plan

**Week -3:**
- ☐ Assign activities to transactions
- ☐ Create training materials
- ☐ Set up test environment

**Week -2:**
- ☐ User training sessions
- ☐ Integration testing
- ☐ Performance testing

**Week -1:**
- ☐ Final validation
- ☐ Deployment rehearsal
- ☐ Communication to users

### Deployment (Day 0)

- ☐ Deploy during maintenance window
- ☐ Run validation queries
- ☐ Test with small dataset
- ☐ Monitor closely

### Post-Deployment (Weeks +1 to +4)

**Week +1:**
- ☐ Daily monitoring
- ☐ Address support tickets
- ☐ Collect feedback

**Week +2:**
- ☐ Review performance metrics
- ☐ Identify issues
- ☐ Plan improvements

**Week +4:**
- ☐ Post-implementation review
- ☐ Document lessons learned
- ☐ Update procedures

---

## Risk Acceptance

### Risks We Accept

✅ **Historical Data Gap**
- Existing proposals won't have ActivityNumber
- **Accepted** because backfill is complex and risky

✅ **Multiple Proposals per Customer**
- Customers may receive more invoices than before
- **Accepted** because it's the desired business outcome

✅ **Slight Performance Impact**
- Processing may be 20-30% slower
- **Accepted** as tradeoff for better grouping

### Risks We Mitigate

⚠️ All critical and high risks have mitigation plans

### Risks We Monitor

👁️ All risks tracked for 90 days post-deployment

---

## Contingency Plans

### Plan A: Feature Flag Disable

**If**: Minor issues, no data corruption  
**Action**: Disable feature via Feature Management  
**Time**: < 5 minutes  
**Impact**: Reverts to standard behavior

### Plan B: Hotfix Deployment

**If**: Code bug, fixable quickly  
**Action**: Deploy patch  
**Time**: 2-4 hours  
**Impact**: Minimal

### Plan C: Full Rollback

**If**: Major issues, data integrity compromised  
**Action**: Remove package, restore database  
**Time**: 4-8 hours  
**Impact**: Significant

---

## Risk Review Schedule

| When | Action | Responsible |
|------|--------|-------------|
| Before deployment | Final risk review | Project Manager |
| Day 1 | Risk monitoring | Technical Lead |
| Week 1 | Risk assessment | Steering Committee |
| Month 1 | Risk closeout | Project Manager |
| Quarter 1 | Lessons learned | All stakeholders |

---

## Approval

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Project Sponsor | ____________ | ____________ | ______ |
| Technical Lead | ____________ | ____________ | ______ |
| Business Owner | ____________ | ____________ | ______ |
| Risk Manager | ____________ | ____________ | ______ |

---

**Document Version**: 1.0  
**Last Updated**: 2025-11-16  
**Next Review**: Before production deployment
