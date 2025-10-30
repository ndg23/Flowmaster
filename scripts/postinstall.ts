#!/usr/bin/env node

import * as fs from 'fs';
import * as path from 'path';
import { execSync } from 'child_process';
import chalk from 'chalk';

function installGlobally(): void {
  try {
    // Obtenir le chemin d'installation global
    const npmRoot: string = execSync('npm root -g', { encoding: 'utf8' }).trim();
    const binPath: string = path.join(npmRoot, '..', 'bin');
    const libPath: string = path.join(npmRoot, 'flowmaster-cli', 'lib');

    // Créer le dossier lib si nécessaire
    if (!fs.existsSync(libPath)) {
      fs.mkdirSync(libPath, { recursive: true });
    }

    // Copier gitflow.sh dans lib/
    const gitflowSrc: string = path.join(__dirname, '..', 'gitflow.sh');
    const gitflowDest: string = path.join(libPath, 'gitflow.sh');
    fs.copyFileSync(gitflowSrc, gitflowDest);

    // Rendre les fichiers exécutables
    const filesToChmod: string[] = [
      path.join(binPath, 'flowmaster'),
      path.join(binPath, 'fm'),
      gitflowDest,
    ];

    filesToChmod.forEach((file: string) => {
      if (fs.existsSync(file)) {
        fs.chmodSync(file, '755');
      }
    });

    console.log('✅ Flowmaster installed successfully!');
    console.log('You can now use:');
    console.log('  • flowmaster');
    console.log('  • fm');

    console.log(chalk.cyan('\n💖 Enjoy FlowMaster CLI? Consider supporting the development!\n'));
    console.log(chalk.white('PayPal: https://paypal.me/VOTRE_USERNAME_PAYPAL'));
    console.log(chalk.white('GitHub Sponsors: https://github.com/sponsors/ndg23\n'));
  } catch (error: any) {
    if (error.code === 'EACCES') {
      console.error('⚠️  Permission denied. Please try:');
      console.error('sudo npm install -g flowmaster-cli');
    } else {
      console.error('❌ Installation failed:', error.message);
    }
    process.exit(1);
  }
}

installGlobally();
