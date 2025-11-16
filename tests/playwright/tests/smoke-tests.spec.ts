import { test, expect } from './fixtures/d365fo-fixtures';

/**
 * Smoke tests to verify basic D365 F&O functionality
 */
test.describe('D365 F&O - Smoke Tests', () => {
  
  test('should load D365 F&O dashboard', async ({ authenticatedPage }) => {
    // Verify dashboard loaded
    await expect(authenticatedPage).toHaveTitle(/Finance and Operations/);
  });

  test('should have navigation menu accessible', async ({ d365Page }) => {
    // Check if navigation search is available
    const navSearch = d365Page.locator('[aria-label="Navigation search"]');
    await expect(navSearch).toBeVisible({ timeout: 10000 });
  });

  test('should display user profile', async ({ d365Page }) => {
    // Check if user profile menu exists
    const userProfile = d365Page.locator('[aria-label="User"]').first();
    await expect(userProfile).toBeVisible({ timeout: 10000 });
  });
});