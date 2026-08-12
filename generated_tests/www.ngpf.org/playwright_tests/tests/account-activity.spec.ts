import { test, expect } from '@playwright/test';
import { LandingPage } from './pages/landing.page';
import { DashboardPage } from './pages/dashboard.page';
import { AccountActivityPage } from './pages/account-activity.page';

test.describe('Account Activity', () => {
  test('verify dashboard and checking account activity', async ({ page }) => {
    const landingPage = new LandingPage(page);
    const dashboardPage = new DashboardPage(page);
    const accountActivityPage = new AccountActivityPage(page);

    await landingPage.goto();
    await landingPage.clickGetStarted();

    await dashboardPage.dismissWelcomeDialogIfVisible();
    await dashboardPage.navigateToCheckingAccount();

    await expect(accountActivityPage.accountActivityHeading).toBeVisible();
    await expect(accountActivityPage.checkingAccountButton).toBeVisible();
  });
});
