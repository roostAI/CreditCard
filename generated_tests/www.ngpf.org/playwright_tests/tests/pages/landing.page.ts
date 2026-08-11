import { Locator, Page } from '@playwright/test';

/**
 * Public NGPF Bank Simulator landing page. Starts a new (or resumed)
 * simulator session, which redirects the browser to the dashboard.
 */
export class LandingPage {
  readonly page: Page;
  readonly getStartedButton: Locator;

  constructor(page: Page) {
    this.page = page;
    this.getStartedButton = this.page.getByRole('button', { name: 'GET STARTED NOW' });
  }

  async goto(): Promise<void> {
    await this.page.goto('/bank-sim/home?returnUrl=%2F');
    await this.getStartedButton.waitFor({ state: 'visible' });
  }

  async startSession(): Promise<void> {
    await this.getStartedButton.click();
    await this.page.waitForURL('**/bank-sim/');
  }
}
