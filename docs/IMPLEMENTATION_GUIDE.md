# Implementation Guide: Activity Number Grouping for Project Invoice Proposals

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Step-by-Step Implementation](#step-by-step-implementation)
3. [Deployment](#deployment)
4. [Validation](#validation)
5. [Rollback Plan](#rollback-plan)

---

## Prerequisites

### Environment Requirements

- D365 F&O Development Environment (Version 10.0.x or higher)
- Visual Studio 2019 or later with D365 F&O development tools
- Your custom model created (e.g., "YourCompany_ProjectExtensions")
- Administrative access to development environment

### Data Requirements

**Verify ActivityNumber field exists on these tables:**

```sql
-- Run this validation query first
SELECT 
    'ProjEmplTransSale' AS TableName,
    CASE WHEN EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_NAME = 'PROJEMPLTRANSSALE' 
        AND COLUMN_NAME = 'ACTIVITYNUMBER'
    ) THEN 'EXISTS' ELSE 'MISSING' END AS FieldStatus
UNION ALL
SELECT 
    'ProjCostTransSale',
    CASE WHEN EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_NAME = 'PROJCOSTTRANSSALE' 
        AND COLUMN_NAME = 'ACTIVITYNUMBER'
    ) THEN 'EXISTS' ELSE 'MISSING' END
UNION ALL
SELECT 
    'ProjItemTransSale',
    CASE WHEN EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_NAME = 'PROJITEMTRANSSALE' 
        AND COLUMN_NAME = 'ACTIVITYNUMBER'
    ) THEN 'EXISTS' ELSE 'MISSING' END
UNION ALL
SELECT 
    'ProjRevenueTransSale',
    CASE WHEN EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_NAME = 'PROJREVENUETRANSSALE' 
        AND COLUMN_NAME = 'ACTIVITYNUMBER'
    ) THEN 'EXISTS' ELSE 'MISSING' END;
```

**Result should show 'EXISTS' for all tables.**

---

## Step-by-Step Implementation

### Phase 1: Create Table Extension

#### Step 1.1: Add ActivityNumber to ProjProposalJour

1. **Open Visual Studio**
2. **Open your D365 F&O project**
3. **Right-click** on your project → **Add** → **New Item**
4. **Select** "Dynamics 365 Items" → "Data Model" → **"Table Extension"**
5. **Name**: `ProjProposalJour.ActivityNumber`
6. **Target Table**: `ProjProposalJour`

**XML Content** (or use designer):

```xml
<?xml version="1.0" encoding="utf-8"?>
<AxTableExtension xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
  <Name>ProjProposalJour_ActivityNumber</Name>
  <ElementType>AxTableExtension</ElementType>
  
  <Fields>
    <AxTableField>
      <Name>ActivityNumber</Name>
      <ExtendedDataType>ActivityNumber</ExtendedDataType>
      <Label>Activity number</Label>
      <HelpText>Activity number used for grouping invoice proposals</HelpText>
      <Mandatory>No</Mandatory>
    </AxTableField>
  </Fields>
  
  <Indexes>
    <AxTableIndex>
      <Name>ActivityNumberIdx</Name>
      <AllowDuplicates>Yes</AllowDuplicates>
      <Fields>
        <AxTableIndexField>
          <DataField>ActivityNumber</DataField>
        </AxTableIndexField>
      </Fields>
    </AxTableIndex>
  </Indexes>
  
  <TargetTable>ProjProposalJour</TargetTable>
</AxTableExtension>
```

**Save and build the project.**

---

### Phase 2: Create Selection Filter Extension

#### Step 2.1: Extend ProjInvoiceProposalCreateLines

1. **Right-click** project → **Add** → **New Item**
2. **Select** "Code" → **"Class"**
3. **Name**: `ProjInvoiceProposalCreateLines_ActivityExtension`

**Copy the complete code from**: `src/ClassExtensions/ProjInvoiceProposalCreateLines_ActivityExtension.xml`

Key methods to implement:
- `runEmplQuery()` - Filter hour transactions
- `runCostQuery()` - Filter expense transactions
- `runItemQuery()` - Filter item transactions
- `runRevenueQuery()` - Filter fee transactions
- `runOnAccountQuery()` - Filter on-account transactions (if applicable)
- `run()` - Provide summary messages

**Build and verify no compilation errors.**

---

### Phase 3: Create Grouping Logic Extension

#### Step 3.1: Extend ProjInvoiceProposalInsertLines

1. **Right-click** project → **Add** → **New Item**
2. **Select** "Code" → **"Class"**
3. **Name**: `ProjInvoiceProposalInsertLines_ActivityExtension`

**Copy the complete code from**: `src/ClassExtensions/ProjInvoiceProposalInsertLines_ActivityExtension.xml`

Key methods to implement:
- `initPreRun()` - Initialize activity tracking
- `isSetProjProposalJour()` - Determine if new proposal needed
- `getActivityNumberFromTransaction()` - Extract activity from transaction
- `setProjProposalJour()` - Create/find proposal by activity
- `validateProposalActivityConsistency()` - Validate consistency
- `updateInvoice()` - Run validation after processing

**Build and verify no compilation errors.**

---

### Phase 4: Create Form Extensions (Optional)

#### Step 4.1: Extend ProjInvoiceProposalDetail Form

1. **Right-click** project → **Add** → **New Item**
2. **Select** "User Interface" → **"Form Extension"**
3. **Name**: `ProjInvoiceProposalDetail_ActivityExtension`
4. **Target Form**: `ProjInvoiceProposalDetail`

**In Form Designer:**
1. Navigate to **Design** → **Data Sources** → **ProjProposalJour**
2. Expand **Fields** → drag **ActivityNumber** to appropriate tab group
3. Set properties:
   - **Visible**: Yes
   - **Allow Edit**: No (read-only)
   - **Position**: After invoice date or appropriate location

#### Step 4.2: Extend ProjInvoiceProposalListPage Form

Repeat similar steps for the list page form to display ActivityNumber in the grid.

---

### Phase 5: Create Labels

#### Step 5.1: Add Label File

1. **Right-click** project → **Add** → **New Item**
2. **Select** "Dynamics 365 Items" → "Labels and Resources" → **"Label File"**
3. **Name**: `ActivityGrouping_en-US`

**Add these labels:**

```
SYS_ProcessingTransactionsWithActivityNumber = Processing transactions with Activity Number
SYS_TransactionsSkippedNoActivity = %1 transactions skipped (no Activity Number assigned)
SYS_NoHourTransactionsWithActivityNumber = No hour transactions with Activity Number found
SYS_TransactionMissingActivity = Transaction %1 (%2) is missing Activity Number - skipped
SYS_CannotCreateProposalWithoutActivity = Cannot create invoice proposal without Activity Number for transaction %1 in project %2
SYS_ProposalCreatedForActivity = Invoice proposal %1 created for Activity Number: %2
SYS_ProposalContainsMultipleActivities = ERROR: Invoice proposal %1 contains transactions from multiple Activity Numbers
SYS_ProposalActivityMismatch = ERROR: Invoice proposal %1 header Activity Number does not match detail lines
```

---

### Phase 6: Build and Sync

#### Step 6.1: Full Build

1. **Right-click** on your project
2. **Select** "Build"
3. **Verify** no errors in Output window

#### Step 6.2: Database Sync

1. **In Visual Studio**: Dynamics 365 → **Synchronize database...**
2. **Or via Admin URL**: `https://[your-environment]/namespaces/AXSF/?mi=SysUtilSubmitDataUpgrade`
3. **Monitor** sync completion
4. **Verify** ActivityNumber field added to ProjProposalJour table

**Validation Query:**
```sql
SELECT TOP 1 * FROM PROJPROPOSALJOUR;
-- Verify ActivityNumber column exists
```

---

## Deployment

### Development Environment

1. ✅ Build completed successfully
2. ✅ Database sync completed
3. ✅ Labels deployed
4. ✅ No compilation errors

### Test/Sandbox Environment

#### Deploy via Deployable Package

1. **Build deployable package** in Visual Studio:
   - Dynamics 365 → **Create Deployment Package**
   - Select your model
   - Output: `.zip` file

2. **Upload to LCS** (Lifecycle Services):
   - Navigate to Asset Library → Software deployable packages
   - Upload package

3. **Deploy to Sandbox**:
   - Environment details → Maintain → Apply updates
   - Select package
   - Schedule deployment

4. **Validate deployment**:
   - Log in to sandbox
   - Test invoice proposal creation
   - Verify ActivityNumber grouping

### Production Environment

**DO NOT deploy directly to production**

1. ✅ Complete all testing in sandbox
2. ✅ User acceptance testing (UAT) completed
3. ✅ Performance testing completed
4. ✅ Rollback plan documented
5. ✅ Users trained
6. ✅ Communication sent
7. **Then** schedule production deployment during maintenance window

---

## Validation

### Post-Deployment Checks

#### 1. Verify Table Extension
```sql
-- Check field exists
SELECT COLUMN_NAME, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'PROJPROPOSALJOUR' 
AND COLUMN_NAME = 'ACTIVITYNUMBER';
```

#### 2. Test Transaction Filtering

**Setup:**
- Create test project with transactions
- Assign ActivityNumber to some transactions
- Leave ActivityNumber blank on others

**Test:**
- Run "Create invoice proposals"
- Verify only transactions with ActivityNumber are included
- Check info log for skipped transaction count

#### 3. Test Activity Grouping

**Setup:**
- Create test project
- Add transactions with ActivityNumber = "ACT001"
- Add transactions with ActivityNumber = "ACT002"

**Test:**
- Run "Create invoice proposals"
- Verify **two** proposals created
- Verify each proposal contains only one ActivityNumber

#### 4. Test Existing Standard Grouping

**Verify that standard grouping still works:**
- Different currencies → separate proposals
- Different funding sources → separate proposals
- Different customers → separate proposals

---

## Rollback Plan

### If Issues Arise in Production

#### Option 1: Soft Rollback (Feature Flag)

**Before deploying**, add this to your extension:

```xpp
// In both extension classes
public void run()
{
    // Check feature flag
    if (!FeatureManagement::isFeatureEnabled('ActivityNumberGrouping'))
    {
        // Skip extension logic
        next run();
        return;
    }
    
    // Your extension logic here
}
```

**To disable**: Turn off feature in Feature Management

#### Option 2: Hard Rollback

1. **Remove deployable package** from LCS
2. **Deploy previous version** without extensions
3. **Clean up data**:

```sql
-- Optional: Clear ActivityNumber from proposals if needed
UPDATE PROJPROPOSALJOUR 
SET ACTIVITYNUMBER = '' 
WHERE ACTIVITYNUMBER IS NOT NULL;
```

---

## Troubleshooting

### Issue: Compilation Errors

**Error**: "Method does not exist"
- **Solution**: Verify you're extending the correct class
- Check class name spelling
- Ensure `[ExtensionOf(classStr(...))]` attribute is correct

### Issue: No Transactions Selected

**Error**: "No transactions found"
- **Solution**: Verify ActivityNumber field exists on transaction tables
- Check if transactions actually have ActivityNumber populated
- Review query filters

### Issue: Multiple Proposals Not Created

**Error**: All transactions in one proposal despite different activities
- **Solution**: Check `isSetProjProposalJour()` logic
- Verify `currentActivityNumber` is being updated
- Add debug logging

### Issue: Performance Degradation

**Error**: Invoice proposal creation is slow
- **Solution**: 
  - Verify indexes created
  - Check cache is working (`activityProposalMap`)
  - Review query execution plans
  - Consider batch processing for large volumes

---

## Next Steps

After successful deployment:

1. ✅ Monitor system for first week
2. ✅ Gather user feedback
3. ✅ Track performance metrics
4. ✅ Document any issues encountered
5. ✅ Create user training materials
6. ✅ Update internal procedures

---

## Support Contacts

- **Technical Issues**: [Your development team]
- **Business Questions**: [Your project management team]
- **User Training**: [Your training team]

---

**Document Version**: 1.0  
**Last Updated**: 2025-11-16  
**Next Review**: After first production deployment
