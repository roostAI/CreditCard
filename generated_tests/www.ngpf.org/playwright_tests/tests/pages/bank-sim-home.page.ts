import { type Page, type Locator } from '@playwright/test';

/**
 * BankSimHomePage – models the NGPF Bank Simulator welcome/home page.
 * URL: https://www.ngpf.org/bank-sim/home?returnUrl=%2F
 */
export class BankSimHomePage {
  readonly page: Page;

  // SEL001 – GET STARTED NOW button on the home page
  readonly getStartedButton: Locator;

  constructor(page: Page) {
    this.page = page;
    this.getStartedButton = page.getByRole('button', { name: 'GET STARTED NOW' });
  }

  /**
   * Navigate to the bank simulator home page and wait for it to be ready.
   * The BASE_URL env var (or playwright.config baseURL) points to the origin;
   * this method appends the path.
   */
  async goto(): Promise<void> {
    await this.page.goto('/bank-sim/home?returnUrl=%2F');
    await this.getStartedButton.waitFor({ state: 'visible' });
  }

  /** Click GET STARTED NOW and wait for navigation to the dashboard. */
  async clickGetStarted(): Promise<void> {
    await this.getStartedButton.click();
    await this.page.waitForURL('**/bank-sim/');
  }
}
