import type { Locator, Page } from '@playwright/test';

/**
 * The public NGPF Bank Simulator welcome page. It offers a single entry
 * point ("GET STARTED NOW") that begins a new simulator session.
 */
export class HomePage {
  readonly page: Page;
  readonly getStartedButton: Locator;

  constructor(page: Page) {
    this.page = page;
    this.getStartedButton = page.getByRole('button', { name: 'GET STARTED NOW' });
  }

  /** Open the Bank Simulator welcome page. */
  async goto(): Promise<void> {
    await this.page.goto('/bank-sim/home?returnUrl=%2F');
  }

  /** Start a new simulator session from the welcome page. */
  async getStarted(): Promise<void> {
    await this.getStartedButton.click();
    await this.page.waitForURL('**/bank-sim/');
  }
}
