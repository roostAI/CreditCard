import { type Page, type Locator, expect } from '@playwright/test';

/**
 * BankSimAccountActivityPage – models the NGPF Bank Simulator account activity view.
 * URL: https://www.ngpf.org/bank-sim/account?type=checking
 */
export class BankSimAccountActivityPage {
  readonly page: Page;

  // SEL006 – Account Activity heading
  readonly accountActivityHeading: Locator;

  // SEL007 – Checking tab button
  readonly checkingTabButton: Locator;

  // SEL008 – Id column header in the transaction table
  readonly tableIdColumnHeader: Locator;

  // SEL009 – Pagination label (e.g. "1 – 5 of 5")
  readonly paginationLabel: Locator;

  constructor(page: Page) {
    this.page = page;
    this.accountActivityHeading = page.getByRole('heading', { name: 'Account Activity' });
    this.checkingTabButton = page.getByRole('button', { name: 'Checking' });
    this.tableIdColumnHeader = page.getByRole('columnheader', { name: 'Id' });
    this.paginationLabel = page.getByText(/\d+\s*–\s*\d+\s+of\s+\d+/);
  }

  /**
   * Assert that the account activity transaction table is visible, has the
   * expected column headers, and displays at least one transaction row.
   * Implements SEL006, SEL007, SEL008, SEL009.
   */
  async assertActivityTableVisible(): Promise<void> {
    await this.accountActivityHeading.waitFor({ state: 'visible' });
    await expect(this.accountActivityHeading).toBeVisible();
    await expect(this.tableIdColumnHeader).toBeVisible();
    await expect(this.page.getByRole('columnheader', { name: 'Date' })).toBeVisible();
    await expect(this.page.getByRole('columnheader', { name: 'Description' })).toBeVisible();
    await expect(this.page.getByRole('columnheader', { name: 'Amount' })).toBeVisible();
    await expect(this.page.getByRole('columnheader', { name: 'Balance' })).toBeVisible();
    await expect(this.page.getByRole('row').nth(1)).toBeVisible();
    await expect(this.paginationLabel).toBeVisible();
  }

  /**
   * Assert that the Checking tab is visible (confirming the checking account
   * is displayed). Does not click; purely a read-only assertion.
   * Implements SEL007.
   */
  async assertCheckingTabActive(): Promise<void> {
    await expect(this.checkingTabButton).toBeVisible();
  }
}
