# Changelog

## [1.0.0] - 2025-01-16

### Added
- Activity Number grouping for project invoice proposals
- Table extension: `ProjProposalJour.ActivityNumber` field
- Class extension: `ProjInvoiceProposalCreateLines_ActivityExtension`
  - Filters transactions by Activity Number (hour, expense, item, fee, on-account)
  - Excludes transactions without Activity Number
- Class extension: `ProjInvoiceProposalInsertLines_ActivityExtension`
  - Groups proposals by Activity Number
  - Caching for improved performance
  - Validation for activity consistency
- Form extensions:
  - `ProjInvoiceProposalDetail` - Activity Number in header
  - `ProjInvoiceProposalListPage` - Activity Number column in grid
- Comprehensive documentation:
  - Implementation Guide
  - Technical Design Document
  - Risk Assessment
  - Testing Guide
  - User Guide
- SQL validation and migration scripts
- Unit test class template

### Changed
- Invoice proposal creation now groups by Activity Number in addition to standard grouping (Customer, Project, Currency, Funding Source)
- Transactions without Activity Number are **excluded** from proposals

### Business Impact
- One invoice proposal per activity per standard grouping
- Improved activity-based revenue tracking
- Better project phase billing visibility
- **Breaking Change**: Transactions without Activity Number will not be invoiced

### Technical Notes
- Uses Chain of Command (CoC) pattern for upgrade safety
- No modifications to standard code
- Backward compatible with existing proposals (new field is optional)
- Requires Activity Number field on all transaction sale tables

### Migration
- Existing proposals created before this release will not have Activity Number
- Use backfill script if historical data population is required
- Coordinate with users to assign activities before go-live

---

## Future Releases

### Planned Enhancements
- [ ] Feature flag for enable/disable
- [ ] Activity assignment wizard
- [ ] Activity validation against master data
- [ ] Activity-based approval workflow
- [ ] Enhanced reporting with activity analytics
- [ ] Multi-language label support
- [ ] Performance optimizations for extra-large volumes

### Known Limitations
- No automatic backfill of existing proposals
- Activity Number not validated against active activities
- OnAccount handling assumes field exists (runtime check included)

---

## Version History

| Version | Date | Description |
|---------|------|-------------|
| 1.0.0 | 2025-01-16 | Initial release with activity grouping |

---

**Maintained by**: [Your Organization]  
**Support**: [Support Email/Link]  
**License**: [Your License]
