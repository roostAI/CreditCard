import { defineConfig, devices } from '@playwright/test';

const BASE_URL = process.env.BASE_URL || 'https://www.ngpf.org';

export default defineConfig({
  testDir: './tests',
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  workers: 1,
  reporter: [['list'], ['json', { outputFile: 'test-results/results.json' }]],
  use: {
    baseURL: BASE_URL,
    trace: 'on-first-retry',
    ...(process.env.ROOSTCODE_PLAYWRIGHT_PROXY_SERVER
      ? { proxy: { server: process.env.ROOSTCODE_PLAYWRIGHT_PROXY_SERVER } }
      : {}),
  },
  projects: [
    {
      name: 'chromium',
      use: {
        ...devices['Desktop Chrome'],
        // Use the system Chrome installation when available
        channel: 'chrome',
        launchOptions: {
          args: process.env.ROOST_PLAYWRIGHT_DISABLE_SANDBOX === 'true'
            ? ['--no-sandbox', '--disable-setuid-sandbox']
            : [],
        },
      },
    },
  ],
});
