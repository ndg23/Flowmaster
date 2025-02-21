#!/usr/bin/env node

const program = require('commander');
const { version } = require('../package.json');
const { feature, hotfix, release } = require('../lib/commands');
const { logger } = require('../lib/utils');

program
  .version(version)
  .description('A modern GitFlow CLI tool');

program
  .command('feature')
  .description('Manage feature branches')
  .option('-s, --start <name>', 'Start a new feature')
  .option('-f, --finish <name>', 'Finish a feature')
  .action(feature);

program
  .command('release')
  .description('Manage release branches')
  .option('-s, --start <version>', 'Start a new release')
  .option('-f, --finish <version>', 'Finish a release')
  .action(release);

program
  .command('hotfix')
  .description('Manage hotfix branches')
  .option('-s, --start <version>', 'Start a new hotfix')
  .option('-f, --finish <version>', 'Finish a hotfix')
  .action(hotfix);

program.parse(process.argv); 