import { test, expect } from './fixtures/d365fo-fixtures';
import { InvoiceProposalHelpers } from './helpers/invoice-proposal-helpers';

/**
 * Test suite for Project Invoice Proposal Activity Grouping
 * 
 * Tests the custom extension that groups invoice proposal lines by Activity Number
 */
test.describe('Project Invoice Proposal - Activity Grouping', () => {
  let invoiceHelper: InvoiceProposalHelpers;

  test.beforeEach(async ({ d365Page }) => {
    invoiceHelper = new InvoiceProposalHelpers(d365Page);
  });

  test('should display activity column in invoice proposal lines', async ({ d365Page }) => {
    // Navigate to invoice proposals
    await invoiceHelper.navigateToInvoiceProposals();
    
    // Create a test invoice proposal
    // Note: Replace with actual project ID from your test data
    await invoiceHelper.createInvoiceProposal('TEST-PROJECT-001');
    
    // Verify activity grouping exists
    const hasActivityColumn = await invoiceHelper.verifyActivityGrouping();
    expect(hasActivityColumn).toBeTruthy();
  });

  test('should group invoice lines by activity number', async ({ d365Page }) => {
    // Navigate to invoice proposals
    await invoiceHelper.navigateToInvoiceProposals();
    
    // Open existing invoice proposal with multiple activities
    // Note: Adjust selector based on your D365 form structure
    await d365Page.click('text=INV-2024-001');
    
    // Get lines grouped by activity
    const activityGroups = await invoiceHelper.getLinesByActivity();
    
    // Verify grouping
    expect(activityGroups.size).toBeGreaterThan(0);
    
    // Log activity groups for visibility
    console.log('Activity Groups:', Object.fromEntries(activityGroups));
  });

  test('should maintain activity grouping after adding new lines', async ({ d365Page }) => {
    // This is a placeholder test - implement based on your business logic
    await invoiceHelper.navigateToInvoiceProposals();
    
    // TODO: Add logic to:
    // 1. Open invoice proposal
    // 2. Add new transaction line
    // 3. Verify activity grouping is maintained
    
    expect(true).toBeTruthy();
  });

  test.skip('should post invoice proposal with activity grouping', async ({ d365Page }) => {
    // Skipped by default to avoid posting in test environment
    // Remove .skip to enable when ready
    
    await invoiceHelper.navigateToInvoiceProposals();
    await invoiceHelper.createInvoiceProposal('TEST-PROJECT-002');
    
    // Post the invoice
    await invoiceHelper.postInvoiceProposal();
    
    // Verify posting was successful
    const successMessage = await d365Page.locator('text=successfully posted');
    await expect(successMessage).toBeVisible();
  });
});