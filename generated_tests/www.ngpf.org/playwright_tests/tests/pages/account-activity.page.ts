import { expect, Locator, Page } from '@playwright/test';

/**
 * Read-only account activity view (https://www.ngpf.org/bank-sim/account)
 * showing the transaction history for the selected account.
 */
export class AccountActivityPage {
  readonly page: Page;
  readonly heading: Locator;
  readonly transactionsTable: Locator;
  readonly checkingToggleButton: Locator;

  constructor(page: Page) {
    this.page = page;
    this.heading = this.page.getByRole('heading', { name: 'Account Activity' });
    this.transactionsTable = this.page.getByRole('table');
    this.checkingToggleButton = this.page.getByRole('button', { name: 'Checking' });
  }

  async waitForReady(): Promise<void> {
    await this.heading.waitFor({ state: 'visible' });
  }

  async expectCheckingAccountSelected(): Promise<void> {
    await expect(this.checkingToggleButton).toHaveClass(/active/);
  }

  async expectTransactionsVisible(): Promise<void> {
    await expect(this.transactionsTable).toBeVisible();
    const rowCount = await this.transactionsTable.getByRole('row').count();
    expect(rowCount).toBeGreaterThan(1);
  }
}
