# D365 F&O: Project Invoice Proposal Activity Number Grouping

## Overview

This repository contains a complete implementation guide for extending Microsoft Dynamics 365 Finance & Operations to group project invoice proposals by **Activity Number** at the transaction line level.

### Business Requirement

- **Goal**: Create separate invoice proposals for each Activity Number
- **Source**: Activity Number from transaction lines (not project header)
- **Rule**: Only invoice transactions that have an Activity Number assigned
- **Benefit**: Better invoice segregation and tracking by activity

### Current Standard Behavior

The standard D365 F&O system groups project invoice proposals by:
1. Customer Account
2. Project Invoice ID (ProjInvoiceProjId)
3. Currency Code
4. Funding Source

### Enhanced Behavior

With this extension, the system will additionally group by:
5. **Activity Number** (from transaction lines)

Transactions **without** an Activity Number will be **excluded** from invoice proposal creation.

---

## Repository Structure

```
├── README.md                          # This file
├── docs/
│   ├── IMPLEMENTATION_GUIDE.md        # Step-by-step implementation
│   ├── TECHNICAL_DESIGN.md            # Technical architecture
│   ├── RISK_ASSESSMENT.md             # Risks and mitigations
│   ├── TESTING_GUIDE.md               # Test scenarios and validation
│   └── USER_GUIDE.md                  # End-user documentation
├── src/
│   ├── TableExtensions/
│   │   └── ProjProposalJour.ActivityNumber.xml
│   ├── ClassExtensions/
│   │   ├── ProjInvoiceProposalCreateLines_ActivityExtension.xml
│   │   └── ProjInvoiceProposalInsertLines_ActivityExtension.xml
│   ├── FormExtensions/
│   │   ├── ProjInvoiceProposalDetail_ActivityExtension.xml
│   │   └── ProjInvoiceProposalListPage_ActivityExtension.xml
│   └── Labels/
│       └── ActivityGrouping_en-US.xml
├── tests/
│   └── ProjInvoiceActivityGroupingTest.xml
└── scripts/
    ├── ValidationQuery.sql
    └── DataMigration.sql
```

---

## Quick Start

### Prerequisites

- D365 F&O development environment (local VM or cloud-hosted)
- Visual Studio with D365 F&O development tools
- Your custom model/package created
- ActivityNumber field exists on transaction tables:
  - `ProjEmplTransSale`
  - `ProjCostTransSale`
  - `ProjItemTransSale`
  - `ProjRevenueTransSale`
  - `ProjOnAccTransSale` (optional)

### Implementation Steps

1. **Review Documentation**
   - Read `docs/TECHNICAL_DESIGN.md` for architecture overview
   - Read `docs/RISK_ASSESSMENT.md` for risks and considerations

2. **Create Table Extension**
   - Add `ActivityNumber` field to `ProjProposalJour`
   - Add index for performance

3. **Create Class Extensions**
   - Implement transaction filtering logic
   - Implement grouping logic

4. **Create Form Extensions** (Optional)
   - Display ActivityNumber on proposal forms

5. **Test in Sandbox**
   - Follow `docs/TESTING_GUIDE.md`
   - Validate all scenarios

6. **Deploy to Production**
   - Follow standard ALM process
   - Communicate changes to users

---

## Key Features

✅ **Transaction-Level Filtering**
- Automatically excludes transactions without ActivityNumber
- Provides clear feedback on skipped transactions

✅ **Activity-Based Grouping**
- Creates separate proposals for each unique ActivityNumber
- Maintains all standard grouping logic (currency, funding source, etc.)

✅ **Performance Optimized**
- Uses caching to minimize database queries
- Adds indexes for efficient lookups

✅ **Validation & Consistency**
- Validates ActivityNumber consistency within each proposal
- Prevents data integrity issues

✅ **User-Friendly**
- Clear information messages
- Detailed logging
- Helpful warnings for skipped transactions

---

## Technical Approach

### Chain of Command (CoC) Extensions

This solution uses D365 F&O Chain of Command pattern to:
- Extend standard functionality without modifying base code
- Maintain upgrade compatibility
- Follow Microsoft best practices

### Two Main Extension Classes

1. **ProjInvoiceProposalCreateLines_ActivityExtension**
   - Filters transactions during selection
   - Adds ActivityNumber criteria to queries
   - Tracks and reports skipped transactions

2. **ProjInvoiceProposalInsertLines_ActivityExtension**
   - Implements ActivityNumber grouping logic
   - Creates/finds proposals by ActivityNumber
   - Validates consistency

---

## Important Considerations

### ⚠️ Breaking Change

This is a **breaking change** in behavior:
- **Before**: Transactions without ActivityNumber are included in proposals
- **After**: Transactions without ActivityNumber are excluded

**Impact**: Users must ensure all transactions have ActivityNumber assigned before invoicing.

### 📊 Data Migration

If you have existing proposals:
- They will not have ActivityNumber populated
- Use provided migration scripts to backfill data
- Or accept that legacy proposals won't have activity tracking

### 🔒 Security & Permissions

No additional security setup required:
- Uses existing project invoice proposal privileges
- ActivityNumber field inherits table-level security

---

## Support & Contribution

### Issues

If you encounter issues:
1. Check `docs/TROUBLESHOOTING.md`
2. Review `docs/RISK_ASSESSMENT.md`
3. Open an issue in this repository

### Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request with detailed description

---

## License

This implementation guide is provided as-is for educational and reference purposes.

---

## Version History

### v1.0.0 (2025-11-16)
- Initial release
- Transaction-level filtering
- Activity-based grouping
- Comprehensive documentation

---

## Contact

For questions or support:
- Create an issue in this repository
- Review documentation in `/docs` folder

---

## Acknowledgments

- Based on Microsoft Dynamics 365 Finance & Operations standard functionality
- Follows Microsoft's extension and CoC best practices
- Designed for D365 F&O version 10.0.x
