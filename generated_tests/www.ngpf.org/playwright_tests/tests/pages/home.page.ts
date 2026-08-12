import { Page, Locator } from '@playwright/test';

export class HomePage {
  readonly page: Page;
  readonly getStartedButton: Locator;
  readonly welcomeOkButton: Locator;
  readonly viewCheckingAccountButton: Locator;

  constructor(page: Page) {
    this.page = page;
    this.getStartedButton = page.getByRole('button', { name: 'GET STARTED NOW' });
    this.welcomeOkButton = page.getByRole('button', { name: 'Ok' });
    this.viewCheckingAccountButton = page.getByRole('button', { name: 'VIEW ACCOUNT' }).first();
  }

  async goto() {
    await this.page.goto('https://www.ngpf.org/bank-sim/home?returnUrl=%2F');
  }

  async getStarted() {
    await this.getStartedButton.click();
  }

  async dismissWelcomeDialog() {
    await this.welcomeOkButton.click();
  }

  async viewCheckingAccount() {
    await this.viewCheckingAccountButton.click();
  }
}
