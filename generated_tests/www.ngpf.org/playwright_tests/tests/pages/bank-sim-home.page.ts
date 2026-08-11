import { expect, type Locator, type Page } from '@playwright/test';

/**
 * The public NGPF Bank Simulator landing page shown before a simulator
 * session has been started.
 */
export class BankSimHomePage {
  readonly page: Page;
  readonly getStartedButton: Locator;

  constructor(page: Page) {
    this.page = page;
    this.getStartedButton = page.getByRole('button', { name: 'GET STARTED NOW' });
  }

  async goto(): Promise<void> {
    await this.page.goto('/bank-sim/home?returnUrl=%2F');
    await expect(this.getStartedButton).toBeVisible();
  }

  async startSimulatorSession(): Promise<void> {
    await this.getStartedButton.click();
  }
}
