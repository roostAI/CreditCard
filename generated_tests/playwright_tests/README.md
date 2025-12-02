# Playwright Test Suite

## RoostGpt Generated playwright test

This project contains Playwright-based automated tests located in the `playwright_tests` directory.

## 📁 Directory Structure

```bash
 playwright_tests/
   ├── README.md
   ├── scenarios/
      ├── scenarios_summary.md
      ├── *.json (scenario files)
      ├── features/
      │   ├── *.feature (feature files)
   ├── tests/
      ├── package.json
      ├── playwright.config.js
      ├── .env.template
      ├── *.spec.js (test files)
      ├── test_summary.md
```

## 🧩 Prerequisites

Make sure you have the following installed:

- [Node.js](https://nodejs.org/) (version 18 or higher recommended)
- npm (comes with Node.js)

## 📦 Setup

1. Navigate to the Playwright tests directory:

2. Install dependencies:

   ```bash
   cd tests
   cp .env.template .env
   npm install
   ```

3. Edit the `.env` file to set any required environment variables.
## 🚀 Running Tests

To execute all Playwright tests:

```bash
npx playwright test
```

You can also run a specific test file:

```bash
npx playwright test example.spec.js
```

> Replace `example.spec.js` with the actual test file you want to run.

## 📂 Test Reports

After the tests run, Playwright will generate a report. To view the report:

```bash
npx playwright show-report
```

## ⚙️ Configuration

Test configuration is defined in `playwright.config.js`.

You can modify settings like test directory, timeout etc., in this file.

## 📘 More Info

For detailed Playwright documentation, visit: [https://playwright.dev](https://playwright.dev)
