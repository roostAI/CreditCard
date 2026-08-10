import { test, expect } from '@playwright/test';
import { HomePage } from './pages/home.page';
import { DashboardPage } from './pages/dashboard.page';

test.describe('home', () => {
  test('launch the bank simulator and enter the dashboard', async ({ page }) => {
    const homePage = new HomePage(page);
    const dashboardPage = new DashboardPage(page);

    // S01 – navigate to the landing page and click GET STARTED NOW
    await homePage.goto();
    await homePage.clickGetStarted();

    // S01 expected: browser navigates to /bank-sim/ and welcome dialog appears
    await expect(page).toHaveURL(/\/bank-sim\//);
    await dashboardPage.waitForWelcomeDialog();
    await expect(dashboardPage.welcomeDialogHeading).toBeVisible();

    // S02 – dismiss the welcome dialog
    await dashboardPage.dismissWelcomeDialog();

    // S02 expected: dialog is closed and dashboard is fully visible
    await expect(dashboardPage.welcomeDialogHeading).not.toBeVisible();
    await dashboardPage.waitForDashboard();

    await expect(dashboardPage.checkingAccountHeading).toBeVisible();
    await expect(dashboardPage.checkingAccountBalance).toBeVisible();

    await expect(dashboardPage.savingsAccountHeading).toBeVisible();
    await expect(dashboardPage.savingsAccountBalance).toBeVisible();

    await expect(dashboardPage.upcomingBillsHeading).toBeVisible();
  });
});
