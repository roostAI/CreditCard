import { type Page, type Locator } from '@playwright/test';

/**
 * Page object for the NGPF Bank Simulator Account Activity page.
 * Accessed via /bank-sim/account?type=checking (or ?type=saving).
 *
 * Owns:
 *   - readiness check (heading visible)
 *   - "Account Activity" heading locator
 *   - "SELECT ACCOUNT" section heading
 *   - Checking / Saving account tab buttons
 *   - Transaction table locator
 *   - Search textbox locator
 */
export class AccountActivityPage {
  readonly page: Page;

  /** "Account Activity" h2 heading */
  readonly pageHeading: Locator;

  /** "SELECT ACCOUNT" h3 heading */
  readonly selectAccountHeading: Locator;

  /** "Checking" tab button */
  readonly checkingTabButton: Locator;

  /** "Saving" tab button */
  readonly savingTabButton: Locator;

  /** Transaction table */
  readonly transactionTable: Locator;

  /** Search textbox */
  readonly searchTextbox: Locator;

  /** "Account Opening" cell in the transaction table */
  readonly accountOpeningCell: Locator;

  constructor(page: Page) {
    this.page = page;
    this.pageHeading = page.getByRole('heading', { name: 'Account Activity' });
    this.selectAccountHeading = page.getByRole('heading', { name: 'SELECT ACCOUNT' });
    this.checkingTabButton = page.getByRole('button', { name: 'Checking' });
    this.savingTabButton = page.getByRole('button', { name: 'Saving' });
    this.transactionTable = page.getByRole('table');
    this.searchTextbox = page.getByRole('textbox', { name: 'Search' });
    this.accountOpeningCell = page.getByRole('cell', { name: 'Account Opening' });
  }

  /** Wait for the Account Activity page to be ready. */
  async waitUntilReady(): Promise<void> {
    await this.pageHeading.waitFor({ state: 'visible' });
    await this.transactionTable.waitFor({ state: 'visible' });
  }

  /** Confirm the page heading is visible. */
  async isHeadingVisible(): Promise<boolean> {
    return this.pageHeading.isVisible();
  }

  /** Confirm the SELECT ACCOUNT section is visible. */
  async isSelectAccountVisible(): Promise<boolean> {
    return this.selectAccountHeading.isVisible();
  }

  /** Return the current page URL. */
  currentUrl(): string {
    return this.page.url();
  }
}
