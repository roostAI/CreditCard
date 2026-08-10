import { type Page, type Locator, expect } from '@playwright/test';

/**
 * AccountActivityPage – owns locators and readiness for the Account Activity
 * surface at /bank-sim/account.
 *
 * Selectors are grounded against the live application (observed 2026-08-10).
 *
 * Tab state uses a custom button-based switcher (not Angular Material tabs):
 *   - The active tab button has the CSS class `active`.
 *   - Clicking the inactive button switches the table content.
 */
export class AccountActivityPage {
  readonly page: Page;

  // Account selector buttons
  readonly checkingTabButton: Locator;
  readonly savingTabButton: Locator;

  // Transaction table elements
  readonly transactionTable: Locator;
  readonly tableHeaderRow: Locator;
  readonly tableRows: Locator;

  // Pagination
  readonly paginatorRangeLabel: Locator;

  constructor(page: Page) {
    this.page = page;

    this.checkingTabButton = page.getByRole('button', { name: 'Checking' });
    this.savingTabButton = page.getByRole('button', { name: 'Saving' });

    // The Angular Material table renders as a native <table>; header cells are <th mat-header-cell>.
    this.transactionTable = page.locator('table.mat-table').first();
    this.tableHeaderRow = page.locator('tr.mat-header-row').first();
    this.tableRows = page.locator('tr.mat-row');

    this.paginatorRangeLabel = page.locator('.mat-paginator-range-label');
  }

  /** Wait for the Account Activity page to be fully loaded. */
  async waitForReady(): Promise<void> {
    await this.page.waitForURL('**/bank-sim/account');
    await this.checkingTabButton.waitFor({ state: 'visible' });
    await this.transactionTable.waitFor({ state: 'visible' });
  }

  /**
   * Return `true` when the Checking tab button has the `active` CSS class.
   */
  async isCheckingTabActive(): Promise<boolean> {
    const cls = await this.checkingTabButton.getAttribute('class');
    return cls?.includes('active') ?? false;
  }

  /**
   * Return `true` when the Saving tab button has the `active` CSS class.
   */
  async isSavingTabActive(): Promise<boolean> {
    const cls = await this.savingTabButton.getAttribute('class');
    return cls?.includes('active') ?? false;
  }

  /** Click the Saving tab button to switch to the savings account view. */
  async selectSavingAccount(): Promise<void> {
    await this.savingTabButton.click();
    // Wait for at least one row to render after the table updates.
    await this.tableRows.first().waitFor({ state: 'visible' });
  }

  /** Return all visible column header texts (trimmed). */
  async getColumnHeaders(): Promise<string[]> {
    // Headers are <th mat-header-cell role="columnheader"> inside the table.
    const headers = this.page.locator('th[role="columnheader"]');
    const count = await headers.count();
    const texts: string[] = [];
    for (let i = 0; i < count; i++) {
      const text = (await headers.nth(i).textContent())?.trim() ?? '';
      if (text) texts.push(text);
    }
    return texts;
  }

  /** Return all visible transaction description texts (trimmed). */
  async getVisibleDescriptions(): Promise<string[]> {
    // The Description column is the 3rd <td> (index 2) in each row.
    const descriptionCells = this.page.locator('tr.mat-row td:nth-child(3)');
    const count = await descriptionCells.count();
    const texts: string[] = [];
    for (let i = 0; i < count; i++) {
      const raw = (await descriptionCells.nth(i).textContent())?.trim() ?? '';
      // Strip Material icon text ("refresh") that appears before the description.
      const cleaned = raw.replace(/^refresh\s*/i, '').trim();
      if (cleaned) texts.push(cleaned);
    }
    return texts;
  }

  /** Return the Amount cell text for the row matching the given description. */
  async getAmountForDescription(description: string): Promise<string> {
    const row = this.tableRows.filter({ hasText: description }).first();
    const amountCell = row.locator('td').nth(3);
    return ((await amountCell.textContent()) ?? '').trim();
  }

  /**
   * Assert that the transaction table has exactly the expected columns.
   */
  async expectColumnHeaders(expected: string[]): Promise<void> {
    const actual = await this.getColumnHeaders();
    expect(actual).toEqual(expected);
  }

  /** Return the current paginator range label text, e.g. "1 – 5 of 5". */
  async getPaginatorText(): Promise<string> {
    return ((await this.paginatorRangeLabel.textContent()) ?? '').trim();
  }
}
