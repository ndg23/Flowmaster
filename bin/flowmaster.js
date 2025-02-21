#!/usr/bin/env node

const { execSync } = require('child_process');
const { join } = require('path');

// Exécuter le script shell avec les arguments
try {
  execSync(`bash ${join(__dirname, '../lib/gitflow.sh')} "$@"`, {
    stdio: 'inherit',
    shell: true
  });
} catch (error) {
  process.exit(1);
} 