import { Page, Locator } from '@playwright/test';

/**
 * HomePage - NGPF Bank Simulator landing page at /bank-sim/home
 * Owns selectors and actions for the pre-login landing surface.
 */
export class HomePage {
  readonly page: Page;
  readonly getStartedButton: Locator;

  constructor(page: Page) {
    this.page = page;
    this.getStartedButton = page.getByRole('button', { name: 'GET STARTED NOW' });
  }

  async goto(): Promise<void> {
    await this.page.goto('/bank-sim/home?returnUrl=%2F');
    await this.page.waitForLoadState('domcontentloaded');
    await this.getStartedButton.waitFor({ state: 'visible' });
  }

  async clickGetStarted(): Promise<void> {
    await this.getStartedButton.click();
  }
}
