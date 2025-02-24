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
  .version(packageJson.version, '-v, --version', 'output the version number')
  .usage('<command> [options]');

// Add commands
program
  .command('init')
  .description('Initialize GitFlow in the repository')
  .action(() => executeGitFlow('init'));

program
  .command('feature')
  .description('Manage feature branches')
  .argument('<action>', 'start/finish/publish/pull')
  .argument('[name]', 'feature name')
  .action((action, name) => executeGitFlow('feature', action, name));

program
  .command('release')
  .description('Manage release branches')
  .argument('<action>', 'start/finish/publish/pull')
  .argument('[version]', 'release version')
  .action((action, version) => executeGitFlow('release', action, version));

program
  .command('hotfix')
  .description('Manage hotfix branches')
  .argument('<action>', 'start/finish/publish/pull')
  .argument('[version]', 'hotfix version')
  .action((action, version) => executeGitFlow('hotfix', action, version));

program
  .command('status')
  .description('Show the status of branches')
  .action(() => executeGitFlow('status'));

program
  .command('config')
  .description('Configure Git settings')
  .option('-g, --global', 'Set global Git configuration')
  .option('-n, --name <name>', 'Set Git user name')
  .option('-e, --email <email>', 'Set Git user email')
  .option('-l, --list', 'List current Git configuration')
  .addHelpText('after', `
Examples:
  $ fm config --name "John Doe" --email "john@example.com"    # Set local config
  $ fm config -g --name "John Doe" --email "john@example.com" # Set global config
  $ fm config --list                                          # Show current config
  
This will:
  1. Set Git user name and email
  2. Configure Git settings for the project
  3. Display current configuration`)
  .action((options) => executeGitFlow('config', JSON.stringify(options)));

program
  .command('donate')
  .description('Support FlowMaster CLI development')
  .action(() => {
    console.log(chalk.cyan('\n💖 Support FlowMaster CLI Development\n'));
    console.log(chalk.white('PayPal: https://paypal.me/VOTRE_USERNAME_PAYPAL'));
    console.log(chalk.white('GitHub Sponsors: https://github.com/sponsors/ndg23\n'));
    console.log(chalk.green('Thank you for your support! 🙏\n'));
  });

// Error handling for unknown commands
program.on('command:*', function () {
  console.error(chalk.red('Invalid command: %s\nSee --help for a list of available commands.'), program.args.join(' '));
  process.exit(1);
});

// Execute GitFlow command
function executeGitFlow(command, ...args) {
  try {
    // Construct the command with proper argument handling
    const gitflowScript = join(__dirname, '../lib/gitflow.sh');
    const commandArgs = [command, ...args].filter(Boolean).join(' ');
    
    console.log(chalk.blue(`Executing GitFlow command: ${command}`));
    
    execSync(`bash "${gitflowScript}" ${commandArgs}`, {
      stdio: 'inherit',
      shell: true,
      env: {
        ...process.env,
        FORCE_COLOR: '1', // Enable colored output
      }
    });
    
    console.log(chalk.green('\nCommand completed successfully! ✨'));
  } catch (error) {
    console.error(chalk.red('\nError executing command:'));
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

// Parse command line arguments
program.parse(process.argv);

// Show help if no arguments provided
if (!process.argv.slice(2).length) {
  program.outputHelp();
} 