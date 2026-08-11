import { test } from '@playwright/test';
import { BankSimHomePage } from './pages/bank-sim-home.page';
import { BankSimDashboardPage } from './pages/bank-sim-dashboard.page';
import { BankSimAccountActivityPage } from './pages/bank-sim-account-activity.page';

/**
 * WF001 – account-activity
 * Start a simulator session, verify the dashboard is usable, and view
 * checking account activity (read-only; no account creation, transfers,
 * bill payments, or external financial activity).
 */
test('displays checking account activity from the simulator dashboard', async ({ page }) => {
  const homePage = new BankSimHomePage(page);
  const dashboardPage = new BankSimDashboardPage(page);
  const accountActivityPage = new BankSimAccountActivityPage(page);

  // S01 – Navigate to the home page and click GET STARTED NOW
  await homePage.goto();
  await homePage.clickGetStarted();

  // S02 – Welcome dialog must appear (required asynchronous readiness surface)
  await dashboardPage.waitForWelcomeDialog();

  // S03 – Dismiss the welcome dialog
  await dashboardPage.dismissWelcomeDialog();

  // S04 – Verify the checking account balance is displayed on the dashboard
  await dashboardPage.assertCheckingBalanceVisible();

  // S05 – Click VIEW ACCOUNT for the checking account
  await dashboardPage.openCheckingAccount();

  // S06 – Verify the account activity table is visible with transaction data
  await accountActivityPage.assertActivityTableVisible();
  await accountActivityPage.assertCheckingTabActive();
});
