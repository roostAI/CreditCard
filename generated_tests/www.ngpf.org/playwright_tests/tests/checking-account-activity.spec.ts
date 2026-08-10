/**
 * Feature: checking-account-activity
 *
 * Happy-path: Navigate from the NGPF Bank Simulator home page to the
 * Checking Account Activity view and verify the transaction table is
 * populated.  This is a read-only, reversible simulator workflow.
 */
import { test, expect } from '@playwright/test';
import { HomeSplashPage } from './pages/home-splash.page';
import { DashboardPage } from './pages/dashboard.page';
import { AccountActivityPage } from './pages/account-activity.page';

test.describe('Checking Account Activity', () => {
  test('displays the checking account transaction table from the home splash screen', async ({ page }) => {
    const homeSplash = new HomeSplashPage(page);
    const dashboard = new DashboardPage(page);
    const accountActivity = new AccountActivityPage(page);

    // Step 1 – Open the home splash screen
    await homeSplash.goto();
    await expect(homeSplash.getStartedButton).toBeVisible();

    // Step 2 – Launch the simulator
    await homeSplash.getStarted();

    // Step 3 – Wait for the dashboard; dismiss the welcome dialog if present
    await dashboard.waitForReady();
    await dashboard.dismissWelcomeDialog();

    // Step 4 – Verify the Checking Account Activity card and balance are shown
    await expect(dashboard.checkingAccountCard).toBeVisible();
    await expect(dashboard.checkingAvailableBalance).toBeVisible();

    // Step 5 – Navigate to the Checking Account Activity table
    await dashboard.openCheckingAccountActivity();

    // Step 6 – Assert the account activity page loaded correctly
    await accountActivity.waitForReady();
    await expect(accountActivity.heading).toBeVisible();

    // Step 7 – Assert the URL is correct
    await expect(page).toHaveURL(/\/account\?type=checking/);

    // Step 8 – Verify the table has the expected column structure
    const columns = await accountActivity.getColumnHeaders();
    expect(columns).toEqual(['Id', 'Date', 'Description', 'Amount', 'Balance', 'Actions']);

    // Step 9 – Verify at least one transaction row is present
    const rowCount = await accountActivity.getRowCount();
    expect(rowCount).toBeGreaterThan(0);

    // Step 10 – Verify pagination is shown and reports rows
    const paginationText = await accountActivity.getPaginationText();
    expect(paginationText).toMatch(/\d+\s*[–-]\s*\d+\s+of\s+\d+/);

    // Step 11 – Verify the SELECT ACCOUNT toggle shows Checking
    await expect(accountActivity.selectAccountLabel).toBeVisible();
    await expect(accountActivity.checkingToggleButton).toBeVisible();
  });
});
