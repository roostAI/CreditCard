import { type Locator, type Page } from '@playwright/test';

export class BankSimulatorPage {
  readonly page: Page;
  readonly getStartedButton: Locator;
  readonly welcomeOkButton: Locator;
  readonly viewCheckingAccountButton: Locator;
  readonly accountActivityHeading: Locator;
  readonly checkingTabButton: Locator;
  readonly savingsTabButton: Locator;

  constructor(page: Page) {
    this.page = page;
    this.getStartedButton = page.getByRole('button', { name: 'GET STARTED NOW' });
    this.welcomeOkButton = page.getByRole('button', { name: 'Ok' });
    this.viewCheckingAccountButton = page.getByRole('button', { name: 'VIEW ACCOUNT' }).first();
    this.accountActivityHeading = page.getByRole('heading', { name: 'Account Activity' });
    this.checkingTabButton = page.getByRole('button', { name: 'Checking' });
    this.savingsTabButton = page.getByRole('button', { name: 'Saving' });
  }

  async goto(): Promise<void> {
    await this.page.goto('/bank-sim/home?returnUrl=%2F');
  }

  async startSimulator(): Promise<void> {
    await this.getStartedButton.click();
  }

  async dismissWelcomeDialog(): Promise<void> {
    await this.welcomeOkButton.waitFor({ state: 'visible' });
    await this.welcomeOkButton.click();
  }

  async viewCheckingAccount(): Promise<void> {
    await this.viewCheckingAccountButton.click();
  }

  async selectSavingsAccount(): Promise<void> {
    await this.savingsTabButton.click();
  }

  async selectCheckingAccount(): Promise<void> {
    await this.checkingTabButton.click();
  }
}
