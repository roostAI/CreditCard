import { Page, Locator } from '@playwright/test';

export class AccountActivityPage {
  readonly page: Page;
  readonly accountActivityHeading: Locator;
  readonly checkingAccountButton: Locator;

  constructor(page: Page) {
    this.page = page;
    this.accountActivityHeading = page.getByRole('heading', { name: 'Account Activity' });
    this.checkingAccountButton = page.getByRole('button', { name: 'Checking' });
  }
}
