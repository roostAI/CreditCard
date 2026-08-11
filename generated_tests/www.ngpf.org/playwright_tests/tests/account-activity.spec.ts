import { test, expect } from '@playwright/test';
import { HomePage } from './pages/home.page';
import { AccountActivityPage } from './pages/account-activity.page';

test.describe('Account Activity', () => {
  test('verify bank simulator dashboard and view checking account activity', async ({ page }) => {
    const homePage = new HomePage(page);
    const accountActivityPage = new AccountActivityPage(page);

    await homePage.goto();
    await homePage.startSimulator();

    await homePage.dismissWelcomeModal();

    await homePage.openCheckingAccount();
    await accountActivityPage.expectLoaded();

    await accountActivityPage.selectSavingAccount();
    await accountActivityPage.expectLoaded();
  });
});
