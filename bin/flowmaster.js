#!/usr/bin/env node

const { execSync } = require('child_process');
const { join } = require('path');
const { program } = require('commander');
const chalk = require('chalk');
const packageJson = require('../package.json');

// Configure Commander
program
  .name('flowmaster')
  .description('A modern GitFlow CLI tool')
  .version(packageJson.version, '-v, --version', 'output the version number');

// Execute GitFlow menu
function executeGitFlowMenu() {
  try {
    const gitflowScript = join(__dirname, '../lib/gitflow.sh');
    
    execSync(`bash "${gitflowScript}"`, {
      stdio: 'inherit',
      shell: true,
      env: {
        ...process.env,
        FORCE_COLOR: '1', // Enable colored output
      }
    });
  } catch (error) {
    console.error(chalk.red('\nError executing menu:'));
    console.error(chalk.yellow(error.message));
    process.exit(1);
  }
}

// Check if Git is installed
try {
  execSync('git --version', { stdio: 'ignore' });
} catch (error) {
  console.error(chalk.red('Git is not installed. Please install Git before using this tool.'));
  process.exit(1);
}

// Execute menu directly
executeGitFlowMenu(); 