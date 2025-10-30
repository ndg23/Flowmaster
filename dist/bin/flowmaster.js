#!/usr/bin/env node
"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const child_process_1 = require("child_process");
const path_1 = require("path");
const commander_1 = require("commander");
const chalk_1 = __importDefault(require("chalk"));
const package_json_1 = __importDefault(require("../package.json"));
commander_1.program
    .name('flowmaster')
    .description('A modern GitFlow CLI tool')
    .version(package_json_1.default.version, '-v, --version', 'output the version number')
    .usage('<command> [options]');
commander_1.program
    .command('init')
    .description('Initialize GitFlow in the repository')
    .action(() => executeGitFlow('init'));
commander_1.program
    .command('reorganize')
    .description('Reorganize an existing project to follow GitFlow')
    .action(() => executeGitFlow('reorganize'));
commander_1.program
    .command('feature')
    .description('Manage feature branches')
    .argument('<action>', 'start/finish/publish/pull')
    .argument('[name]', 'feature name')
    .action((action, name) => executeGitFlow('feature', action, name));
commander_1.program
    .command('release')
    .description('Manage release branches')
    .argument('<action>', 'start/finish/publish/pull')
    .argument('[version]', 'release version')
    .action((action, version) => executeGitFlow('release', action, version));
commander_1.program
    .command('hotfix')
    .description('Manage hotfix branches')
    .argument('<action>', 'start/finish/publish/pull')
    .argument('[version]', 'hotfix version')
    .action((action, version) => executeGitFlow('hotfix', action, version));
commander_1.program
    .command('status')
    .description('Show the status of branches')
    .action(() => executeGitFlow('status'));
commander_1.program
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
commander_1.program
    .command('donate')
    .description('Support FlowMaster CLI development')
    .action(() => {
    console.log(chalk_1.default.cyan('\n💖 Support FlowMaster CLI Development\n'));
    console.log(chalk_1.default.white('PayPal: https://paypal.me/VOTRE_USERNAME_PAYPAL'));
    console.log(chalk_1.default.white('GitHub Sponsors: https://github.com/sponsors/ndg23\n'));
    console.log(chalk_1.default.green('Thank you for your support! 🙏\n'));
});
commander_1.program.on('command:*', function () {
    console.error(chalk_1.default.red('Invalid command: %s\nSee --help for a list of available commands.'), commander_1.program.args.join(' '));
    process.exit(1);
});
function executeGitFlow(command, ...args) {
    try {
        const gitflowScript = (0, path_1.join)(__dirname, '../lib/gitflow.sh');
        const commandArgs = [command, ...args].filter(Boolean).join(' ');
        console.log(chalk_1.default.blue(`Executing GitFlow command: ${command}`));
        (0, child_process_1.execSync)(`bash "${gitflowScript}" ${commandArgs}`, {
            stdio: 'inherit',
            env: {
                ...process.env,
                FORCE_COLOR: '1',
            },
        });
        console.log(chalk_1.default.green('\nCommand completed successfully! ✨'));
    }
    catch (error) {
        console.error(chalk_1.default.red('\nError executing command:'));
        console.error(chalk_1.default.yellow(error.message));
        process.exit(1);
    }
}
try {
    (0, child_process_1.execSync)('git --version', { stdio: 'ignore' });
}
catch {
    console.error(chalk_1.default.red('Git is not installed. Please install Git before using this tool.'));
    process.exit(1);
}
commander_1.program.parse(process.argv);
if (!process.argv.slice(2).length) {
    commander_1.program.outputHelp();
}
//# sourceMappingURL=flowmaster.js.map