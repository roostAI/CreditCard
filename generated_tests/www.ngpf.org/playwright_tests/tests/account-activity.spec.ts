import { test, expect } from '@playwright/test';
import { HomePage } from './pages/home.page';
import { DashboardPage } from './pages/dashboard.page';
import { AccountActivityPage } from './pages/account-activity.page';

test.describe('account activity', () => {
  test('starts a simulator session and reviews checking account activity', async ({ page }) => {
    const home = new HomePage(page);
    const dashboard = new DashboardPage(page);
    const accountActivity = new AccountActivityPage(page);

    // Start a new simulator session.
    await home.goto();
    await expect(home.getStartedButton).toBeVisible();
    await home.getStarted();
    await dashboard.dismissWelcomeDialog();

    // Verify the dashboard is usable: both accounts show a summary widget
    // with an available balance.
    await expect(dashboard.checkingAccountCardHeader).toBeVisible();
    await expect(dashboard.savingAccountCardHeader).toBeVisible();
    await expect(dashboard.checkingAvailableBalanceText).toBeVisible();
    await expect(dashboard.savingAvailableBalanceText).toBeVisible();

    const checkingBalance = await dashboard.getCheckingAvailableBalanceText();
    expect(checkingBalance).not.toHaveLength(0);

    // Safe, read-only account activity journey: open the checking ledger
    // and confirm it reflects the same balance shown on the dashboard.
    await dashboard.viewCheckingAccount();

    await expect(accountActivity.heading).toBeVisible();
    await expect(accountActivity.balanceCellByText(checkingBalance)).toBeVisible();
  });
});
