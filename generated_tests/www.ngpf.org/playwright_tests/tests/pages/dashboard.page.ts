import { Page, Locator } from '@playwright/test';

export class DashboardPage {
  readonly page: Page;
  readonly welcomeDialog: Locator;
  readonly dismissWelcomeButton: Locator;
  readonly checkingViewAccountButton: Locator;

  constructor(page: Page) {
    this.page = page;
    this.welcomeDialog = page.getByRole('heading', { name: 'Welcome to the NGPF Bank Simulator' });
    this.dismissWelcomeButton = page.getByRole('button', { name: 'Ok' });
    this.checkingViewAccountButton = page.getByRole('button', { name: 'VIEW ACCOUNT' }).first();
  }

  async dismissWelcomeDialogIfVisible(): Promise<void> {
    await this.dismissWelcomeButton.waitFor({ state: 'visible' });
    await this.dismissWelcomeButton.click();
  }

  async navigateToCheckingAccount(): Promise<void> {
    await this.checkingViewAccountButton.click();
  }
}
