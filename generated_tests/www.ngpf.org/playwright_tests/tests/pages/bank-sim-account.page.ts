import { expect, type Locator, type Page } from '@playwright/test';

/**
 * Read-only account activity screen.
 * URL: /bank-sim/account?type=checking (or ?type=saving)
 */
export class AccountActivityPage {
  readonly page: Page;
  readonly heading: Locator;
  readonly checkingToggleButton: Locator;
  readonly descriptionColumnHeader: Locator;

  constructor(page: Page) {
    this.page = page;
    this.heading = page.getByRole('heading', { name: 'Account Activity' });
    this.checkingToggleButton = page.getByRole('button', { name: 'Checking' });
    this.descriptionColumnHeader = page.getByRole('columnheader', { name: 'Description' });
  }

  async expectCheckingActivityIsDisplayed(): Promise<void> {
    await expect(this.page).toHaveURL(/\/bank-sim\/account\?type=checking/);
    await expect(this.heading).toBeVisible();
    await expect(this.checkingToggleButton).toBeVisible();
    await expect(this.descriptionColumnHeader).toBeVisible();
  }
}
