const inquirer = require('inquirer');
const git = require('../utils/git');
const logger = require('../utils/logger');
const { validateBranchName } = require('../utils/validation');

async function feature(options) {
  try {
    if (options.start) {
      await startFeature(options.start);
    } else if (options.finish) {
      await finishFeature(options.finish);
    } else {
      // Interactive mode
      const { action } = await inquirer.prompt([{
        type: 'list',
        name: 'action',
        message: 'What would you like to do?',
        choices: [
          { name: 'Start a new feature', value: 'start' },
          { name: 'Finish a feature', value: 'finish' }
        ]
      }]);

      if (action === 'start') {
        const { name } = await inquirer.prompt([{
          type: 'input',
          name: 'name',
          message: 'Enter feature name:',
          validate: validateBranchName
        }]);
        await startFeature(name);
      } else {
        await finishFeature();
      }
    }
  } catch (error) {
    logger.error('Feature command failed', error);
  }
}

async function startFeature(name) {
  const branchName = `feature/${name}`;
  await git.checkoutBranch('develop');
  await git.checkoutBranch(branchName, true);
  logger.success(`Started new feature: ${branchName}`);
}

async function finishFeature(name) {
  const currentBranch = await git.getCurrentBranch();
  if (!currentBranch.startsWith('feature/')) {
    throw new Error('Not on a feature branch');
  }
  
  await git.checkoutBranch('develop');
  await git.mergeBranch(currentBranch);
  await git.deleteBranch(currentBranch);
  logger.success(`Finished feature: ${currentBranch}`);
}

module.exports = feature; 