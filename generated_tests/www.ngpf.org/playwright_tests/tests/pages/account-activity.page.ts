import type { Locator, Page } from '@playwright/test';

/**
 * The read-only account activity ledger (checking or saving) reached from
 * the dashboard's "VIEW ACCOUNT" action.
 */
export class AccountActivityPage {
  readonly page: Page;
  readonly heading: Locator;

  constructor(page: Page) {
    this.page = page;
    this.heading = page.getByRole('heading', { name: 'Account Activity' });
  }

  /**
   * The ledger row cell whose Balance column shows the given amount, e.g.
   * the checking account's most recent running balance.
   */
  balanceCellByText(balanceText: string): Locator {
    return this.page.getByRole('cell', { name: balanceText });
  }
}
