import { expect, type Locator, type Page } from '@playwright/test';

/**
 * The account activity page reached from the dashboard, listing the
 * transaction history table for the selected account (checking or saving).
 */
export class AccountActivityPage {
  readonly page: Page;
  readonly heading: Locator;
  readonly checkingToggleButton: Locator;
  readonly transactionsTable: Locator;
  readonly accountOpeningRowCell: Locator;

  constructor(page: Page) {
    this.page = page;
    this.heading = page.getByRole('heading', { name: 'Account Activity' });
    this.checkingToggleButton = page.getByRole('button', { name: 'Checking' });
    this.transactionsTable = page.getByRole('table');
    this.accountOpeningRowCell = page.getByRole('cell', { name: 'Account Opening' });
  }

  async expectCheckingAccountActivityVisible(): Promise<void> {
    await expect(this.heading).toBeVisible();
    await expect(this.checkingToggleButton).toHaveClass(/active/);
    await expect(this.transactionsTable).toBeVisible();
    await expect(this.accountOpeningRowCell).toBeVisible();
  }
}
