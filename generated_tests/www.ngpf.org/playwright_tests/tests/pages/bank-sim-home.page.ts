import { expect, type Locator, type Page } from '@playwright/test';

/**
 * Public landing page for the NGPF Bank Simulator.
 * URL: /bank-sim/home
 */
export class HomePage {
  readonly page: Page;
  readonly startSimulatorButton: Locator;

  constructor(page: Page) {
    this.page = page;
    this.startSimulatorButton = page.getByRole('button', { name: 'GET STARTED NOW' });
  }

  async goto(): Promise<void> {
    await this.page.goto('/bank-sim/home?returnUrl=%2F');
    await expect(this.startSimulatorButton).toBeVisible();
  }

  async startSimulator(): Promise<void> {
    await this.startSimulatorButton.click();
    await this.page.waitForURL(/\/bank-sim\/?(\?.*)?$/);
  }
}
