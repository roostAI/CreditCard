import 'dotenv/config';
import { test, expect } from '@playwright/test';
import fs from 'fs';
import path from 'path';

const BASE_HOST_URL = process.env.BASE_HOST_URL;
const BASE_URL = process.env.BASE_URL;

// Capture accessibility tree on failure
test.afterEach(async ({ page }, testInfo) => {
  if (testInfo.status !== 'passed') {
    try {
      const accessibilityTree = await page.accessibility.snapshot();
      
      const domSnapshot = await page.evaluate(() => {
        return Array.from(document.querySelectorAll('*'))
          .filter(el => {
            const rect = el.getBoundingClientRect();
            const style = window.getComputedStyle(el);
            return rect.width > 0 && rect.height > 0 && 
                   style.display !== 'none' &&
                   style.visibility !== 'hidden' &&
                   parseFloat(style.opacity) > 0.05;
          })
          .map(el => {
            const style = window.getComputedStyle(el);
            const rect = el.getBoundingClientRect();
            
            return {
              tag: el.tagName.toLowerCase(),
              id: el.id || null,
              classes: el.className || null,
              text: (el.innerText || el.textContent || '').trim().substring(0, 100),
              value: el.value || null,
              role: el.getAttribute('role') || null,
              ariaLabel: el.getAttribute('aria-label') || null,
              type: el.type || null,
              href: el.href || null,
              cursor: style.cursor,
              display: style.display,
              hasOnclick: !!el.onclick || el.hasAttribute('onclick'),
              parent: {
                tag: el.parentElement?.tagName?.toLowerCase(),
                classes: el.parentElement?.className || null
              },
              position: {
                x: Math.round(rect.x),
                y: Math.round(rect.y),
                width: Math.round(rect.width),
                height: Math.round(rect.height)
              }
            };
          });
      });
      
      const fileName = path.basename(testInfo.file)
        .replace('.auth.spec.js', '')
        .replace('.noauth.spec.js', '')
        .replace('.spec.js', '');
      const stateFile = path.join(__dirname, `../.accessibility_state_${fileName}.json`);
      fs.writeFileSync(stateFile, JSON.stringify({ 
        accessibility_tree: accessibilityTree, 
        dom_snapshot: domSnapshot, 
        element_count: domSnapshot.length, 
        url: page.url() 
      }, null, 2));
    } catch (e) {}
  }
});

test('User Administration: Validate Duplicate Username Prevention During User Creation', async ({ page }) => {
  // Step 1: Navigate to OrangeHRM dashboard (authentication via storage state)
  await page.goto(BASE_URL || BASE_HOST_URL);
  await page.waitForLoadState('networkidle');
  await page.waitForURL(`${BASE_HOST_URL}/web/index.php/dashboard/index`);

  // Step 2: Navigate to Admin section
  await page.getByRole('link', { name: 'Admin' }).click();
  await page.waitForURL(`${BASE_HOST_URL}/web/index.php/admin/viewSystemUsers`);

  // Step 3: Click Add User button to open user creation form
  await page.getByRole('button', { name: 'Add' }).click();
  await page.waitForURL(`${BASE_HOST_URL}/web/index.php/admin/saveSystemUser`);

  // Step 4: Open User Role dropdown
  await page.getByText('-- Select --').nth(0).click();

  // Step 5: Select Admin role from dropdown
  await page.getByRole('option', { name: 'Admin' }).click();

  // Step 6: Enter employee name in autocomplete field
  const employeeNameField = page.getByRole('textbox', { name: 'Type for hints...' });
  await employeeNameField.fill('Test');

  // Step 7: Select employee from autocomplete dropdown
  await page.getByRole('option', { name: 'Aparna123 4Ys 010Z' }).click({ timeout: 60000 });

  // Step 8: Open Status dropdown
  await page.getByText('-- Select --').click();

  // Step 9: Select Enabled status
  await page.getByRole('option', { name: 'Enabled' }).click();

  // Step 10: Enter duplicate username 'Admin' (existing username)
  const usernameField = page.locator('.oxd-input--active').nth(1);
  await usernameField.fill('Admin');

  // Step 11: Enter password
  const passwordField = page.locator('.oxd-input--active').nth(2);
  await passwordField.fill('Test@123');

  // Step 12: Enter confirm password
  const confirmPasswordField = page.locator('.oxd-input--active').nth(3);
  await confirmPasswordField.fill('Test@123');

  // Step 13: Click Save button to trigger validation
  await page.getByRole('button', { name: 'Save' }).click();

  // Verify that duplicate username validation error appears
  await expect(page.locator('[class*="error"]').first()).toBeVisible();
  
  // Verify page remains on Add User form (duplicate prevented)
  await expect(page).toHaveURL(`${BASE_HOST_URL}/web/index.php/admin/saveSystemUser`);
});