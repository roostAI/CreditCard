import 'dotenv/config';
import { test, expect } from '@playwright/test';
import fs from 'fs';
import path from 'path';

// Capture accessibility tree on failure for intelligent iteration
test.afterEach(async ({ page }, testInfo) => {
  if (testInfo.status !== 'passed') {
    try {
      // Wait for any animations/modals to fully render
      // await page.waitForTimeout(15000);
      
      const accessibilityTree = await page.accessibility.snapshot();
      
      // UNIVERSAL SOLUTION: Capture complete DOM snapshot (like Chrome DevTools)
      // AI analyzes actual DOM instead of relying on pattern matching
      const domSnapshot = await page.evaluate(() => {
        return Array.from(document.querySelectorAll('*'))
          .filter(el => {
            // Only visible elements
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

test('Complete successful authentication workflow for OrangeHRM', async ({ page, context }) => {
  try {
    // Step 1: Navigate to OrangeHRM dashboard URL which auto-redirects to login page
    await page.goto(process.env.LOGIN_URL || process.env.BASE_URL);
    
    // Wait for redirect to login page
    await page.waitForURL(/\/auth\/login/, { timeout: 60000 });
    await page.waitForLoadState('networkidle');
    
    // Verify we're on the login page
    await expect(page).toHaveURL(/\/auth\/login/);
    
    // Step 2: Enter valid username into the Username field on login form
    // Captured selectors:
    //   1. page.getByRole("textbox", { name: "Username" }) (confidence: 90%, strategy: role, unique: true)
    const usernameInput = page.getByRole('textbox', { name: 'Username' });
    await usernameInput.waitFor({ state: 'visible', timeout: 60000 });
    await usernameInput.fill(process.env.UI_SITE_USERNAME || 'Admin');
    
    // Step 3: Enter valid password into the Password field on login form
    // Captured selectors:
    //   1. page.getByRole("textbox", { name: "Password" }) (confidence: 90%, strategy: role, unique: true)
    const passwordInput = page.getByRole('textbox', { name: 'Password' });
    await passwordInput.waitFor({ state: 'visible', timeout: 60000 });
    await passwordInput.fill(process.env.UI_SITE_PASSWORD || 'admin123');
    
    // Step 4: Click the Login button to submit authentication credentials
    // Captured selectors:
    //   1. page.getByRole("button", { name: "Login" }) (confidence: 90%, strategy: role, unique: true)
    const loginButton = page.getByRole('button', { name: 'Login' });
    await loginButton.waitFor({ state: 'visible', timeout: 60000 });
    await loginButton.click();
    
    // Step 5: Verify successful authentication and navigation to authenticated dashboard
    await page.waitForURL(/\/dashboard\/index/, { timeout: 60000 });
    await page.waitForLoadState('networkidle');
    
    // Verify we're on the dashboard page
    await expect(page).toHaveURL(/\/dashboard\/index/);
    
    // Step 6: Verify authenticated dashboard state and user session establishment
    // Wait for dashboard to fully load
    await page.waitForLoadState('domcontentloaded');
    
    // Wait for authentication to fully propagate
    await page.waitForLoadState('networkidle');
    // await page.waitForTimeout(30000);  // Allow time for auth state to be set
    
    // Save authenticated state for other tests to reuse
    await context.storageState({ path: '.auth/storage-state.json' });
    console.log('✅ Storage state saved - other tests can now skip login!');
    
  } catch (error) {
    console.error('❌ Login test failed:', error.message);
    throw error;
  }
});