import { type Page, type Locator } from '@playwright/test';

/**
 * AccountActivityPage: the checking or saving account activity table.
 * URL: /bank-sim/account?type=checking  (or ?type=saving)
 *
 * Live-grounded observations (2026-08-10):
 *  - H2: "Account Activity"
 *  - Table header cells: ["Id","Date","Description","Amount","Balance","Actions"]
 *  - Pagination text: "1 – 5 of 5"
 *  - Account toggle buttons: "Checking", "Saving"
 *  - tr[mat-row] for data rows (5 present in the demo dataset)
 */
export class AccountActivityPage {
  readonly page: Page;

  /** Page heading */
  readonly heading: Locator;

  /** Table header cells */
  readonly tableHeaderCells: Locator;

  /** All data rows */
  readonly tableRows: Locator;

  /** Pagination range label */
  readonly paginationLabel: Locator;

  /** SELECT ACCOUNT label */
  readonly selectAccountLabel: Locator;

  /** Checking account toggle button */
  readonly checkingToggleButton: Locator;

  constructor(page: Page) {
    this.page = page;

    this.heading = page.getByRole('heading', { name: 'Account Activity' });

    this.tableHeaderCells = page.locator('th[mat-header-cell]');

    this.tableRows = page.locator('tr[mat-row]');

    this.paginationLabel = page.locator('.mat-paginator-range-label');

    this.selectAccountLabel = page.getByText('SELECT ACCOUNT');

    this.checkingToggleButton = page.getByRole('button', { name: 'Checking' });
  }

  /** Wait until the account activity table is fully visible */
  async waitForReady(): Promise<void> {
    await this.heading.waitFor({ state: 'visible' });
    await this.tableRows.first().waitFor({ state: 'visible' });
  }

  /** Return the text content of the pagination label, e.g. "1 – 5 of 5" */
  async getPaginationText(): Promise<string> {
    return (await this.paginationLabel.textContent() ?? '').trim();
  }

  /** Return the text of all table header cells */
  async getColumnHeaders(): Promise<string[]> {
    return this.tableHeaderCells.allInnerTexts();
  }

  /** Return the number of visible data rows */
  async getRowCount(): Promise<number> {
    return this.tableRows.count();
  }
}
