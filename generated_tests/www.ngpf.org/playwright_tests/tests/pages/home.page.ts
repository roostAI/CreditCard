import { type Page, type Locator } from '@playwright/test';

/**
 * Page object for the NGPF Bank Simulator home / landing page.
 *
 * Owns:
 *   - navigation to the landing URL
 *   - readiness check (GET STARTED NOW button visible)
 *   - "GET STARTED NOW" action
 *   - welcome dialog dismissal
 *   - dashboard account-card accessors (read-only)
 */
export class HomePage {
  readonly page: Page;

  /** Landing page entry button */
  readonly getStartedButton: Locator;

  /** Welcome dialog OK button */
  readonly welcomeDialogOkButton: Locator;

  /** Dashboard – Checking account card header */
  readonly checkingAccountHeader: Locator;

  /** Dashboard – Checking account available balance */
  readonly checkingBalanceText: Locator;

  /** Dashboard – "VIEW ACCOUNT" button for the checking card */
  readonly viewCheckingAccountButton: Locator;

  /** Dashboard – Saving account card header */
  readonly savingAccountHeader: Locator;

  /** Dashboard – Saving account available balance */
  readonly savingBalanceText: Locator;

  constructor(page: Page) {
    this.page = page;
    this.getStartedButton = page.getByRole('button', { name: 'GET STARTED NOW' });
    this.welcomeDialogOkButton = page.getByRole('button', { name: 'Ok' });
    this.checkingAccountHeader = page.locator('mat-card-header').filter({ hasText: 'Checking Account Activity' });
    this.checkingBalanceText = page.getByText('$216.04');
    this.viewCheckingAccountButton = page.getByRole('button', { name: 'VIEW ACCOUNT' }).first();
    this.savingAccountHeader = page.locator('mat-card-header').filter({ hasText: 'Saving Account Activity' });
    this.savingBalanceText = page.getByText('$230.00');
  }

  /** Navigate to the simulator landing page. */
  async goto(): Promise<void> {
    await this.page.goto('/bank-sim/home?returnUrl=%2F');
    await this.getStartedButton.waitFor({ state: 'visible' });
  }

  /** Click GET STARTED NOW to enter the simulator. */
  async clickGetStarted(): Promise<void> {
    await this.getStartedButton.click();
  }

  /**
   * Dismiss the welcome dialog that appears after GET STARTED NOW.
   * Waits for the dialog to appear before clicking Ok.
   */
  async dismissWelcomeDialog(): Promise<void> {
    await this.welcomeDialogOkButton.waitFor({ state: 'visible' });
    await this.welcomeDialogOkButton.click();
    await this.welcomeDialogOkButton.waitFor({ state: 'hidden' });
  }

  /**
   * Return true when both account dashboard cards are visible.
   */
  async isDashboardVisible(): Promise<boolean> {
    return (
      (await this.checkingAccountHeader.isVisible()) &&
      (await this.savingAccountHeader.isVisible())
    );
  }

  /** Click "VIEW ACCOUNT" on the checking account card. */
  async goToCheckingAccount(): Promise<void> {
    await this.viewCheckingAccountButton.click();
  }
}
