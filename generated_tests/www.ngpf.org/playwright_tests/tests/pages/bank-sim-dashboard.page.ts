import { expect, type Locator, type Page } from '@playwright/test';

/**
 * The bank simulator home dashboard shown after a simulator session has
 * started. Owns the first-run welcome dialog and the account activity
 * summary cards.
 */
export class BankSimDashboardPage {
  readonly page: Page;
  readonly welcomeDialog: Locator;
  readonly welcomeDialogOkButton: Locator;
  private readonly checkingAccountCard: Locator;
  readonly checkingAvailableBalanceLabel: Locator;
  private readonly checkingViewAccountButton: Locator;

  constructor(page: Page) {
    this.page = page;
    this.welcomeDialog = page.getByRole('dialog');
    this.welcomeDialogOkButton = page.getByRole('button', { name: 'Ok' });
    this.checkingAccountCard = page.locator('mat-card.home-cards', { has: page.locator('mat-card-header', { hasText: 'Checking Account Activity' }) });
    this.checkingAvailableBalanceLabel = this.checkingAccountCard.getByText('AVAILABLE BALANCE');
    this.checkingViewAccountButton = this.checkingAccountCard.getByRole('button', { name: 'VIEW ACCOUNT' });
  }

  async dismissWelcomeDialog(): Promise<void> {
    await this.welcomeDialog.waitFor({ state: 'visible' });
    await this.welcomeDialogOkButton.click();
    await this.welcomeDialog.waitFor({ state: 'detached' });
  }

  async expectDashboardUsable(): Promise<void> {
    await expect(this.checkingAccountCard).toBeVisible();
    await expect(this.checkingAvailableBalanceLabel).toBeVisible();
  }

  async viewCheckingAccount(): Promise<void> {
    await this.checkingViewAccountButton.click();
    await this.page.waitForURL(/\/bank-sim\/account\?type=checking/);
  }
}
