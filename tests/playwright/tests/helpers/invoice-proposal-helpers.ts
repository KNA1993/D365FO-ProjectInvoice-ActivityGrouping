import { Page } from '@playwright/test';
import { D365FONavigation } from './d365fo-navigation';

/**
 * Helper class for Project Invoice Proposal operations
 */
export class InvoiceProposalHelpers {
  private navigation: D365FONavigation;

  constructor(private page: Page) {
    this.navigation = new D365FONavigation(page);
  }

  /**
   * Navigate to Project Invoice Proposals
   */
  async navigateToInvoiceProposals(): Promise<void> {
    await this.navigation.navigateToMenuItem('Invoice proposals');
  }

  /**
   * Create a new invoice proposal
   */
  async createInvoiceProposal(projectId: string): Promise<void> {
    // Click New button
    await this.page.click('button:has-text("New")');
    
    // Wait for dialog
    await this.page.waitForTimeout(1000);
    
    // Fill project ID
    await this.page.fill('[name="ProjectId"]', projectId);
    
    // Click OK
    await this.page.click('button:has-text("OK")');
    
    await this.navigation.waitForFormLoad();
  }

  /**
   * Verify activity grouping on invoice proposal lines
   */
  async verifyActivityGrouping(): Promise<boolean> {
    // Navigate to lines
    await this.page.click('text=Invoice proposal lines');
    
    await this.page.waitForTimeout(1000);
    
    // Check if Activity column exists
    const activityColumn = await this.page.locator('th:has-text("Activity")');
    return await activityColumn.isVisible();
  }

  /**
   * Get invoice proposal lines grouped by activity
   */
  async getLinesByActivity(): Promise<Map<string, number>> {
    const activityGroups = new Map<string, number>();
    
    // Get all activity cells
    const activityCells = await this.page.locator('td[data-dyn-role="ActivityNumber"]').all();
    
    for (const cell of activityCells) {
      const activityNumber = await cell.textContent();
      if (activityNumber) {
        const trimmed = activityNumber.trim();
        activityGroups.set(trimmed, (activityGroups.get(trimmed) || 0) + 1);
      }
    }
    
    return activityGroups;
  }

  /**
   * Post invoice proposal
   */
  async postInvoiceProposal(): Promise<void> {
    await this.page.click('button:has-text("Post")');
    
    // Wait for posting dialog
    await this.page.waitForTimeout(1000);
    
    // Confirm post
    await this.page.click('button:has-text("OK")');
    
    // Wait for posting to complete
    await this.page.waitForTimeout(5000);
  }
}