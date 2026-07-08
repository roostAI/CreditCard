import { BasePage } from './BasePage.js';
import { OnboardingWizardPage } from './OnboardingWizardPage.js';

export class HomePage extends BasePage {
  constructor(page) {
    super(page);

    // Primary: page.getByRole('link', { name: 'Find Your Next WFH Job!' })
    // Alt1: page.getByRole('link', { name: /Find Your Next WFH Job!/ })
    // Alt2: page.locator('[role="main"]').getByRole('link', { name: /Find Your Next WFH Job!/ })
    // Alt3: page.getByText('Find Your Next WFH Job!')
    // Alt4: page.locator('#content').getByRole('link', { name: 'Find Your Next WFH Job!' })
    this.findYourNextWfhJobLink = page.getByRole('link', { name: 'Find Your Next WFH Job!' });
  }

  /**
   * Clicks the 'Find Your Next WFH Job!' link to start the onboarding wizard.
   * Navigates to the OnboardingWizardPage.
   */
  async clickFindYourNextWfhJob() {
    await this.findYourNextWfhJobLink.click({ timeout: 45000 });
    return new OnboardingWizardPage(this.page);
  }
}
