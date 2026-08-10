import { type Page, type Locator } from '@playwright/test';

/**
 * HomeSplashPage: the public landing page of the NGPF Bank Simulator.
 * URL: /bank-sim/home?returnUrl=%2F
 */
export class HomeSplashPage {
  readonly page: Page;

  // Primary CTA on the splash screen
  readonly getStartedButton: Locator;

  constructor(page: Page) {
    this.page = page;
    this.getStartedButton = page.getByRole('button', { name: 'GET STARTED NOW' });
  }

  async goto(): Promise<void> {
    await this.page.goto('/bank-sim/home?returnUrl=%2F');
    await this.page.waitForLoadState('domcontentloaded');
    // Allow Angular to render the splash screen
    await this.getStartedButton.waitFor({ state: 'visible' });
  }

  /** Click GET STARTED NOW and wait for the simulator to load */
  async getStarted(): Promise<void> {
    await this.getStartedButton.click();
    // After clicking, Angular routes to /bank-sim/; wait for the URL change
    await this.page.waitForURL('**/bank-sim/**');
  }
}
