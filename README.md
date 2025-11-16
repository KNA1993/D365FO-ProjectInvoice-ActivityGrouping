# D365 Finance & Operations: Activity-Based Invoice Proposal Grouping

## Overview

This extension enhances Microsoft Dynamics 365 Finance & Operations project invoice proposal creation to **group invoices by Activity Number** at the transaction line level.

### Key Features

✅ **Optional per Project** - Enable via "Use activity grouping for project invoice proposals" checkbox on project master  
✅ **Activity-Based Grouping** - One invoice proposal per activity number  
✅ **Transaction Filtering** - Only transactions WITH ActivityNumber are invoiced (when enabled)  
✅ **Non-Invasive** - Uses Chain of Command pattern (no base code modification)  
✅ **Backward Compatible** - Existing projects unaffected (opt-in model)  
✅ **Multi-Language Support** - English and Norwegian (Norsk Bokmål) labels included

---

## Business Requirement

**Problem**: Standard D365 FO groups invoice proposals by Customer, Project, Currency, and Funding Source. This doesn't provide visibility into which project activities/phases are being invoiced.

**Solution**: Add ActivityNumber as an additional grouping dimension, creating separate invoice proposals for each activity.

**Configuration**: Add checkbox on project master:
- **English**: "Use activity grouping for project invoice proposals"
- **Norwegian**: "Gruppere basert på aktivitet ved fakturering"

---

## How It Works

### Standard Grouping (Projects with UseActivityGrouping = No)
```
Customer + Project + Currency + Funding Source
→ One Invoice Proposal
```

### Enhanced Grouping (Projects with UseActivityGrouping = Yes)
```
Customer + Project + Currency + Funding Source + ActivityNumber
→ Multiple Invoice Proposals (one per activity)

Transactions WITHOUT ActivityNumber → EXCLUDED
```

---

## Example Scenario

### Project Setup
- **Project**: PROJ-2025
- **Customer**: Contoso Ltd
- **Use activity grouping**: ✅ Yes

### Transactions
| Type | Activity | Amount |
|------|----------|--------|
| Hours | Design | $10,000 |
| Hours | Development | $25,000 |
| Expenses | Development | $3,000 |
| Hours | Testing | $8,000 |

### Result
**3 Invoice Proposals Created:**
1. Proposal #001: Design - $10,000
2. Proposal #002: Development - $28,000
3. Proposal #003: Testing - $8,000

**Benefit**: Clear visibility of invoiced activities, easier project phase tracking.

---

## Installation

### Prerequisites
- D365 Finance & Operations (version 10.0.x or later)
- Visual Studio with D365 development tools
- ActivityNumber field exists on transaction sale tables:
  - ProjEmplTransSale
  - ProjCostTransSale
  - ProjItemTransSale
  - ProjRevenueTransSale
  - ProjOnAccTransSale (optional)

### Quick Start

1. **Clone Repository**
   ```bash
   git clone https://github.com/KNA1993/D365FO-ProjectInvoice-ActivityGrouping.git
   ```

2. **Import to Visual Studio**
   - Create new D365 model or use existing
   - Add files from `/src` directory
   - Build solution

3. **Deploy**
   - Sync database (adds ProjTable.UseActivityGrouping and ProjProposalJour.ActivityNumber)
   - Deploy package to environment

4. **Enable for Projects**
   - Navigate to: Project management > Projects > All projects
   - Open project
   - Set "Use activity grouping for project invoice proposals" = Yes
   - Save

5. **Test**
   - Create transactions with ActivityNumber assigned
   - Run invoice proposal creation
   - Verify separate proposals per activity

---

## Configuration

### Project-Level Setting

**Path**: Project management > Projects > All projects > [Project] > Invoice tab

**Field**: Use activity grouping for project invoice proposals  
**Norwegian**: Gruppere basert på aktivitet ved fakturering

**Values**:
- ☐ **No** (Default) - Standard behavior, no activity filtering or grouping
- ☑ **Yes** - Enable activity-based grouping, exclude transactions without activities

### When to Enable

✅ Enable for projects where:
- Activity-based billing is required
- Customer wants separate invoices per project phase
- Activity tracking is mandatory
- All transactions have ActivityNumber assigned

❌ Keep disabled for projects where:
- Activities are not used
- Single invoice per project is preferred
- Transactions may not have ActivityNumber

---

## Documentation

### For Users
- [User Guide](docs/USER_GUIDE.md) - End-user documentation
- [Business Process Flowchart](docs/BUSINESS_PROCESS_FLOWCHART.md) - Visual process flows

### For Developers
- [Implementation Guide](docs/IMPLEMENTATION_GUIDE.md) - Step-by-step setup
- [Technical Design](docs/TECHNICAL_DESIGN.md) - Architecture and algorithms
- [Configuration Options](docs/CONFIGURATION_OPTIONS.md) - How to make it optional

### For Project Managers
- [Risk Assessment](docs/RISK_ASSESSMENT.md) - Risks and mitigations
- [Testing Guide](docs/TESTING_GUIDE.md) - Test scenarios and validation

---

## Technical Architecture

### Extension Points

1. **ProjTable** - Add UseActivityGrouping field (NoYes)
2. **ProjProposalJour** - Add ActivityNumber field
3. **ProjInvoiceProposalCreateLines** - Filter transactions by ActivityNumber
4. **ProjInvoiceProposalInsertLines** - Group proposals by ActivityNumber
5. **Forms** - Add checkbox to project form, column to proposal list

### Key Classes Extended

```
ProjInvoiceProposalCreateLines_ActivityExtension
├─ isActivityGroupingEnabled() - Check project setting
├─ runEmplQuery() - Filter hour transactions
├─ runCostQuery() - Filter expense transactions
├─ runItemQuery() - Filter item transactions
├─ runRevenueQuery() - Filter revenue transactions
└─ runOnAccountQuery() - Filter on-account transactions

ProjInvoiceProposalInsertLines_ActivityExtension
├─ isActivityGroupingEnabled() - Check project setting
├─ isSetProjProposalJour() - Check if new proposal needed
├─ getActivityNumberFromTransaction() - Extract activity
├─ setProjProposalJour() - Create/find activity-specific proposal
└─ validateProposalActivityConsistency() - Validate consistency
```

---

## Labels (Multi-Language)

### English (en-US)
- **Use activity grouping for project invoice proposals**
- Activity number
- Only transactions with assigned activity numbers will be included
- Activity-based filtering enabled for this project
- Standard invoice proposal creation (activity filtering disabled)

### Norwegian (nb-NO)
- **Gruppere basert på aktivitet ved fakturering**
- Aktivitetsnummer
- Bare transaksjoner med tildelte aktivitetsnumre vil bli inkludert
- Aktivitetsbasert filtrering aktivert for dette prosjektet
- Standard fakturaforslag (aktivitetsfiltrering deaktivert)

---

## Troubleshooting

### No Proposals Created

**Cause**: Transactions don't have ActivityNumber assigned

**Solution**:
1. Check project setting: UseActivityGrouping = Yes?
2. Verify transactions have ActivityNumber
3. Run validation query from Testing Guide
4. Assign activities or disable UseActivityGrouping

### Too Many Proposals

**Expected Behavior**: One proposal per unique combination of:
- Customer
- Project  
- Currency
- Funding Source
- **ActivityNumber** ← New dimension

**Solution**: This is correct. Each activity gets a separate proposal.

### Existing Projects Affected

**Should Not Happen**: Extension only applies when UseActivityGrouping = Yes

**Verify**:
1. Check ProjTable.UseActivityGrouping field value
2. Should default to No for existing projects
3. Review extension code for isActivityGroupingEnabled() checks

---

## Support

### Resources
- 📖 [Full Documentation](docs/)
- 🐛 [Issue Tracker](https://github.com/KNA1993/D365FO-ProjectInvoice-ActivityGrouping/issues)
- 💬 [Discussions](https://github.com/KNA1993/D365FO-ProjectInvoice-ActivityGrouping/discussions)

### Contact
For questions or support, please open an issue on GitHub.

---

## License

[Specify your license]

---

## Version History

**1.0.0** (2025-01-16)
- Initial release
- Activity-based invoice proposal grouping
- Project-level configuration flag (UseActivityGrouping)
- Multi-language support (English, Norwegian)
- Comprehensive documentation

---

**Repository**: https://github.com/KNA1993/D365FO-ProjectInvoice-ActivityGrouping  
**Author**: [Your Name/Organization]  
**Last Updated**: 2025-11-16
