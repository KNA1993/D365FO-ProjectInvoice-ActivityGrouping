import { test as base, Page } from '@playwright/test';

/**
 * Custom fixtures for D365 F&O testing
 */
export type D365FOFixtures = {
  d365Page: Page;
  authenticatedPage: Page;
};

export const test = base.extend<D365FOFixtures>({
  /**
   * Authenticated D365 F&O page fixture
   */
  authenticatedPage: async ({ page }, use) => {
    // Navigate to D365 F&O
    const baseUrl = process.env.D365_BASE_URL || 'https://your-instance.sandbox.operations.dynamics.com';
    await page.goto(baseUrl);
    
    // Wait for authentication (adjust based on your auth flow)
    // If already authenticated, this should load the dashboard
    await page.waitForLoadState('networkidle');
    
    // Wait for D365 frame to load
    await page.waitForTimeout(5000);
    
    await use(page);
  },
  
  /**
   * D365 F&O page with navigation helper
   */
  d365Page: async ({ authenticatedPage }, use) => {
    await use(authenticatedPage);
  },
});

export { expect } from '@playwright/test';