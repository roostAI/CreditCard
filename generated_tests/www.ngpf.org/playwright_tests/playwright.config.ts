import { defineConfig, devices } from '@playwright/test';

const isSandbox = process.env.ROOST_PLAYWRIGHT_DISABLE_SANDBOX === 'true';

export default defineConfig({
  testDir: './tests',
  fullyParallel: false,
  forbidOnly: Boolean(process.env.CI),
  retries: 0,
  reporter: [['list'], ['html', { open: 'never' }]],
  use: {
    baseURL: process.env.BASE_URL ?? 'https://www.ngpf.org',
    proxy: process.env.ROOSTCODE_PLAYWRIGHT_PROXY_SERVER
      ? { server: process.env.ROOSTCODE_PLAYWRIGHT_PROXY_SERVER }
      : undefined,
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    ...(isSandbox
      ? {
          channel: 'chrome',
          launchOptions: { args: ['--no-sandbox', '--disable-setuid-sandbox'] },
        }
      : {}),
  },
  projects: [
    {
      name: 'chrome',
      use: {
        ...devices['Desktop Chrome'],
        channel: 'chrome',
        ...(isSandbox
          ? { launchOptions: { args: ['--no-sandbox', '--disable-setuid-sandbox'] } }
          : {}),
      },
    },
  ],
});
