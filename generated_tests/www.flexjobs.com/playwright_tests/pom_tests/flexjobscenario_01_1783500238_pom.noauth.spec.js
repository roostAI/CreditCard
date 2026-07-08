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

test('Flexjobscenario - complete onboarding wizard to find remote job', { tag: ['@smoke'] }, async ({ page }) => {
  await page.goto(BASE_URL || BASE_HOST_URL, { waitUntil: 'domcontentloaded' });

  const homePage = new HomePage(page);

  // Step: click Find Your Next WFH Job! link to start onboarding wizard
  const wizard = await homePage.clickFindYourNextWfhJob();

  // Step: select I'm open to both remote work preference
  await wizard.selectOpenToBothRemote();

  // Step: click Next (link variant)
  await wizard.clickNextLink();

  // Step: select Career progression reason
  await wizard.selectCareerProgression();

  // Step: click Next (button variant)
  await wizard.clickNextButton();

  // Step: select Just exploring
  await wizard.clickJustExploring();

  // Step: click Next (button variant)
  await wizard.clickNextButton();

  // Step: fill desired salary range
  await wizard.fillSalaryRange('65000');

  // Step: click Next (link variant)
  await wizard.clickNextLink();

  // Step: click Next (button variant)
  await wizard.clickNextButton();

  // Step: skip resume upload
  await wizard.skipResumeUpload();

  // Step: click Next (button variant)
  await wizard.clickNextButton();

  // Step: enter job title
  await wizard.enterJobTitle('Software Engineer');

  // Step: select Software Engineer option from dropdown
  await wizard.selectSoftwareEngineerOption();

  // Step: click Next (button variant)
  await wizard.clickNextButton();

  // Step: select Communications job category
  await wizard.selectCommunicationsCategory();

  // Step: click Next (button variant)
  await wizard.clickNextButton();

  // Step: select 3-5 Years experience
  await wizard.selectThreeToFiveYearsExperience();

  // Step: click Next (button variant)
  await wizard.clickNextButton();

  // Step: select Master's or Higher education level
  await wizard.selectMastersOrHigherEducation();

  // Step: click Next (button variant)
  await wizard.clickNextButton();

  // Step: select Health/Medical Insurance benefit
  await wizard.selectHealthMedicalInsuranceBenefit();

  // Step: submit final Find Your Next Remote Job! button (goal completion)
  await wizard.submitFindYourNextRemoteJob();

  // Final goal verification: onboarding wizard completed and remote job search submitted
  await expect(page).toHaveURL(new RegExp(BASE_HOST_URL + '.*'));
});

