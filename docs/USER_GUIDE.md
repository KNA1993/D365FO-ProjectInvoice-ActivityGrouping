# User Guide: Activity-Based Invoice Proposal Grouping

## What's New?

### Overview

Your D365 Finance & Operations system has been enhanced to group project invoice proposals by **Activity Number**. This means invoices will now be organized based on the activities recorded on your project transactions.

### Key Changes

✅ **Invoice Grouping**  
One invoice proposal per activity (instead of combining all activities)

✅ **Activity Required**  
Only transactions **with** an Activity Number will be included in invoice proposals

✅ **Clear Separation**  
Easier to track billing by project phase or work package

⚠️ **Important**  
Transactions **without** an Activity Number will be **skipped** during invoice creation

---

## For Project Managers

### How This Helps You

1. **Better Revenue Tracking**
   - See exactly which activities are invoiced
   - Track billing progress by project phase
   - Identify completed vs. pending activities

2. **Clearer Customer Communication**
   - Customer receives separate invoices per activity
   - Easy to explain what's being billed
   - Transparent activity-based billing

3. **Improved Project Control**
   - Invoice as activities complete
   - No need to wait for entire project
   - Better cash flow management

### What You Need to Do

#### Before Creating Invoice Proposals

1. **Verify Activity Assignment**
   - Check that all transactions have Activity Numbers
   - Use Activity Assignment Report (see below)
   - Assign activities to any missing transactions

2. **Mark Activities Ready to Invoice**
   - Review activity completion status
   - Mark completed activities for invoicing
   - Leave in-progress activities for later

3. **Communicate with Customer**
   - Inform customer about activity-based invoicing
   - Explain activity breakdown on invoices
   - Set expectations for multiple invoices

#### Running the Activity Assignment Report

**Navigation**: Project management > Inquiries and reports > Transactions > Activity assignment status

**What to Look For**:
```
Project: PROJ-001
├── Hour Transactions
│   ├── With Activity: 95 (Ready)
│   └── Without Activity: 5 ⚠️ (Action Required)
├── Expense Transactions
│   ├── With Activity: 87 (Ready)
│   └── Without Activity: 3 ⚠️ (Action Required)
└── Item Transactions
    ├── With Activity: 100 (Ready)
    └── Without Activity: 0 (Ready)
```

**Action**: Assign activities to transactions showing ⚠️

---

## For Timesheets & Expense Entry

### What Changed

**Before**: Activity Number was optional  
**Now**: Activity Number is **required** for invoicing

### How to Enter Transactions

#### Entering Hours

1. Open your timesheet
2. Select project
3. **Select Activity** (required)
4. Enter hours
5. Submit

⚠️ **Warning**: If you don't select an activity, your hours **will not be invoiced**.

#### Entering Expenses

1. Create expense report
2. Add expense line
3. Select project
4. **Select Activity** (required)
5. Enter amount
6. Submit

⚠️ **Warning**: If you don't select an activity, your expense **will not be invoiced**.

#### Entering Items

1. Create item journal
2. Select project
3. **Select Activity** (required)
4. Enter item and quantity
5. Post

### Activity Selection Tips

✅ **Choose the Right Activity**
- Match activity to the work performed
- If unsure, ask your project manager
- Use activity descriptions as guide

✅ **Be Consistent**
- Use same activity for related work
- Don't switch activities mid-task
- Follow project activity plan

❌ **Don't Skip Activity**
- Never leave activity blank
- If no activity fits, contact project manager
- Don't use generic "Other" unless instructed

---

## For Accountants

### Invoice Proposal Creation Process

#### Step 1: Pre-Creation Checks

**Before** running proposal creation:

1. **Run Validation Report**
   ```
   Project management > Inquiries > Transactions ready to invoice
   Filter: ActivityNumber = <blank>
   ```

2. **Review Results**
   - If report shows transactions: Stop
   - Contact project manager to assign activities
   - Don't proceed until all transactions have activities

3. **Verify Activity Data**
   ```
   Project management > Setup > Activities
   Check: All activities are active and valid
   ```

#### Step 2: Create Proposals

**Navigation**: Project management > Invoices > Invoice proposals > Create invoice proposals

**Process**:
1. Select project(s)
2. Set date range
3. Select transaction types
4. Click OK

**What Happens**:
- System selects transactions **with Activity Numbers only**
- Groups transactions by:
  - Customer
  - Project
  - Currency
  - Funding Source
  - **Activity Number** ⭐
- Creates separate proposal for each group

**Example Output**:
```
Project: PROJ-001, Customer: C001, Currency: USD

├── Proposal #001: Activity = "Design Phase"
│   Amount: $15,000
│   Lines: 25 hours, 5 expenses
│
├── Proposal #002: Activity = "Development Phase"
│   Amount: $45,000
│   Lines: 75 hours, 12 expenses, 3 items
│
└── Proposal #003: Activity = "Testing Phase"
    Amount: $20,000
    Lines: 40 hours, 8 expenses

Total: 3 proposals for 3 activities
```

#### Step 3: Review Proposals

**Navigation**: Project management > Invoices > Invoice proposals

**What to Check**:

☑️ Activity column populated on all proposals  
☑️ Each proposal contains only one activity  
☑️ All expected activities are present  
☑️ Amounts are reasonable

**Filtering by Activity**:
```
Filter: ActivityNumber = "Design Phase"
Result: All proposals for Design Phase across all projects
```

#### Step 4: Post Invoices

**Process unchanged**:
1. Review proposal details
2. Make any necessary adjustments
3. Post invoice
4. Activity Number automatically transferred to invoice

### Understanding Infolog Messages

#### Success Messages

```
✅ "Processing transactions with Activity Number"
   Normal: System starting proposal creation

✅ "1,234 transactions processed"
   Normal: Count of transactions included

✅ "Created 5 invoice proposals"
   Normal: Proposals created successfully
```

#### Warning Messages

```
⚠️ "15 transactions skipped (no Activity Number)"
   Action: Investigate skipped transactions
   Impact: Some transactions not invoiced
   
⚠️ "No transactions found with Activity Number"
   Action: Verify activity assignment
   Impact: No proposals created
```

#### Error Messages

```
❌ "Cannot create proposal without Activity Number"
   Cause: Data integrity issue
   Action: Contact support
   
❌ "Proposal contains multiple Activity Numbers"
   Cause: System error
   Action: Contact support
```

### Month-End Close Checklist

- [ ] All transactions have Activity Numbers assigned
- [ ] Activity assignment report shows 0 missing
- [ ] Invoice proposals created successfully
- [ ] All proposals have ActivityNumber populated
- [ ] Proposal count matches activity count
- [ ] No skipped transaction warnings
- [ ] All proposals reviewed and posted
- [ ] Revenue recognized by activity
- [ ] Activity-based reports generated

---

## Common Scenarios

### Scenario 1: Forgot to Assign Activity

**Problem**: You ran invoice proposal creation and got warning "50 transactions skipped"

**Solution**:
1. Go to: Project > Transactions > All transactions
2. Filter: ActivityNumber = <blank>, InvoiceStatus = "Ready"
3. Select transactions
4. Click "Edit" > "Activity"
5. Assign appropriate activity
6. Rerun invoice proposal creation

---

### Scenario 2: Wrong Activity Assigned

**Problem**: Transaction has wrong activity, already in proposal

**Solution**:
1. Delete the invoice proposal (if not posted)
2. Correct the transaction activity
3. Recreate invoice proposal
4. Verify correct activity on new proposal

**Note**: If proposal already posted, create credit note and reissue.

---

### Scenario 3: Customer Wants Combined Invoice

**Problem**: Customer doesn't want separate invoices per activity

**Solution**:
- **Option A**: Post all proposals, combine in customer invoice
- **Option B**: Manually consolidate proposals before posting
- **Option C**: Discuss with project manager about activity structure

**Recommended**: Option A (easiest, maintains activity tracking)

---

### Scenario 4: Activity Changed Mid-Work

**Problem**: Work started in Activity A, finished in Activity B

**Solution**:
1. Split the transaction
2. Assign Activity A to first part
3. Assign Activity B to second part
4. Invoice each part with correct activity

**Example**:
```
Original: 10 hours, Activity = ?

Split into:
→ 5 hours, Activity = "Design" (early work)
→ 5 hours, Activity = "Development" (later work)
```

---

### Scenario 5: No Activity Fits

**Problem**: Employee did work but no activity matches

**Solution**:
1. Contact project manager
2. Create new activity if needed, or
3. Assign to closest matching activity
4. Document reason

**Don't**: Leave activity blank - transaction won't invoice!

---

## Reports & Inquiries

### Key Reports

#### 1. Activity Invoicing Status

**Path**: Project management > Inquiries > Activity invoicing status

**Shows**:
- Activities per project
- Invoiced vs. uninvoiced amounts
- Transactions without activities

#### 2. Proposal by Activity Report

**Path**: Project management > Reports > Invoice > Proposal by activity

**Shows**:
- All proposals grouped by activity
- Activity totals
- Cross-project activity summary

#### 3. Missing Activity Report

**Path**: Project management > Reports > Transactions > Missing activity

**Shows**:
- All transactions without Activity Number
- Grouped by project and transaction type
- Impact analysis (uninvoiceable amount)

### Data Queries

#### Find Transactions Without Activity

```
Navigation: Project > Inquiries > Transactions > All transactions

Advanced Filter:
  Field: ActivityNumber
  Criteria: "" (empty)
  AND
  Field: InvoiceStatus
  Criteria: Ready

Result: List of transactions that won't invoice
```

#### Find Proposals by Activity

```
Navigation: Project > Invoices > Invoice proposals

Filter:
  ActivityNumber = "Design Phase"

Result: All proposals for Design Phase
```

---

## Troubleshooting

### Problem: No Proposals Created

**Symptoms**: Batch job completes but 0 proposals

**Possible Causes**:
1. No transactions have Activity Number
2. Date range too narrow
3. All transactions already invoiced
4. Transaction status not "Ready"

**Diagnosis**:
```
Check 1: Run Missing Activity Report
Check 2: Verify date range in batch parameters
Check 3: Check transaction InvoiceStatus field
Check 4: Review batch log for warnings
```

**Solution**:
- Assign activities to transactions
- Expand date range
- Verify transaction status

---

### Problem: More Proposals Than Expected

**Symptoms**: Created 10 proposals, expected 3

**Possible Causes**:
1. Multiple activities in project
2. Multiple currencies
3. Multiple funding sources
4. Existing proposals being reused

**Diagnosis**:
```
Check: Group proposals by ActivityNumber
Check: Review currency on proposals
Check: Review funding source
```

**Solution**:
- This is expected behavior
- Each activity/currency/funding combination creates separate proposal
- Review with project manager if unexpected

---

### Problem: Transactions Skipped

**Symptoms**: Warning "X transactions skipped"

**Cause**: Transactions don't have Activity Number

**Solution**:
1. Note the count (X)
2. Run Missing Activity Report
3. Assign activities
4. Rerun proposal creation

**Prevention**: Require activity at transaction entry

---

### Problem: Can't Find Proposal

**Symptoms**: Created proposal but can't find it in list

**Possible Causes**:
1. Filtered by wrong activity
2. Proposal already posted
3. Wrong project selected

**Solution**:
```
Navigation: Project > Invoices > Invoice proposals
Action: Clear all filters
Action: Search by date created
Action: Search by project
```

---

## Best Practices

### For Everyone

✅ **Always Assign Activity**
- Make it a habit
- Think about activity before entering transaction
- Verify activity before submitting

✅ **Use Consistent Activities**
- Follow project activity structure
- Don't create ad-hoc activities
- Ask if unsure

✅ **Review Before Invoice**
- Check activity assignments
- Run validation reports
- Communicate with team

### For Project Managers

✅ **Clear Activity Definitions**
- Define activities at project start
- Communicate to team
- Provide examples

✅ **Regular Reviews**
- Weekly activity assignment check
- Monthly invoicing review
- Address gaps promptly

✅ **Team Training**
- Train on activity selection
- Emphasize importance
- Provide quick reference

### For Accountants

✅ **Pre-Invoice Validation**
- Always run Missing Activity Report first
- Don't create proposals with gaps
- Coordinate with project managers

✅ **Consistent Process**
- Same workflow every time
- Document exceptions
- Review batch logs

✅ **Month-End Discipline**
- Set cutoff for activity assignment
- Complete proposals before close
- Verify activity-based reports

---

## Getting Help

### Support Resources

**Documentation**: [Link to full documentation]

**Training Videos**: [Link to training portal]

**Quick Reference Card**: [Link to PDF]

**FAQ**: [Link to FAQ document]

### Contact Information

**IT Support**: [Email/Phone]
- Technical issues
- System errors
- Access problems

**Finance Team**: [Email/Phone]
- Invoicing questions
- Process guidance
- Month-end support

**Project Management Office**: [Email/Phone]
- Activity structure
- Project setup
- Business process

### Feedback

We want to hear from you!

**Submit Feedback**: [Link to feedback form]

**Report Issues**: [Link to issue tracker]

**Suggest Improvements**: [Email]

---

## Appendix: Activity Examples

### Software Development Project

```
├── Requirements Analysis
├── Design
├── Development
├── Testing
├── Deployment
└── Support
```

### Construction Project

```
├── Planning & Permits
├── Site Preparation
├── Foundation
├── Structure
├── Finishing
└── Inspection
```

### Consulting Project

```
├── Discovery
├── Analysis
├── Recommendations
├── Implementation Support
└── Training
```

---

**Document Version**: 1.0  
**Last Updated**: 2025-11-16  
**For Questions**: Contact your system administrator
