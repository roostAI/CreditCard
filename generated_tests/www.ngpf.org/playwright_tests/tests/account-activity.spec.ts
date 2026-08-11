import { test } from '@playwright/test';
import { BankSimHomePage } from './pages/bank-sim-home.page';
import { BankSimDashboardPage } from './pages/bank-sim-dashboard.page';
import { AccountActivityPage } from './pages/account-activity.page';

test.describe('NGPF Bank Simulator account activity', () => {
  test('starts a simulator session and views the checking account activity', async ({ page }) => {
    const homePage = new BankSimHomePage(page);
    const dashboardPage = new BankSimDashboardPage(page);
    const accountActivityPage = new AccountActivityPage(page);

    await homePage.goto();
    await homePage.startSimulatorSession();

    await dashboardPage.dismissWelcomeDialog();
    await dashboardPage.expectDashboardUsable();

    await dashboardPage.viewCheckingAccount();
    await accountActivityPage.expectCheckingAccountActivityVisible();
  });
});
