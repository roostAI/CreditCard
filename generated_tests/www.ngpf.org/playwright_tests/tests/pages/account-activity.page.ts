import { type Page, type Locator, expect } from '@playwright/test';

/**
 * Page object for the Account Activity page (/bank-sim/account).
 * Owns all locators, navigation readiness, and UI actions for this surface.
 */
export class AccountActivityPage {
  readonly page: Page;

  // Account tab buttons
  readonly checkingTab: Locator;

  // Search input
  readonly searchInput: Locator;

  // Transaction table and rows
  readonly transactionTable: Locator;
  readonly transactionRows: Locator;

  // Pagination summary text
  readonly paginationSummary: Locator;

  constructor(page: Page) {
    this.page = page;
    this.checkingTab = page.getByRole('button', { name: 'Checking' });
    this.searchInput = page.getByRole('textbox', { name: 'Search' });
    this.transactionTable = page.getByRole('table');
    this.transactionRows = page.getByRole('table').locator('tbody tr');
    this.paginationSummary = page.locator('mat-paginator .mat-mdc-paginator-range-label, mat-paginator .mat-paginator-range-label').first();
  }

  /** Wait for the Account Activity page to be ready with at least one transaction row. */
  async waitForReady(): Promise<void> {
    await expect(this.page).toHaveURL(/\/bank-sim\/account/);
    await expect(this.checkingTab).toBeVisible();
    await expect(this.transactionTable).toBeVisible();
  }

  /**
   * Type text into the search box using keyboard events so Angular's
   * input listeners fire correctly.
   */
  async searchFor(keyword: string): Promise<void> {
    await this.searchInput.click();
    await this.page.keyboard.type(keyword);
  }

  /** Clear the search box (triggers live filter reset). */
  async clearSearch(): Promise<void> {
    await this.searchInput.fill('');
  }

  /**
   * Return the number of visible transaction rows in the table body.
   */
  async getVisibleRowCount(): Promise<number> {
    return this.transactionRows.count();
  }
}
