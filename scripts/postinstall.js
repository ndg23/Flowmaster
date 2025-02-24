#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const chalk = require('chalk');

function installGlobally() {
  try {
    // Obtenir le chemin d'installation global
    const npmRoot = execSync('npm root -g', { encoding: 'utf8' }).trim();
    const binPath = path.join(npmRoot, '..', 'bin');
    const libPath = path.join(npmRoot, 'flowmaster-cli', 'lib');

    // Créer le dossier lib si nécessaire
    if (!fs.existsSync(libPath)) {
      fs.mkdirSync(libPath, { recursive: true });
    }

    // Copier gitflow.sh dans lib/
    const gitflowSrc = path.join(__dirname, '..', 'gitflow.sh');
    const gitflowDest = path.join(libPath, 'gitflow.sh');
    fs.copyFileSync(gitflowSrc, gitflowDest);

    // Rendre les fichiers exécutables
    const filesToChmod = [
      path.join(binPath, 'flowmaster'),
      path.join(binPath, 'fm'),
      gitflowDest
    ];

    filesToChmod.forEach(file => {
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

  } catch (error) {
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