import { expect, type Locator, type Page } from '@playwright/test';

/**
 * Bank Simulator dashboard shown after starting a session.
 * URL: /bank-sim/
 */
export class DashboardPage {
  readonly page: Page;
  readonly welcomeDialogOkButton: Locator;
  readonly checkingCard: Locator;
  readonly checkingAvailableBalanceLabel: Locator;
  readonly viewCheckingAccountButton: Locator;

  constructor(page: Page) {
    this.page = page;
    this.welcomeDialogOkButton = page.getByRole('button', { name: 'Ok' });
    this.checkingCard = page.locator('mat-card-header').filter({ hasText: 'Checking Account Activity' });
    this.checkingAvailableBalanceLabel = page.getByText('AVAILABLE BALANCE').first();
    this.viewCheckingAccountButton = page.getByRole('button', { name: 'VIEW ACCOUNT' }).first();
  }

  async dismissWelcomeDialog(): Promise<void> {
    await this.welcomeDialogOkButton.waitFor({ state: 'visible' });
    await this.welcomeDialogOkButton.click();
    await this.welcomeDialogOkButton.waitFor({ state: 'detached' });
  }

  async expectDashboardIsUsable(): Promise<void> {
    await expect(this.checkingCard).toBeVisible();
    await expect(this.checkingAvailableBalanceLabel).toBeVisible();
    await expect(this.viewCheckingAccountButton).toBeVisible();
  }

  async viewCheckingAccount(): Promise<void> {
    await this.viewCheckingAccountButton.click();
    await this.page.waitForURL(/\/bank-sim\/account\?type=checking/);
  }
}
