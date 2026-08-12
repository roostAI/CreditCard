import { Page, Locator } from '@playwright/test';

export class CheckingAccountActivityPage {
  readonly page: Page;
  readonly accountHeading: Locator;

  constructor(page: Page) {
    this.page = page;
    this.accountHeading = page.getByRole('heading', { name: 'Account Activity' });
  }

  async isLoaded() {
    await this.accountHeading.waitFor({ state: 'visible' });
  }
}
