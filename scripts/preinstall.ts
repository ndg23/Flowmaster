#!/usr/bin/env node

import { execSync } from 'child_process';
import * as fs from 'fs';

function checkPrerequisites(): void {
  try {
    // Vérifier Git
    execSync('git --version', { stdio: 'ignore' });

    // Vérifier Node version
    const nodeVersion: string = process.version.match(/^v(\d+)/)?.[1] || '0';
    if (parseInt(nodeVersion) < 12) {
      throw new Error('Node.js 12 or higher is required');
    }

    // Vérifier les permissions npm
    const npmRoot: string = execSync('npm root -g', { encoding: 'utf8' }).trim();
    try {
      fs.accessSync(npmRoot, fs.constants.W_OK);
    } catch {
      throw new Error('EACCES');
    }
  } catch (error: any) {
    if (error.message === 'EACCES') {
      console.error('⚠️  Insufficient permissions. Please install with sudo:');
      console.error('sudo npm install -g flowmaster-cli');
    } else {
      console.error('❌ Prerequisites check failed:', error.message);
    }
    process.exit(1);
  }
}

checkPrerequisites();
