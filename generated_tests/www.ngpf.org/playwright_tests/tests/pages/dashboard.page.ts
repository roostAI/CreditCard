import type { Locator, Page } from '@playwright/test';

/**
 * The simulator's account dashboard ("home" screen after a session has
 * started). Shows a one-time welcome dialog plus summary widgets for the
 * checking and saving accounts.
 */
export class DashboardPage {
  readonly page: Page;
  readonly welcomeDialogOkButton: Locator;
  readonly checkingAccountCardHeader: Locator;
  readonly savingAccountCardHeader: Locator;
  readonly checkingAvailableBalanceText: Locator;
  readonly savingAvailableBalanceText: Locator;
  readonly viewCheckingAccountButton: Locator;

  constructor(page: Page) {
    this.page = page;
    this.welcomeDialogOkButton = page.getByRole('button', { name: 'Ok' });
    this.checkingAccountCardHeader = page.locator('mat-card-header').filter({ hasText: 'Checking Account Activity' });
    this.savingAccountCardHeader = page.locator('mat-card-header').filter({ hasText: 'Saving Account Activity' });
    this.checkingAvailableBalanceText = page.locator('mat-card').filter({ hasText: 'Checking Account Activity' }).last().locator('.balance');
    this.savingAvailableBalanceText = page.locator('mat-card').filter({ hasText: 'Saving Account Activity' }).last().locator('.balance');
    this.viewCheckingAccountButton = page.getByRole('button', { name: 'VIEW ACCOUNT' }).first();
  }

  /** Dismiss the one-time welcome dialog shown after starting a session. */
  async dismissWelcomeDialog(): Promise<void> {
    await this.welcomeDialogOkButton.waitFor({ state: 'visible' });
    await this.welcomeDialogOkButton.click();
    await this.welcomeDialogOkButton.waitFor({ state: 'detached' });
  }

  /** Read the checking account's available balance shown on the dashboard. */
  async getCheckingAvailableBalanceText(): Promise<string> {
    const text = await this.checkingAvailableBalanceText.textContent();
    return (text ?? '').trim();
  }

  /** Open the checking account's read-only activity ledger. */
  async viewCheckingAccount(): Promise<void> {
    await this.viewCheckingAccountButton.click();
    await this.page.waitForURL('**/bank-sim/account?type=checking*');
  }
}
