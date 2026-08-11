import { Locator, Page, expect } from '@playwright/test';

export class HomePage {
  readonly page: Page;
  readonly getStartedButton: Locator;
  readonly welcomeModalHeading: Locator;
  readonly welcomeModalOkButton: Locator;
  readonly viewAccountButton: Locator;

  constructor(page: Page) {
    this.page = page;
    this.getStartedButton = page.getByRole('button', { name: 'GET STARTED NOW' });
    this.welcomeModalHeading = page.getByRole('heading', { name: 'Welcome to the NGPF Bank Simulator' });
    this.welcomeModalOkButton = page.getByRole('button', { name: 'Ok' });
    this.viewAccountButton = page.getByRole('button', { name: 'VIEW ACCOUNT' }).first();
  }

  async goto() {
    await this.page.goto('/bank-sim/home?returnUrl=%2F');
  }

  async startSimulator() {
    await expect(this.getStartedButton).toBeVisible();
    await this.getStartedButton.click();
  }

  async dismissWelcomeModal() {
    await expect(this.welcomeModalHeading).toBeVisible();
    await this.welcomeModalOkButton.click();
  }

  async openCheckingAccount() {
    await expect(this.viewAccountButton).toBeVisible();
    await this.viewAccountButton.click();
  }
}
