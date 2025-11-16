import { Page } from '@playwright/test';

/**
 * Helper class for D365 F&O navigation
 */
export class D365FONavigation {
  constructor(private page: Page) {}

  /**
   * Navigate to a menu item using the navigation search
   */
  async navigateToMenuItem(menuItem: string): Promise<void> {
    // Click navigation search
    await this.page.click('[aria-label="Navigation search"]');
    
    // Type menu item name
    await this.page.fill('[aria-label="Navigation search"]', menuItem);
    
    // Wait for search results
    await this.page.waitForTimeout(1000);
    
    // Click first result
    await this.page.click(`text=${menuItem}`);
    
    // Wait for page to load
    await this.page.waitForLoadState('networkidle');
  }

  /**
   * Open a specific company
   */
  async selectCompany(companyCode: string): Promise<void> {
    // Click company selector
    await this.page.click('[aria-label="Company"]');
    
    // Select company
    await this.page.click(`text=${companyCode}`);
    
    // Wait for company change
    await this.page.waitForTimeout(2000);
  }

  /**
   * Wait for D365 form to load
   */
  async waitForFormLoad(): Promise<void> {
    await this.page.waitForLoadState('networkidle');
    await this.page.waitForTimeout(2000);
  }
}