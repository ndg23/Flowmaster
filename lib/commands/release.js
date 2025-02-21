const inquirer = require('inquirer');
const git = require('../utils/git');
const logger = require('../utils/logger');
const { validateVersion } = require('../utils/validation');
const { updateChangelog } = require('../utils/changelog');

async function release(options) {
  try {
    if (options.start) {
      await startRelease(options.start);
    } else if (options.finish) {
      await finishRelease(options.finish);
    } else {
      // Interactive mode
      const { action } = await inquirer.prompt([{
        type: 'list',
        name: 'action',
        message: 'What would you like to do?',
        choices: [
          { name: 'Start a new release', value: 'start' },
          { name: 'Finish a release', value: 'finish' }
        ]
      }]);

      if (action === 'start') {
        const { version } = await inquirer.prompt([{
          type: 'input',
          name: 'version',
          message: 'Enter release version:',
          validate: validateVersion
        }]);
        await startRelease(version);
      } else {
        await finishRelease();
      }
    }
  } catch (error) {
    logger.error('Release command failed', error);
  }
}

async function startRelease(version) {
  const branchName = `release/v${version}`;
  await git.checkoutBranch('develop');
  await git.checkoutBranch(branchName, true);
  await updateChangelog(version);
  logger.success(`Started new release: ${branchName}`);
}

async function finishRelease() {
  const currentBranch = await git.getCurrentBranch();
  if (!currentBranch.startsWith('release/')) {
    throw new Error('Not on a release branch');
  }

  await git.checkoutBranch('main');
  await git.mergeBranch(currentBranch);
  await git.checkoutBranch('develop');
  await git.mergeBranch(currentBranch);
  await git.deleteBranch(currentBranch);
  logger.success(`Finished release: ${currentBranch}`);
}

module.exports = release; 