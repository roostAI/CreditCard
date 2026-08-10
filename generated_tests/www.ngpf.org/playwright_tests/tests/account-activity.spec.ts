import { test, expect } from '@playwright/test';
import { HomePage } from './pages/home.page';
import { AccountActivityPage } from './pages/account-activity.page';

/**
 * Feature: Account Activity
 *
 * Happy-path test: Navigate from the NGPF Bank Simulator landing page,
 * enter the simulator, dismiss the welcome dialog, verify the dashboard,
 * then open the Checking account activity view and confirm the transaction
 * table is populated.
 *
 * This test is entirely read-only / safely reversible: no account creation,
 * no payments, no personal data submission.
 */
test.describe('Account Activity', () => {
  test('view checking account activity from the simulator home page', async ({ page }) => {
    const homePage = new HomePage(page);
    const accountActivityPage = new AccountActivityPage(page);

    // Step 1 – Navigate to the simulator landing page
    await homePage.goto();
    await expect(homePage.getStartedButton).toBeVisible();

    // Step 2 – Enter the simulator
    await homePage.clickGetStarted();

    // Step 3 – Dismiss the welcome dialog
    await homePage.dismissWelcomeDialog();

    // Step 4 – Verify the dashboard shows both account cards
    await expect(homePage.checkingAccountHeader).toBeVisible();
    await expect(homePage.savingAccountHeader).toBeVisible();

    // Step 5 – Navigate to the Checking account activity
    await homePage.goToCheckingAccount();

    // Step 6 – Verify the Account Activity page loaded correctly
    await accountActivityPage.waitUntilReady();
    await expect(page).toHaveURL(/\/bank-sim\/account\?type=checking/);
    await expect(accountActivityPage.pageHeading).toBeVisible();
    await expect(accountActivityPage.selectAccountHeading).toBeVisible();
    await expect(accountActivityPage.checkingTabButton).toBeVisible();
    await expect(accountActivityPage.savingTabButton).toBeVisible();
    await expect(accountActivityPage.transactionTable).toBeVisible();

    // Step 7 – Confirm the "Account Opening" seeded transaction is present
    await expect(accountActivityPage.accountOpeningCell).toBeVisible();
  });
});
