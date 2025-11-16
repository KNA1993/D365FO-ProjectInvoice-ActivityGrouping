# Playwright MCP Tests for D365 F&O Project Invoice Activity Grouping

This directory contains automated end-to-end tests using Playwright for the D365 Finance & Operations Project Invoice Activity Grouping extension.

## Prerequisites

- Node.js 18+ installed
- Access to a D365 F&O environment (UAT/Sandbox recommended)
- Playwright MCP installed in VS Code

## Setup

1. **Install dependencies:**
   ```bash
   cd tests/playwright
   npm install
   ```

2. **Install Playwright browsers:**
   ```bash
   npx playwright install
   ```

3. **Configure environment:**
   Create a `.env` file in the `tests/playwright` directory:
   ```env
   D365_BASE_URL=https://your-instance.sandbox.operations.dynamics.com
   D365_COMPANY=YOUR_COMPANY_CODE
   D365_USERNAME=your.email@domain.com
   D365_PASSWORD=your_password
   ```

## Running Tests

### Using Playwright MCP in VS Code

With Playwright MCP installed, you can:

1. **Run tests interactively** via Copilot:
   - Ask: "Run the invoice proposal activity grouping tests"
   - Copilot will use MCP to execute tests and show results

2. **Debug tests** with browser interaction:
   - MCP allows real-time browser control
   - Navigate, click, and inspect elements during test execution

### Using Command Line

```bash
# Run all tests
npm test

# Run tests in headed mode (see browser)
npm run test:headed

# Run tests with UI mode
npm run test:ui

# Debug specific test
npm run test:debug

# View test report
npm run report
```

## Test Structure

```
tests/
├── fixtures/
│   └── d365fo-fixtures.ts       # Custom Playwright fixtures for D365
├── helpers/
│   ├── d365fo-navigation.ts     # Navigation helper functions
│   └── invoice-proposal-helpers.ts  # Invoice-specific helpers
├── invoice-proposal-activity-grouping.spec.ts  # Main test suite
└── smoke-tests.spec.ts          # Basic smoke tests
```

## Test Scenarios Covered

1. **Activity Column Display**: Verifies that the Activity column appears in invoice proposal lines
2. **Activity Grouping**: Confirms lines are properly grouped by activity number
3. **Line Addition**: Tests that grouping is maintained when adding new lines
4. **Invoice Posting**: Validates posting functionality with activity grouping (skipped by default)

## Using Playwright MCP

Playwright MCP provides enhanced testing capabilities:

### Browser Interaction
```typescript
// MCP allows direct browser control
await mcp_playwright_browser_navigate({ url: 'your-d365-url' });
await mcp_playwright_browser_click({ element: 'New button', ref: 'btn-new' });
await mcp_playwright_browser_snapshot(); // Get page state
```

### Page Snapshots
```typescript
// Capture accessibility snapshot for verification
const snapshot = await mcp_playwright_browser_snapshot();
// Analyze structure and content
```

### Wait Strategies
```typescript
// Wait for specific text to appear
await mcp_playwright_browser_wait_for({ text: 'Invoice posted successfully' });
```

## Customization

### Adding New Tests

1. Create a new `.spec.ts` file in the `tests/` directory
2. Import fixtures: `import { test, expect } from './fixtures/d365fo-fixtures'`
3. Write your test scenarios

### Extending Helpers

Add new helper methods to:
- `d365fo-navigation.ts` for general D365 navigation
- `invoice-proposal-helpers.ts` for invoice-specific operations

## Best Practices

1. **Use descriptive test names** that explain what is being tested
2. **Keep tests isolated** - each test should be independent
3. **Use page objects/helpers** instead of inline selectors
4. **Add waits appropriately** - D365 can be slow to load
5. **Skip destructive tests** by default (use `test.skip`)
6. **Use test data** that can be reliably recreated

## Troubleshooting

### Tests fail with timeout
- Increase timeouts in `playwright.config.ts`
- D365 F&O can be slow, especially in sandbox environments

### Authentication issues
- Ensure credentials are correct in `.env`
- You may need to handle MFA differently
- Consider using persistent auth state

### Element not found
- Use `mcp_playwright_browser_snapshot()` to inspect page structure
- D365 forms are dynamic - selectors may need adjustment
- Add appropriate waits before interacting with elements

## CI/CD Integration

To run tests in CI/CD pipelines:

```yaml
# Example GitHub Actions workflow
- name: Install dependencies
  run: |
    cd tests/playwright
    npm install
    npx playwright install --with-deps

- name: Run tests
  env:
    D365_BASE_URL: ${{ secrets.D365_BASE_URL }}
    D365_USERNAME: ${{ secrets.D365_USERNAME }}
    D365_PASSWORD: ${{ secrets.D365_PASSWORD }}
  run: |
    cd tests/playwright
    npm test

- name: Upload test results
  uses: actions/upload-artifact@v3
  if: always()
  with:
    name: playwright-report
    path: tests/playwright/playwright-report/
```

## Resources

- [Playwright Documentation](https://playwright.dev/)
- [Playwright MCP Guide](https://playwright.dev/docs/mcp)
- [D365 F&O Testing Best Practices](https://docs.microsoft.com/dynamics365/fin-ops-core/dev-itpro/testing/)

## Contributing

When adding new tests:
1. Follow the existing structure
2. Add appropriate comments and documentation
3. Test locally before committing
4. Update this README if adding new capabilities