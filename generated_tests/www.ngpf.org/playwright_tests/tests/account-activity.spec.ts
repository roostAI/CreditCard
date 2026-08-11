import { test } from '@playwright/test';
import { LandingPage } from './pages/landing.page';
import { DashboardPage } from './pages/dashboard.page';
import { AccountActivityPage } from './pages/account-activity.page';

test.describe('account activity', () => {
  test('starts a bank simulator session and views checking account activity', async ({ page }) => {
    const landingPage = new LandingPage(page);
    const dashboardPage = new DashboardPage(page);
    const accountActivityPage = new AccountActivityPage(page);

    await landingPage.goto();
    await landingPage.startSession();

    await dashboardPage.dismissWelcomeDialog();
    await dashboardPage.expectCheckingSummaryVisible();

    await dashboardPage.viewCheckingAccount();

    await accountActivityPage.waitForReady();
    await accountActivityPage.expectCheckingAccountSelected();
    await accountActivityPage.expectTransactionsVisible();
  });
});
