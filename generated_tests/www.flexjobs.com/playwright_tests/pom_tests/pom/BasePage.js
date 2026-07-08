export class BasePage {
  constructor(page) {
    this.page = page;
  }

  async goto(url) {
    await this.page.goto(url, { timeout: 60000 });
    return this;
  }

  async waitForLoad() {
    await this.page.waitForLoadState('load', { timeout: 60000 });
    return this;
  }

  async getTitle() {
    return await this.page.title();
  }

  async getCurrentUrl() {
    return this.page.url();
  }
}
