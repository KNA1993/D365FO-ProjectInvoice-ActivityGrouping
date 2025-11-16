# Configuration Options: Making Activity Filtering Optional

## Problem Statement

The Chain of Command extension affects **ALL** projects using the invoice proposal batch job. This means:
- Projects **with** activities: Work as designed ✓
- Projects **without** activities: Transactions are excluded ✗

You need a way to ensure non-activity projects are not affected.

---

## Solution Options

### Option 1: Project-Level Configuration Flag (Recommended)

**Concept**: Add a field to ProjTable to enable/disable activity-based invoicing per project.

#### Implementation:

**Step 1: Extend ProjTable**

```xml
<!-- File: src/Tables/ProjTable.UseActivityGrouping.xml -->
<?xml version="1.0" encoding="utf-8"?>
<AxTableExtension xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
	<Name>ProjTable_ActivityGrouping</Name>
	<TargetElement>ProjTable</TargetElement>
	<Fields>
		<AxTableField xmlns="">
			<Name>UseActivityGrouping</Name>
			<ExtendedDataType>NoYesId</ExtendedDataType>
			<HelpText>Enable activity-based invoice proposal grouping</HelpText>
			<Label>@ActivityLabels:UseActivityGrouping</Label>
			<Mandatory>No</Mandatory>
		</AxTableField>
	</Fields>
</AxTableExtension>
```

**Step 2: Update Extension Logic**

```xpp
[ExtensionOf(classStr(ProjInvoiceProposalCreateLines))]
final class ProjInvoiceProposalCreateLines_ActivityExtension
{
    private boolean isActivityGroupingEnabled()
    {
        ProjTable projTable = ProjTable::find(this.parmProjInvoiceProjId());
        return projTable.UseActivityGrouping;
    }
    
    public int runEmplQuery(Query _query)
    {
        // Only apply activity filter if enabled for this project
        if (this.isActivityGroupingEnabled())
        {
            QueryBuildDataSource qbds;
            QueryBuildRange qbr;
            
            qbds = _query.dataSourceTable(tableNum(ProjEmplTransSale));
            
            if (qbds)
            {
                qbr = qbds.addRange(fieldNum(ProjEmplTransSale, ActivityNumber));
                qbr.value(SysQuery::valueNotEmpty());
                qbr.status(RangeStatus::Locked);
            }
        }
        
        return next runEmplQuery(_query);
    }
    
    // Repeat for runCostQuery, runItemQuery, runRevenueQuery, runOnAccountQuery
}
```

```xpp
[ExtensionOf(classStr(ProjInvoiceProposalInsertLines))]
final class ProjInvoiceProposalInsertLines_ActivityExtension
{
    private boolean isActivityGroupingEnabled()
    {
        ProjTable projTable = ProjTable::find(this.parmProjInvoiceProjId());
        return projTable.UseActivityGrouping;
    }
    
    public boolean isSetProjProposalJour()
    {
        boolean ret = next isSetProjProposalJour();
        
        // Only check activity if enabled
        if (!ret && this.isActivityGroupingEnabled())
        {
            ActivityNumber transActivity = this.getActivityNumberFromTransaction();
            
            if (transActivity != currentActivityNumber)
            {
                ret = true;
            }
        }
        
        return ret;
    }
    
    // Update other methods similarly
}
```

**Step 3: Add to Project Form**

```xml
<!-- File: src/Forms/ProjTable.UseActivityGrouping.xml -->
<?xml version="1.0" encoding="utf-8"?>
<AxFormExtension xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
	<Name>ProjTable_ActivityGrouping</Name>
	<TargetElement>ProjTable</TargetElement>
	<FormDesign>
		<Controls>
			<AxFormGroupControl>
				<Name>InvoicingGroup</Name>
				<FormControlExtension>
					<Controls>
						<AxFormCheckBoxControl>
							<Name>UseActivityGrouping</Name>
							<DataField>UseActivityGrouping</DataField>
							<DataSource>ProjTable</DataSource>
						</AxFormCheckBoxControl>
					</Controls>
				</FormControlExtension>
			</AxFormGroupControl>
		</Controls>
	</FormDesign>
</AxFormExtension>
```

**Benefits:**
- ✅ Granular control per project
- ✅ Existing projects unaffected (default = No)
- ✅ New projects can opt-in
- ✅ Easy to enable/disable

**Drawbacks:**
- Requires project master data update
- Users must remember to enable flag

---

### Option 2: Global Parameter (Project Management Parameters)

**Concept**: Add global setting to enable/disable activity filtering system-wide.

#### Implementation:

**Step 1: Extend ProjParameters**

```xml
<!-- File: src/Tables/ProjParameters.UseActivityGrouping.xml -->
<?xml version="1.0" encoding="utf-8"?>
<AxTableExtension xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
	<Name>ProjParameters_ActivityGrouping</Name>
	<TargetElement>ProjParameters</TargetElement>
	<Fields>
		<AxTableField xmlns="">
			<Name>UseActivityGrouping</Name>
			<ExtendedDataType>NoYesId</ExtendedDataType>
			<HelpText>Enable activity-based invoice proposal grouping globally</HelpText>
			<Label>@ActivityLabels:UseActivityGrouping</Label>
			<Mandatory>No</Mandatory>
		</AxTableField>
	</Fields>
</AxTableExtension>
```

**Step 2: Update Extension Logic**

```xpp
[ExtensionOf(classStr(ProjInvoiceProposalCreateLines))]
final class ProjInvoiceProposalCreateLines_ActivityExtension
{
    private boolean isActivityGroupingEnabled()
    {
        ProjParameters projParameters = ProjParameters::find();
        return projParameters.UseActivityGrouping;
    }
    
    public int runEmplQuery(Query _query)
    {
        if (this.isActivityGroupingEnabled())
        {
            // Apply activity filter
            QueryBuildDataSource qbds = _query.dataSourceTable(tableNum(ProjEmplTransSale));
            
            if (qbds)
            {
                QueryBuildRange qbr = qbds.addRange(fieldNum(ProjEmplTransSale, ActivityNumber));
                qbr.value(SysQuery::valueNotEmpty());
                qbr.status(RangeStatus::Locked);
            }
        }
        
        return next runEmplQuery(_query);
    }
}
```

**Benefits:**
- ✅ Simple on/off switch
- ✅ One place to control
- ✅ Easy rollback if issues

**Drawbacks:**
- ❌ All-or-nothing (can't have mixed projects)
- ❌ Requires system-wide decision

---

### Option 3: Project Type-Based Configuration

**Concept**: Enable activity grouping only for specific project types.

#### Implementation:

**Step 1: Extend ProjGroup**

```xml
<!-- File: src/Tables/ProjGroup.UseActivityGrouping.xml -->
<?xml version="1.0" encoding="utf-8"?>
<AxTableExtension xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
	<Name>ProjGroup_ActivityGrouping</Name>
	<TargetElement>ProjGroup</TargetElement>
	<Fields>
		<AxTableField xmlns="">
			<Name>UseActivityGrouping</Name>
			<ExtendedDataType>NoYesId</ExtendedDataType>
			<HelpText>Enable activity-based invoice proposal grouping for this project type</HelpText>
			<Label>@ActivityLabels:UseActivityGrouping</Label>
			<Mandatory>No</Mandatory>
		</AxTableField>
	</Fields>
</AxTableExtension>
```

**Step 2: Update Logic**

```xpp
private boolean isActivityGroupingEnabled()
{
    ProjTable projTable = ProjTable::find(this.parmProjInvoiceProjId());
    ProjGroup projGroup = ProjGroup::find(projTable.ProjGroupId);
    return projGroup.UseActivityGrouping;
}
```

**Benefits:**
- ✅ Logical grouping (Time & Material vs Fixed Price)
- ✅ Easy to configure for similar projects
- ✅ Inheritable setting

**Drawbacks:**
- ❌ Less granular than project-level
- ❌ May affect unintended projects in same group

---

### Option 4: Feature Management Flag

**Concept**: Use D365 built-in Feature Management to enable/disable.

#### Implementation:

**Step 1: Register Feature**

```xpp
// File: src/Classes/ProjectActivityGroupingFeature.xml
[ExportAttribute(identifierStr(Microsoft.Dynamics.ApplicationPlatform.FeatureExposure.IFeatureMetadata))]
class ProjectActivityGroupingFeature implements IFeatureMetadata
{
    public FeatureName featureName()
    {
        return literalStr("ProjectActivityBasedInvoiceGrouping");
    }
    
    public FeatureLabel featureLabel()
    {
        return "@ActivityLabels:ActivityGroupingFeature";
    }
    
    public FeatureDescription featureDescription()
    {
        return "@ActivityLabels:ActivityGroupingFeatureDesc";
    }
    
    public FeatureLearMoreUrl featureMoreInfoUrl()
    {
        return "https://github.com/KNA1993/D365FO-ProjectInvoice-ActivityGrouping";
    }
    
    public FeatureDefaultState defaultState()
    {
        return FeatureDefaultState::Disabled;
    }
    
    public boolean isCannotDisableEnabled()
    {
        return false;
    }
}
```

**Step 2: Check Feature State**

```xpp
private boolean isActivityGroupingEnabled()
{
    return FeatureStateProvider::isFeatureEnabled(
        FeatureStateProvider::getFeatureMetadataFromFeatureClass(
            classStr(ProjectActivityGroupingFeature)));
}
```

**Benefits:**
- ✅ Professional enterprise approach
- ✅ Integrates with standard D365 feature management
- ✅ Can enable in staging first, then production
- ✅ Rollback is instant (just disable feature)

**Drawbacks:**
- ❌ More complex to implement
- ❌ All-or-nothing (not per-project)

---

## Comparison Matrix

| Option | Granularity | Complexity | Flexibility | Rollback Ease |
|--------|-------------|------------|-------------|---------------|
| **Project-Level Flag** | Per project | Medium | High | Easy |
| **Global Parameter** | System-wide | Low | Low | Very Easy |
| **Project Type Flag** | Per project type | Medium | Medium | Easy |
| **Feature Management** | System-wide | High | Medium | Instant |

---

## Recommended Approach

### **Two-Tier Approach (Best of Both Worlds)**

1. **Feature Management Flag** (System-wide on/off)
2. **Project-Level Flag** (Granular control when enabled)

```xpp
private boolean isActivityGroupingEnabled()
{
    // First check: Is feature enabled globally?
    if (!FeatureStateProvider::isFeatureEnabled(
        FeatureStateProvider::getFeatureMetadataFromFeatureClass(
            classStr(ProjectActivityGroupingFeature))))
    {
        return false; // Feature disabled - skip activity logic
    }
    
    // Second check: Is it enabled for this project?
    ProjTable projTable = ProjTable::find(this.parmProjInvoiceProjId());
    return projTable.UseActivityGrouping;
}
```

**Benefits:**
- Global kill switch for emergencies
- Per-project control for normal operations
- Phased rollout possible
- Maximum safety

---

## Migration Strategy

### Phase 1: Deploy with Feature Disabled
```
Day 0: Deploy code + feature (disabled by default)
Day 1-7: No impact, validate deployment
```

### Phase 2: Enable for Pilot Projects
```
Week 2: Enable feature globally
Week 2: Set UseActivityGrouping = Yes on 3 pilot projects
Week 3-4: Monitor, collect feedback
```

### Phase 3: Rollout
```
Week 5: Enable for 10 more projects
Week 6: Enable for 50% of projects
Week 7: Enable for all new projects by default
Week 8+: Gradually migrate remaining projects
```

### Emergency Rollback
```
If critical issue: Disable feature in Feature Management
Result: ALL projects revert to standard behavior immediately
```

---

## Default Behavior Recommendation

### For New Projects
```xpp
// In project creation logic
projTable.UseActivityGrouping = ProjParameters::find().DefaultActivityGrouping;
```

### For Existing Projects
```sql
-- Keep existing projects as-is (default = No)
UPDATE ProjTable
SET UseActivityGrouping = 0
WHERE UseActivityGrouping IS NULL;
```

---

## Code Template: Complete Implementation

```xpp
// Extension with configuration check
[ExtensionOf(classStr(ProjInvoiceProposalCreateLines))]
final class ProjInvoiceProposalCreateLines_ActivityExtension
{
    private boolean isActivityGroupingEnabled(ProjInvoiceProjId _projInvoiceProjId)
    {
        // Feature flag check (system-wide)
        if (!FeatureStateProvider::isFeatureEnabled(
            FeatureStateProvider::getFeatureMetadataFromFeatureClass(
                classStr(ProjectActivityGroupingFeature))))
        {
            return false;
        }
        
        // Project-level check
        ProjTable projTable = ProjTable::find(_projInvoiceProjId);
        return projTable.UseActivityGrouping == NoYes::Yes;
    }
    
    public int runEmplQuery(Query _query)
    {
        // Get project ID from query
        QueryBuildDataSource qbds = _query.dataSourceTable(tableNum(ProjEmplTransSale));
        
        if (qbds)
        {
            // Check if activity grouping enabled for this project
            if (this.isActivityGroupingEnabled(this.parmProjInvoiceProjId()))
            {
                QueryBuildRange qbr = qbds.addRange(fieldNum(ProjEmplTransSale, ActivityNumber));
                qbr.value(SysQuery::valueNotEmpty());
                qbr.status(RangeStatus::Locked);
                
                info("Activity-based filtering enabled for this project");
            }
            else
            {
                info("Standard invoice proposal creation (activity filtering disabled)");
            }
        }
        
        return next runEmplQuery(_query);
    }
    
    // Repeat for other query methods...
}
```

---

## Testing Checklist

- [ ] Project with UseActivityGrouping = Yes → Filters by activity ✓
- [ ] Project with UseActivityGrouping = No → Standard behavior ✓
- [ ] Feature disabled → All projects standard behavior ✓
- [ ] Mixed projects in same batch → Correct behavior per project ✓
- [ ] Performance impact negligible ✓
- [ ] Rollback tested ✓

---

**Document Version**: 1.0  
**Last Updated**: 2025-11-16  
**Recommended Option**: Two-Tier (Feature Management + Project-Level Flag)
