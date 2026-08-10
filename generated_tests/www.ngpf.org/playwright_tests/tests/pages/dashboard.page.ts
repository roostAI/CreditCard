import { Page, Locator } from '@playwright/test';

/**
 * DashboardPage - NGPF Bank Simulator main dashboard at /bank-sim/
 * Owns selectors and actions for the dashboard surface including the
 * welcome dialog that appears on first entry.
 */
export class DashboardPage {
  readonly page: Page;

  // Welcome dialog
  readonly welcomeDialogHeading: Locator;
  readonly welcomeDialogOkButton: Locator;

  // Checking account card
  readonly checkingAccountHeading: Locator;
  readonly checkingAccountBalance: Locator;

  // Savings account card
  readonly savingsAccountHeading: Locator;
  readonly savingsAccountBalance: Locator;

  // Upcoming bills section
  readonly upcomingBillsHeading: Locator;

  constructor(page: Page) {
    this.page = page;

    this.welcomeDialogHeading = page.getByRole('heading', { name: 'Welcome to the NGPF Bank Simulator' });
    this.welcomeDialogOkButton = page.getByRole('button', { name: 'Ok' });

    this.checkingAccountHeading = page.getByText('Checking Account Activity');
    this.checkingAccountBalance = page.getByText('$216.04');

    this.savingsAccountHeading = page.getByText('Saving Account Activity');
    this.savingsAccountBalance = page.getByText('$230.00');

    this.upcomingBillsHeading = page.getByText('Upcoming Bills');
  }

  /** Wait for the welcome dialog to be visible after navigation. */
  async waitForWelcomeDialog(): Promise<void> {
    await this.welcomeDialogHeading.waitFor({ state: 'visible' });
  }

  /** Dismiss the welcome dialog by clicking Ok. */
  async dismissWelcomeDialog(): Promise<void> {
    await this.welcomeDialogOkButton.click();
    await this.welcomeDialogHeading.waitFor({ state: 'hidden' });
  }

  /** True when the welcome dialog is no longer in the DOM. */
  async isWelcomeDialogClosed(): Promise<boolean> {
    return !(await this.welcomeDialogHeading.isVisible());
  }

  /** Wait until the dashboard cards are rendered. */
  async waitForDashboard(): Promise<void> {
    await this.checkingAccountBalance.waitFor({ state: 'visible' });
    await this.savingsAccountBalance.waitFor({ state: 'visible' });
    await this.upcomingBillsHeading.waitFor({ state: 'visible' });
  }
}
