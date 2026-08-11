import { Locator, Page, expect } from '@playwright/test';

export class AccountActivityPage {
  readonly page: Page;
  readonly accountActivityHeading: Locator;
  readonly checkingAccountButton: Locator;
  readonly savingAccountButton: Locator;
  readonly activityTable: Locator;

  constructor(page: Page) {
    this.page = page;
    this.accountActivityHeading = page.getByRole('heading', { name: 'Account Activity' });
    this.checkingAccountButton = page.getByRole('button', { name: 'Checking' });
    this.savingAccountButton = page.getByRole('button', { name: 'Saving' });
    this.activityTable = page.getByRole('table');
  }

  async expectLoaded() {
    await expect(this.accountActivityHeading).toBeVisible();
    await expect(this.activityTable).toBeVisible();
  }

  async selectCheckingAccount() {
    await expect(this.checkingAccountButton).toBeVisible();
    await this.checkingAccountButton.click();
  }

  async selectSavingAccount() {
    await expect(this.savingAccountButton).toBeVisible();
    await this.savingAccountButton.click();
  }
}
