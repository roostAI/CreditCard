import { expect, Locator, Page } from '@playwright/test';

/**
 * NGPF Bank Simulator dashboard shown after starting a session
 * (https://www.ngpf.org/bank-sim/). Surfaces account summary cards and
 * dismisses the one-time welcome dialog.
 */
export class DashboardPage {
  readonly page: Page;
  readonly welcomeDialog: Locator;
  readonly welcomeDialogOkButton: Locator;
  readonly checkingCard: Locator;
  readonly checkingViewAccountButton: Locator;

  constructor(page: Page) {
    this.page = page;
    this.welcomeDialog = this.page.getByRole('dialog', { name: 'Welcome to the NGPF Bank' });
    this.welcomeDialogOkButton = this.welcomeDialog.getByRole('button', { name: 'Ok' });
    this.checkingCard = this.page.locator('mat-card.home-cards').filter({ hasText: 'Checking Account Activity' });
    this.checkingViewAccountButton = this.checkingCard.getByRole('button', { name: 'VIEW ACCOUNT' });
  }

  async dismissWelcomeDialog(): Promise<void> {
    await this.welcomeDialog.waitFor({ state: 'visible' });
    await this.welcomeDialogOkButton.click();
    await this.welcomeDialog.waitFor({ state: 'detached' });
  }

  async expectCheckingSummaryVisible(): Promise<void> {
    await expect(this.checkingCard).toBeVisible();
    await expect(this.checkingCard).toContainText('AVAILABLE BALANCE');
  }

  async viewCheckingAccount(): Promise<void> {
    await this.checkingViewAccountButton.click();
    await this.page.waitForURL('**/bank-sim/account?type=checking');
  }
}
