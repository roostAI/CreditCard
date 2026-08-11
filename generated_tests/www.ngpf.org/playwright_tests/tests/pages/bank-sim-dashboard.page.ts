import { type Page, type Locator, expect } from '@playwright/test';

/**
 * BankSimDashboardPage – models the NGPF Bank Simulator dashboard.
 * URL: https://www.ngpf.org/bank-sim/
 *
 * On first load a welcome dialog is shown; the caller must dismiss it before
 * interacting with dashboard content.
 */
export class BankSimDashboardPage {
  readonly page: Page;

  // SEL002 – welcome dialog heading
  readonly welcomeDialogHeading: Locator;

  // SEL003 – Ok button inside the welcome dialog
  readonly welcomeDialogOkButton: Locator;

  // SEL004 – checking account card header on the dashboard
  readonly checkingCardHeader: Locator;

  // SEL005 – VIEW ACCOUNT button for the checking account (first button)
  readonly viewCheckingAccountButton: Locator;

  constructor(page: Page) {
    this.page = page;
    this.welcomeDialogHeading = page.getByRole('heading', { name: 'Welcome to the NGPF Bank' });
    this.welcomeDialogOkButton = page.getByRole('button', { name: 'Ok' });
    this.checkingCardHeader = page.locator('mat-card-header').filter({ hasText: 'Checking Account Activity' });
    this.viewCheckingAccountButton = page.getByRole('button', { name: 'VIEW ACCOUNT' }).first();
  }

  /**
   * Wait for the welcome dialog to appear after the simulator session starts.
   * The dialog is rendered asynchronously; do not test for optional presence.
   */
  async waitForWelcomeDialog(): Promise<void> {
    await this.welcomeDialogHeading.waitFor({ state: 'visible' });
  }

  /**
   * Dismiss the welcome dialog and wait for it to detach from the DOM.
   * Implements SEL003.
   */
  async dismissWelcomeDialog(): Promise<void> {
    await this.welcomeDialogOkButton.waitFor({ state: 'visible' });
    await this.welcomeDialogOkButton.click();
    await this.welcomeDialogOkButton.waitFor({ state: 'detached' });
  }

  /**
   * Assert that the checking account card and VIEW ACCOUNT button are visible.
   * Implements SEL004/SEL005 visibility check.
   */
  async assertCheckingBalanceVisible(): Promise<void> {
    await expect(this.checkingCardHeader).toBeVisible();
    await expect(this.viewCheckingAccountButton).toBeVisible();
  }

  /**
   * Click VIEW ACCOUNT for the checking account card.
   * Waits for navigation to the account activity page.
   * Implements SEL005.
   */
  async openCheckingAccount(): Promise<void> {
    await this.viewCheckingAccountButton.click();
    await this.page.waitForURL('**/bank-sim/account?type=checking');
  }
}
