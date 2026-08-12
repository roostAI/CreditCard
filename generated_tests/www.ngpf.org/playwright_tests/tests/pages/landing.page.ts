import { Page, Locator } from '@playwright/test';

export class LandingPage {
  readonly page: Page;
  readonly getStartedButton: Locator;

  constructor(page: Page) {
    this.page = page;
    this.getStartedButton = page.getByRole('button', { name: 'GET STARTED NOW' });
  }

  async goto(): Promise<void> {
    await this.page.goto('/bank-sim/home?returnUrl=%2F');
  }

  async clickGetStarted(): Promise<void> {
    await this.getStartedButton.click();
  }
}
