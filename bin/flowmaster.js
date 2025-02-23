#!/usr/bin/env node

const { execSync } = require('child_process');
const { join } = require('path');
const { program } = require('commander');

program
  .version('1.0.0')
  .option('--version', 'output the version number');

program.parse(process.argv);

if (program.version) {
  console.log(program.version());
}

// Exécuter le script shell avec les arguments
try {
  execSync(`bash ${join(__dirname, '../lib/gitflow.sh')} "$@"`, {
    stdio: 'inherit',
    shell: true
  });
} catch (error) {
  process.exit(1);
} 