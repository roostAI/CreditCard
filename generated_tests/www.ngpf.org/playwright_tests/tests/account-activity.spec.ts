import { test } from '@playwright/test';
import { HomePage } from './pages/bank-sim-home.page';
import { DashboardPage } from './pages/bank-sim-dashboard.page';
import { AccountActivityPage } from './pages/bank-sim-account.page';

test.describe('account activity', () => {
  test('starts a simulator session and views checking account activity', async ({ page }) => {
    const homePage = new HomePage(page);
    const dashboardPage = new DashboardPage(page);
    const accountActivityPage = new AccountActivityPage(page);

    await homePage.goto();
    await homePage.startSimulator();

    await dashboardPage.dismissWelcomeDialog();
    await dashboardPage.expectDashboardIsUsable();

    await dashboardPage.viewCheckingAccount();
    await accountActivityPage.expectCheckingActivityIsDisplayed();
  });
});
