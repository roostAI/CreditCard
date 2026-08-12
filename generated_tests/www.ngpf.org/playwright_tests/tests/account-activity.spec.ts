import { test, expect } from '@playwright/test';
import { BankSimulatorPage } from './pages/bank-simulator.page';

test('User views checking account activity', async ({ page }) => {
  const bankSimPage = new BankSimulatorPage(page);

  await bankSimPage.goto();
  await bankSimPage.startSimulator();
  await bankSimPage.dismissWelcomeDialog();
  await expect(bankSimPage.viewCheckingAccountButton).toBeVisible();

  await bankSimPage.viewCheckingAccount();
  await expect(bankSimPage.accountActivityHeading).toBeVisible();

  await bankSimPage.selectSavingsAccount();
  await expect(bankSimPage.savingsTabButton).toBeVisible();

  await bankSimPage.selectCheckingAccount();
  await expect(bankSimPage.checkingTabButton).toBeVisible();
});
