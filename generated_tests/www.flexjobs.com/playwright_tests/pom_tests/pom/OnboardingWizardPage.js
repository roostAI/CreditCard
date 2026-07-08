import { BasePage } from './BasePage.js';

export class OnboardingWizardPage extends BasePage {
  constructor(page) {
    super(page);

    // Primary: page.getByRole('radio', { name: 'I’m open to both' })
    // Alt1: page.getByRole('radio', { name: /I’m open to both/ })
    // Alt2: page.locator('[role="radiogroup"]').getByRole('radio', { name: /I’m open to both/ })
    // Alt3: page.locator('#what-kind-remote').getByRole('radio', { name: 'I’m open to both' })
    this.openToBothRemoteRadio = page.getByRole('radio', { name: 'I’m open to both' });

    // Primary: page.getByRole('link', { name: 'Next' })
    // Alt1: page.getByText('Next')
    // Alt2: page.locator('#wizard_footer').getByRole('link', { name: 'Next' })
    // Alt3: page.locator('a.gSEjSY.active-btn')
    this.nextLink = page.getByRole('link', { name: 'Next' });

    // Primary: page.getByRole('button', { name: 'Next' })
    // Alt1: page.getByText('Next')
    // Alt2: page.locator('#wizard_footer').getByRole('button', { name: 'Next' })
    // Alt3: page.locator('button.gSEjSY.active-btn')
    this.nextButton = page.getByRole('button', { name: 'Next' });

    // Primary: page.getByRole('listitem').filter({ hasText: 'Career progressionI want a' })
    // Alt1: page.locator('li').filter({ hasText: 'Career progressionI want a role aligned with  my background' })
    // Alt2: page.locator('#content').locator('li')
    this.careerProgressionListItem = page.getByRole('listitem').filter({ hasText: 'Career progressionI want a' });

    // Primary: page.getByRole('button', { name: 'Just exploring' })
    // Alt1: page.getByText('Just exploring')
    // Alt2: page.locator('#content').getByRole('button', { name: 'Just exploring' })
    this.justExploringButton = page.getByRole('button', { name: 'Just exploring' });

    // Primary: page.locator('#salary-range')
    // Alt1: page.locator('input[value="65000"]')
    // Alt2: page.locator('input.sc-cc0717-2')
    this.salaryRangeInput = page.locator('#salary-range');

    // Primary: page.locator('#no-resume-selected')
    // Alt1: page.getByText('No, skip the uploadI want to answer a few more questions.')
    // Alt2: page.locator('div.sc-9f26cda1-5')
    this.skipResumeUploadOption = page.locator('#no-resume-selected');

    // Primary: page.getByRole('combobox', { name: 'Add up to 5 job titles' })
    // Alt1: page.getByLabel('Add up to 5 job titles')
    // Alt2: page.getByPlaceholder('Add up to 5 job titles')
    // Alt3: page.locator('#job_title')
    this.jobTitleCombobox = page.getByRole('combobox', { name: 'Add up to 5 job titles' });

    // Primary: page.getByRole('option', { name: 'Software Engineer', exact: true })
    // Alt1: page.locator('[role="listbox"]').getByRole('option', { name: 'Software Engineer' })
    // Alt2: page.locator('li').filter({ hasText: /^Software Engineer$/ })
    this.softwareEngineerOption = page.getByRole('option', { name: 'Software Engineer', exact: true });

    // Primary: page.getByTestId('data-9')
    // Alt1: page.getByRole('button', { name: 'Communications' })
    // Alt2: page.locator('#Communications')
    this.communicationsCategoryButton = page.getByTestId('data-9');

    // Primary: page.getByRole('button', { name: '-5 Years' })
    // Alt1: page.getByRole('button', { name: /3-5 Years/ })
    // Alt2: page.getByText('3-5 Years')
    this.threeToFiveYearsButton = page.getByRole('button', { name: '-5 Years' });

    // Primary: page.getByRole('button', { name: 'Master\'s or Higher' })
    // Alt1: page.getByRole('button', { name: /Master's or Higher/ })
    // Alt2: page.getByText('Master\'s or Higher')
    this.mastersOrHigherButton = page.getByRole('button', { name: 'Master\'s or Higher' });

    // Primary: page.getByTestId('data-0')
    // Alt1: page.getByText('Health/Medical Insurance')
    // Alt2: page.locator('#Health/Medical-Insurance')
    this.healthMedicalInsuranceButton = page.getByTestId('data-0');

    // Primary: page.getByRole('button', { name: 'Find Your Next Remote Job!' })
    // Alt1: page.getByText('Find Your Next Remote Job!')
    // Alt2: page.locator('#job-benefits')
    this.findYourNextRemoteJobButton = page.getByRole('button', { name: 'Find Your Next Remote Job!' });
  }

  async selectOpenToBothRemote() {
    await this.openToBothRemoteRadio.click({ timeout: 30000 });
    return this;
  }

  async clickNextLink() {
    await this.nextLink.click({ timeout: 45000 });
    return this;
  }

  async clickNextButton() {
    await this.nextButton.click({ timeout: 45000 });
    return this;
  }

  async selectCareerProgression() {
    await this.careerProgressionListItem.click({ timeout: 30000 });
    return this;
  }

  async clickJustExploring() {
    await this.justExploringButton.click({ timeout: 30000 });
    return this;
  }

  async fillSalaryRange(value) {
    await this.salaryRangeInput.fill(value, { timeout: 30000 });
    return this;
  }

  async skipResumeUpload() {
    await this.skipResumeUploadOption.click({ timeout: 30000 });
    return this;
  }

  async enterJobTitle(value) {
    await this.jobTitleCombobox.click({ timeout: 30000 });
    await this.jobTitleCombobox.fill(value, { timeout: 30000 });
    return this;
  }

  async selectSoftwareEngineerOption() {
    await this.softwareEngineerOption.click({ timeout: 30000 });
    return this;
  }

  async selectCommunicationsCategory() {
    await this.communicationsCategoryButton.click({ timeout: 30000 });
    return this;
  }

  async selectThreeToFiveYearsExperience() {
    await this.threeToFiveYearsButton.click({ timeout: 30000 });
    return this;
  }

  async selectMastersOrHigherEducation() {
    await this.mastersOrHigherButton.click({ timeout: 30000 });
    return this;
  }

  async selectHealthMedicalInsuranceBenefit() {
    await this.healthMedicalInsuranceButton.click({ timeout: 30000 });
    return this;
  }

  async submitFindYourNextRemoteJob() {
    await this.findYourNextRemoteJobButton.click({ timeout: 45000 });
    return this;
  }
}
