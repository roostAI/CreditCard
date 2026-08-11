import { defineConfig, devices } from '@playwright/test';

const baseURL = process.env.BASE_URL || 'https://www.ngpf.org';

export default defineConfig({
  testDir: './tests',
  timeout: 30_000,
  expect: {
    timeout: 10_000,
  },
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  workers: 1,
  reporter: [
    ['list'],
    ['json', { outputFile: process.env.PLAYWRIGHT_JSON_OUTPUT_FILE || 'test-results/results.json' }],
  ],
  use: {
    baseURL,
    ...(process.env.ROOSTCODE_PLAYWRIGHT_PROXY_SERVER
      ? { proxy: { server: process.env.ROOSTCODE_PLAYWRIGHT_PROXY_SERVER } }
      : {}),
    ...(process.env.ROOST_PLAYWRIGHT_DISABLE_SANDBOX === 'true' &&
    process.env.PLAYWRIGHT_CHROMIUM_SANDBOX
      ? {
          launchOptions: {
            args: ['--no-sandbox', '--disable-setuid-sandbox'],
          },
        }
      : {}),
    channel: 'chrome',
    headless: true,
    screenshot: 'only-on-failure',
    trace: 'retain-on-failure',
    video: 'off',
  },
  outputDir: 'test-results/',
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
});
