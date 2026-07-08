
import { defineConfig } from "@playwright/test";

import * as fs from "fs";
import * as path from "path";
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/**
 * @see https://playwright.dev/docs/test-configuration
 *
 * This configuration automatically reuses authentication session with smart cookie validation:
 * 1. Checks if storage state exists AND cookies are still valid
 * 2. If cookies expired → login test runs first to regenerate fresh cookies
 * 3. If cookies valid → authenticated tests run directly (no login needed!)
 * 4. Login tests always run with fresh browser
 */

// Storage state file path
const storageStatePath = path.join(__dirname, '.auth', 'storage-state.json');

/**
 * Validates if authentication cookies in storage state are still valid
 *
 * Smart validation that only checks auth-critical cookies (not analytics/tracking):
 * - Configurable via AUTH_COOKIE_NAMES env var (comma-separated patterns)
 * - Default patterns: session, auth, token, sid, JSESSIONID, etc.
 * - Grace period: Triggers re-login N minutes before expiration (COOKIE_GRACE_PERIOD_MINUTES)
 * - Ignores non-auth cookies to prevent unnecessary re-logins
 *
 * @returns {boolean} true if auth cookies are valid, false if expired/missing
 */
function isStorageStateValid() {
  if (!fs.existsSync(storageStatePath)) {
    return false;
  }

  try {
    const rawData = fs.readFileSync(storageStatePath, 'utf-8');
    if (!rawData.trim()) throw new Error('File is empty');
    
    const storageState = JSON.parse(rawData);

    // Check if cookies array exists
    if (!storageState.cookies || !Array.isArray(storageState.cookies)) {
      return false;
    }

    // Configure authentication cookie patterns
    // Override via AUTH_COOKIE_NAMES environment variable (comma-separated)
    const authCookiePatterns = (process.env.AUTH_COOKIE_NAMES ||
      'session,auth,token,sid,oauth,JSESSIONID,connect.sid,access_token,refresh_token,jwt,bearer,_session').split(',');

    // Configure grace period (minutes before expiration to trigger re-login)
    const gracePeriodMinutes = parseInt(process.env.COOKIE_GRACE_PERIOD_MINUTES || '1');
    const gracePeriodSeconds = gracePeriodMinutes * 60;
    const now = Date.now() / 1000; // Convert to seconds

    // Filter to only auth-critical cookies
    const authCookies = storageState.cookies.filter((cookie) =>
      authCookiePatterns.some((pattern) =>
        cookie.name.toLowerCase().includes(pattern.toLowerCase())
      )
    );

    if (authCookies.length === 0) {
      return false;
    }

    // Check auth cookies for expiration (with grace period)
    // @ts-ignore - Cookie type from storage state
    const expiredAuthCookies = authCookies.filter((cookie) =>
      cookie.expires &&
      cookie.expires !== -1 &&
      cookie.expires < (now + gracePeriodSeconds)
    );

    if (expiredAuthCookies.length > 0) {
      return false;
    }

    return true;
  } catch (error) {
    // If the file is corrupted or empty, delete it so Playwright treats it as missing
    try {
      if (fs.existsSync(storageStatePath)) {
        fs.unlinkSync(storageStatePath);
      }
    } catch (e) {}
    return false;
  }
}

// Validate storage state (exists + cookies not expired)
const storageStateValid = isStorageStateValid();

export default defineConfig({
  testDir: ".",
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: 1,
  reporter: "html",
  globalTimeout: 600000,
  timeout: 120000,

  use: {
    locale: "en-US",
    trace: "on-first-retry",
    screenshot: "only-on-failure",
    viewport: null, // Use actual browser window size
    // Browser channel (e.g. "chrome", "msedge") — injected from BROWSER_USE_CHANNEL; empty = bundled Chromium
    
    launchOptions: {
      // Custom browser binary — injected from BROWSER_USE_EXECUTABLE_PATH; empty = bundled Chromium
      
      args: [
        "--start-maximized",
        "--disable-blink-features=AutomationControlled",
        "--disable-dev-shm-usage",
        "--no-sandbox",
      ],
    },
    // Do NOT set storageState here globally
    // Each project will specify its own storage state needs
  },

  projects: [
    // ==========================================
    // LOGIN TEST - Always runs with fresh browser
    // ==========================================
    {
      name: 'login-test',
      
      testMatch: /login_analysis.*\.spec\.js/,
      use: {
        browserName: 'chromium',
        // No storageState - fresh browser for login
      },
    },

    // ==========================================
    // AUTHENTICATED TESTS - Need login (use storage state)
    // ==========================================
    {
      name: 'chromium-authenticated',
      
      testMatch: /.*\.auth\.spec\.js/,
      // Smart dependency: Only depend on login if storage state is invalid
      dependencies: storageStateValid ? [] : ['login-test'],
      use: {
        browserName: 'chromium',
        // Always set storage state for authenticated tests
        storageState: storageStatePath
      },
    },

    // ==========================================
    // UNAUTHENTICATED TESTS - Public pages (no login)
    // ==========================================
    {
      name: 'chromium-noauth',
      
      testMatch: /.*\.noauth\.spec\.js/,
      use: {
        browserName: 'chromium',
        // No storageState - fresh browser for public pages
      },
    },

    // // ==========================================
    // // FIREFOX BROWSER
    // // ==========================================
    // {
    //   name: 'firefox-authenticated',
    //   testMatch: /.*\.auth\.spec\.js/,
    //   use: {
    //     browserName: 'firefox',
    //     viewport: null,
    //     storageState: '.auth/storage-state.json',
    //   },
    //   dependencies: ['setup'],
    // },
    // {
    //   name: 'firefox-noauth',
    //   testMatch: /.*\.noauth\.spec\.js/,
    //   use: { browserName: 'firefox', viewport: null },
    // },
    // {
    //   name: 'firefox-login-tests',
    //   testMatch: /login.*\.spec\.js/,
    //   use: { browserName: 'firefox', viewport: null },
    // },

    // // ==========================================
    // // WEBKIT (Safari) BROWSER
    // // ==========================================
    // {
    //   name: 'webkit-authenticated',
    //   testMatch: /.*\.auth\.spec\.js/,
    //   use: {
    //     browserName: 'webkit',
    //     viewport: null,
    //     storageState: '.auth/storage-state.json',
    //   },
    //   dependencies: ['setup'],
    // },
    // {
    //   name: 'webkit-noauth',
    //   testMatch: /.*\.noauth\.spec\.js/,
    //   use: { browserName: 'webkit', viewport: null },
    // },
    // {
    //   name: 'webkit-login-tests',
    //   testMatch: /login.*\.spec\.js/,
    //   use: { browserName: 'webkit', viewport: null },
    // },
  ],
});
