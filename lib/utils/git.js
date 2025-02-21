const simpleGit = require('simple-git');
const { logger } = require('./logger');

class Git {
  constructor() {
    this.git = simpleGit();
  }

  async getCurrentBranch() {
    try {
      const result = await this.git.revparse(['--abbrev-ref', 'HEAD']);
      return result.trim();
    } catch (error) {
      logger.error('Failed to get current branch', error);
      throw error;
    }
  }

  async checkoutBranch(branch, create = false) {
    try {
      if (create) {
        await this.git.checkoutLocalBranch(branch);
      } else {
        await this.git.checkout(branch);
      }
    } catch (error) {
      logger.error(`Failed to checkout branch ${branch}`, error);
      throw error;
    }
  }

  async hasChanges() {
    const status = await this.git.status();
    return !status.isClean();
  }
}

module.exports = new Git(); 