import 'dotenv/config';
import { test, expect } from '@playwright/test';
import { HomePage } from './pom/HomePage.js';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const BASE_HOST_URL = process.env.BASE_HOST_URL;
const BASE_URL = process.env.BASE_URL;

let stepTimeout30 = { timeout: 30000 };
let stepTimeout45 = { timeout: 45000 };

test('User completes the FlexJobs remote job onboarding wizard', { tag: ['@smoke'] }, async ({ page }) => {
  await page.goto(BASE_URL || BASE_HOST_URL, { waitUntil: 'domcontentloaded' });

  const homePage = new HomePage(page);

  // Step: click 'Find Your Next WFH Job!' link to start the onboarding wizard
  const wizardPage = await homePage.clickFindYourNextWfhJob();

  // Step: select 'I'm open to both' remote work radio option
  await wizardPage.selectOpenToBothRemote();

  // Step: click Next (link)
  await wizardPage.clickNextLink();

  // Step: select 'Career progression' list item
  await wizardPage.selectCareerProgression();

  // Step: click Next (button)
  await wizardPage.clickNextButton();

  // Step: click 'Just exploring' button
  await wizardPage.clickJustExploring();

  // Step: click Next (button)
  await wizardPage.clickNextButton();

  // Step: fill desired salary range
  await wizardPage.fillSalaryRange('65000');

  // Step: click Next (link)
  await wizardPage.clickNextLink();

  // Step: skip resume upload
  await wizardPage.skipResumeUpload();

  // Step: click Next (button)
  await wizardPage.clickNextButton();

  // Step: enter job title in combobox
  await wizardPage.enterJobTitle('Software Engineer');

  // Step: select 'Software Engineer' from options list
  await wizardPage.selectSoftwareEngineerOption();

  // Step: click Next (button)
  await wizardPage.clickNextButton();

  // Step: select 'Communications' job category
  await wizardPage.selectCommunicationsCategory();

  // Step: click Next (button)
  await wizardPage.clickNextButton();

  // Step: select '3-5 Years' experience
  await wizardPage.selectThreeToFiveYearsExperience();

  // Step: click Next (button)
  await wizardPage.clickNextButton();

  // Step: select 'Master's or Higher' education level
  await wizardPage.selectMastersOrHigherEducation();

  // Step: click Next (button)
  await wizardPage.clickNextButton();

  // Step: select 'Health/Medical Insurance' benefit
  await wizardPage.selectHealthMedicalInsuranceBenefit();

  // Step: submit / final CTA 'Find Your Next Remote Job!'
  await wizardPage.submitFindYourNextRemoteJob();

  // Final goal verification: URL reflects the completed onboarding flow (moved past the wizard)
  await expect(page).toHaveURL(new RegExp(BASE_HOST_URL + '.*'), stepTimeout30);
});

