import { type Page, type Locator } from '@playwright/test';

/**
 * Shared navigation and simulator-start helpers used by all Bank Simulator pages.
 */
export class BankSimPage {
  readonly page: Page;

  // Landing page
  readonly getStartedButton: Locator;

  // Welcome dialog
  readonly welcomeDialogOkButton: Locator;

  // Nav – ACCOUNTS menu
  readonly accountsNavMenu: Locator;
  readonly accountActivityNavLink: Locator;

  constructor(page: Page) {
    this.page = page;
    this.getStartedButton = page.getByRole('button', { name: 'GET STARTED NOW' });
    this.welcomeDialogOkButton = page.getByRole('button', { name: 'Ok' });
    this.accountsNavMenu = page.locator('a').filter({ hasText: 'ACCOUNTS expand_more' });
    this.accountActivityNavLink = page.locator('app-menu-list-item').filter({ hasText: /^ACCOUNT ACTIVITY$/ });
  }

  /** Navigate to the simulator home page. */
  async goto(): Promise<void> {
    await this.page.goto('/bank-sim/home?returnUrl=%2F');
  }

  /**
   * Start the simulator: click GET STARTED NOW, then dismiss the welcome dialog.
   * Leaves the browser on /bank-sim/ (dashboard).
   */
  async startSimulator(): Promise<void> {
    await this.getStartedButton.click();
    await this.welcomeDialogOkButton.click();
  }

  /**
   * Navigate to ACCOUNTS > ACCOUNT ACTIVITY via the nav menu.
   * Assumes the simulator session is active (dashboard is visible).
   */
  async goToAccountActivity(): Promise<void> {
    await this.accountsNavMenu.click();
    await this.accountActivityNavLink.click();
    await this.page.waitForURL('**/bank-sim/account');
  }
}
