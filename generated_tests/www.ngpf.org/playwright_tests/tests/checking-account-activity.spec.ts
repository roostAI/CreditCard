import { test, expect } from '@playwright/test';
import { HomePage } from './pages/home.page';
import { CheckingAccountActivityPage } from './pages/checking-account-activity.page';

test('View checking account activity and transaction history', async ({ page }) => {
  const homePage = new HomePage(page);
  const checkingAccountActivityPage = new CheckingAccountActivityPage(page);

  await homePage.goto();
  await homePage.getStarted();
  await homePage.dismissWelcomeDialog();
  await homePage.viewCheckingAccount();

  await checkingAccountActivityPage.isLoaded();
  await expect(checkingAccountActivityPage.accountHeading).toBeVisible();
});
