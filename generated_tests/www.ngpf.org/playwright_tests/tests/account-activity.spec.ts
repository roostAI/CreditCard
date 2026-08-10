import { test, expect } from '@playwright/test';
import { BankSimPage } from './pages/bank-sim.page';
import { AccountActivityPage } from './pages/account-activity.page';

/**
 * WF003 – Search transactions on the Account Activity page
 *
 * Preconditions (established before the test begins):
 *   - An active simulator session exists
 *   - The Account Activity page is loaded at /bank-sim/account with the Checking tab active
 */
test('searches and clears transactions on the Account Activity page', async ({ page }) => {
  const bankSim = new BankSimPage(page);
  const accountActivity = new AccountActivityPage(page);

  // S01 – Navigate to ACCOUNTS > ACCOUNT ACTIVITY via the nav menu
  // Expected: Account Activity page displayed with Checking table showing multiple rows
  await bankSim.goto();
  await bankSim.startSimulator();
  await bankSim.goToAccountActivity();
  await accountActivity.waitForReady();

  const unfiltered = await accountActivity.getVisibleRowCount();
  expect(unfiltered).toBeGreaterThan(1);

  // S02 – Type 'Streamwave' into the Search textbox
  // Expected: table filters live to show only rows containing 'Streamwave'; others hidden
  await accountActivity.searchFor('Streamwave');

  await expect(accountActivity.paginationSummary).toContainText('1 of 1');
  await expect(accountActivity.transactionTable).toContainText('Streamwave Videos');
  await expect(accountActivity.transactionTable).not.toContainText('Snack Shack');
  await expect(accountActivity.transactionTable).not.toContainText('Account Opening');

  // S03 – Clear the search textbox
  // Expected: full unfiltered transaction list is restored
  await accountActivity.clearSearch();

  await expect(accountActivity.paginationSummary).toContainText(`${unfiltered} of ${unfiltered}`);
  await expect(accountActivity.transactionTable).toContainText('Streamwave Videos');
  await expect(accountActivity.transactionTable).toContainText('Snack Shack');
  await expect(accountActivity.transactionTable).toContainText('Account Opening');
});
