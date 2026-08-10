import { test, expect } from '@playwright/test';
import { SimulatorPage } from './pages/simulator.page';
import { AccountActivityPage } from './pages/account-activity.page';

/**
 * WF002 – View checking and savings account transaction history
 *
 * Preconditions (established before the test begins):
 *   - None: the test starts from the landing page and creates its own session.
 */
test('WF002: view checking and savings account transaction history', async ({ page }) => {
  const simulator = new SimulatorPage(page);
  const accountActivity = new AccountActivityPage(page);

  // ── S01 ──────────────────────────────────────────────────────────────────────
  // Setup: Start the simulator from the landing page and dismiss the welcome dialog.
  // (These steps establish the precondition of an active session before S01 begins.)
  await simulator.goto();
  await simulator.startSimulator();
  await simulator.dismissWelcomeDialog();

  // Navigate to Account Activity via ACCOUNTS > ACCOUNT ACTIVITY.
  await simulator.goToAccountActivity();
  await accountActivity.waitForReady();

  // The page must load at /bank-sim/account.
  await expect(page).toHaveURL(/\/bank-sim\/account/);

  // The transaction table must display the expected six columns.
  await accountActivity.expectColumnHeaders(['Id', 'Date', 'Description', 'Amount', 'Balance', 'Actions']);

  // ── S02 ──────────────────────────────────────────────────────────────────────
  // Verify the Checking tab is active by default.
  expect(await accountActivity.isCheckingTabActive()).toBe(true);

  // The "Account Opening" row with $250.00 amount must be present.
  const descriptions = await accountActivity.getVisibleDescriptions();
  expect(descriptions.length).toBeGreaterThan(0);
  expect(descriptions).toContain('Account Opening');

  // The Account Opening row must show $250.00 in the Amount column.
  const accountOpeningAmount = await accountActivity.getAmountForDescription('Account Opening');
  expect(accountOpeningAmount).toContain('$250.00');

  // ── S03 ──────────────────────────────────────────────────────────────────────
  // Switch to the Saving account tab.
  await accountActivity.selectSavingAccount();

  // The Saving tab must now be active.
  expect(await accountActivity.isSavingTabActive()).toBe(true);
  expect(await accountActivity.isCheckingTabActive()).toBe(false);

  // The savings transaction table must contain the account-opening entry.
  const savingDescriptions = await accountActivity.getVisibleDescriptions();
  expect(savingDescriptions).toContain('Account Opening');

  // The savings table must also contain a Network ATM entry.
  expect(savingDescriptions).toContain('Network ATM');

  // The paginator must read "1 – 2 of 2" confirming exactly two savings rows.
  const paginatorText = await accountActivity.getPaginatorText();
  expect(paginatorText).toBe('1 – 2 of 2');
});
