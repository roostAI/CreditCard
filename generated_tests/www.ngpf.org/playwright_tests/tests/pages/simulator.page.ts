import { type Page, type Locator } from '@playwright/test';

/**
 * SimulatorPage – owns the landing/home surface and the shared simulator
 * navigation, including the GET STARTED NOW button, the welcome dialog, and
 * the top-level nav menu links.
 *
 * Selectors are grounded against https://www.ngpf.org/bank-sim/home?returnUrl=%2F
 * (observed 2026-08-10).
 */
export class SimulatorPage {
  readonly page: Page;

  // Landing page
  readonly getStartedButton: Locator;

  // Welcome dialog
  readonly welcomeDialog: Locator;
  readonly welcomeDialogOkButton: Locator;

  // Sidebar navigation – the text spans inside the mat-list-item links.
  readonly accountsNavItem: Locator;
  readonly accountActivityNavItem: Locator;

  constructor(page: Page) {
    this.page = page;

    this.getStartedButton = page.getByRole('button', { name: 'GET STARTED NOW' });

    this.welcomeDialog = page.locator('[role="dialog"]');
    this.welcomeDialogOkButton = this.welcomeDialog.getByRole('button', { name: 'Ok' });

    // The sidebar nav items are identified by their exact visible text.
    this.accountsNavItem = page.getByText('ACCOUNTS', { exact: true }).first();
    this.accountActivityNavItem = page.getByText('ACCOUNT ACTIVITY', { exact: true });
  }

  /** Navigate to the landing/home page. */
  async goto(): Promise<void> {
    await this.page.goto('/bank-sim/home?returnUrl=%2F');
    await this.getStartedButton.waitFor({ state: 'visible' });
  }

  /**
   * Click GET STARTED NOW and wait for the simulator dashboard to load.
   * The welcome dialog is shown after navigation.
   */
  async startSimulator(): Promise<void> {
    await this.getStartedButton.click();
    await this.page.waitForURL('**/bank-sim/**');
    await this.welcomeDialog.waitFor({ state: 'visible' });
  }

  /** Dismiss the welcome dialog by clicking Ok. */
  async dismissWelcomeDialog(): Promise<void> {
    await this.welcomeDialogOkButton.click();
    await this.welcomeDialog.waitFor({ state: 'hidden' });
  }

  /** Expand the ACCOUNTS submenu in the sidebar. */
  async openAccountsMenu(): Promise<void> {
    await this.accountsNavItem.click();
  }

  /** Navigate to the Account Activity page via the ACCOUNTS submenu. */
  async goToAccountActivity(): Promise<void> {
    await this.openAccountsMenu();
    await this.accountActivityNavItem.click();
    await this.page.waitForURL('**/bank-sim/account');
  }
}
