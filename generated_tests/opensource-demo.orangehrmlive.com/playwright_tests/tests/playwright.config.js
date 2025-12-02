
// @ts-check
import { defineConfig, devices } from "@playwright/test";
import * as fs from "fs";
import * as path from "path";

/**
 * @see https://playwright.dev/docs/test-configuration
 * 
 * This configuration automatically reuses authentication session with smart cookie validation:
 * 1. Checks if storage state exists AND cookies are still valid
 * 2. If cookies expired → login test runs first to regenerate fresh cookies
 * 3. If cookies valid → authenticated tests run directly (no login needed!)
 * 4. Login tests always run with fresh browser
 */

// Check if storage state file exists
const storageStatePath = path.join(__dirname, '.auth', 'storage-state.json');
const storageStateExists = fs.existsSync(storageStatePath);

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
  if (!storageStateExists) {
    console.log('⚠️  Storage state file does not exist - login required');
    return false;
  }

  try {
    const storageState = JSON.parse(fs.readFileSync(storageStatePath, 'utf-8'));
    
    // Check if cookies array exists
    if (!storageState.cookies || !Array.isArray(storageState.cookies)) {
      console.log('⚠️  No cookies found in storage state - login required');
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
      console.log('ℹ️  No authentication cookies found in storage state');
      console.log('🔄 Login test will run to establish session');
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
      // @ts-ignore - Cookie type
      console.log(`⚠️  Found ${expiredAuthCookies.length} expired/expiring auth cookie(s): ${expiredAuthCookies.map((c) => c.name).join(', ')}`);
      console.log(`   (Grace period: ${gracePeriodMinutes} minutes before expiration)`);
      console.log('🔄 Login test will run first to regenerate fresh cookies');
      return false;
    }
    
    console.log(`✅ All ${authCookies.length} authentication cookie(s) are valid - reusing existing session`);
    // @ts-ignore - Cookie type
    console.log(`   Auth cookies checked: ${authCookies.map((c) => c.name).join(', ')}`);
    return true;
  } catch (error) {
    const err = error;
    console.log(`⚠️  Error validating storage state: ${err instanceof Error ? err.message : String(err)}`);
    console.log('🔄 Login test will run first to regenerate cookies');
    return false;
  }
}

// Validate storage state (exists + cookies not expired)
const storageStateValid = isStorageStateValid();

module.exports = defineConfig({
  testDir: "./.",
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: 1,
  reporter: "html",
  
  use: {
    trace: "on-first-retry",
    launchOptions: {
      args: [
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
        ...devices["Desktop Chrome"],
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
        ...devices["Desktop Chrome"],
        // Only set storage state if file exists
        ...(storageStateExists ? { storageState: storageStatePath } : {})
      },
    },
    
    // ==========================================
    // UNAUTHENTICATED TESTS - Public pages (no login)
    // ==========================================
    {
      name: 'chromium-noauth',
      testMatch: /.*\.noauth\.spec\.js/,
      use: { 
        ...devices["Desktop Chrome"],
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
    //     ...devices["Desktop Firefox"],
    //     storageState: '.auth/storage-state.json',
    //   },
    //   dependencies: ['setup'],
    // },
    // {
    //   name: 'firefox-noauth',
    //   testMatch: /.*\.noauth\.spec\.js/,
    //   use: { ...devices["Desktop Firefox"] },
    // },
    // {
    //   name: 'firefox-login-tests',
    //   testMatch: /login.*\.spec\.js/,
    //   use: { ...devices["Desktop Firefox"] },
    // },
    
    // // ==========================================
    // // WEBKIT (Safari) BROWSER
    // // ==========================================
    // {
    //   name: 'webkit-authenticated',
    //   testMatch: /.*\.auth\.spec\.js/,
    //   use: { 
    //     ...devices["Desktop Safari"],
    //     storageState: '.auth/storage-state.json',
    //   },
    //   dependencies: ['setup'],
    // },
    // {
    //   name: 'webkit-noauth',
    //   testMatch: /.*\.noauth\.spec\.js/,
    //   use: { ...devices["Desktop Safari"] },
    // },
    // {
    //   name: 'webkit-login-tests',
    //   testMatch: /login.*\.spec\.js/,
    //   use: { ...devices["Desktop Safari"] },
    // },
  ],
});
