import { type Page, type Locator } from '@playwright/test';

/**
 * DashboardPage: the main simulator dashboard.
 * URL: /bank-sim/ (after GET STARTED NOW)
 *
 * Live-grounded observations (2026-08-10):
 *  - mat-card titles: ["CHECKING ACCOUNT ACTIVITY","SAVING ACCOUNT ACTIVITY","UPCOMING TRANSFERS","UPCOMING BILLS"]
 *  - Buttons: ["Account","VIEW ACCOUNT","VIEW ACCOUNT","VIEW TRANSFERS","VIEW BILLS"]
 *  - Welcome dialog "Ok" button appears on first load
 */
export class DashboardPage {
  readonly page: Page;

  /** Dialog that appears on first load – must be dismissed before interacting */
  readonly welcomeDialogOkButton: Locator;

  /** CHECKING ACCOUNT ACTIVITY card */
  readonly checkingAccountCard: Locator;

  /** Available balance text inside the checking card */
  readonly checkingAvailableBalance: Locator;

  /** VIEW ACCOUNT button for the checking card (first of two VIEW ACCOUNT buttons) */
  readonly checkingViewAccountButton: Locator;

  constructor(page: Page) {
    this.page = page;

    this.welcomeDialogOkButton = page.getByRole('button', { name: 'Ok' });

    // Use mat-card with class 'home-cards' scoped to the checking title.
    // Live observation: outer 'mat-card.card' wraps 4 child cards; the individual
    // account card has class 'home-cards' and contains exactly one AVAILABLE BALANCE.
    this.checkingAccountCard = page
      .locator('mat-card.home-cards')
      .filter({ has: page.locator('mat-card-title', { hasText: 'CHECKING ACCOUNT ACTIVITY' }) });

    this.checkingAvailableBalance = this.checkingAccountCard.locator('.balance-text', { hasText: 'AVAILABLE BALANCE' });

    // There are two VIEW ACCOUNT buttons (checking and saving); the first is checking.
    this.checkingViewAccountButton = page.getByRole('button', { name: 'VIEW ACCOUNT' }).first();
  }

  /** Dismiss the welcome dialog if it is visible */
  async dismissWelcomeDialog(): Promise<void> {
    if (await this.welcomeDialogOkButton.isVisible()) {
      await this.welcomeDialogOkButton.click();
    }
  }

  /** Assert the dashboard is fully rendered */
  async waitForReady(): Promise<void> {
    await this.checkingAccountCard.waitFor({ state: 'visible' });
  }

  /** Navigate to Checking Account Activity by clicking the first VIEW ACCOUNT button */
  async openCheckingAccountActivity(): Promise<void> {
    await this.checkingViewAccountButton.click();
    await this.page.waitForURL('**/account?type=checking');
  }
}
