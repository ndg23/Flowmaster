#!/usr/bin/env node

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const os = require('os');

function setupAlias() {
  const isWindows = process.platform === 'win32';
  const homeDir = os.homedir();
  let rcFile;

  // Déterminer le fichier RC approprié
  if (isWindows) {
    // Pour Windows, on pourrait créer un fichier batch
    const batchFile = path.join(process.env.USERPROFILE, 'flowmaster.cmd');
    fs.writeFileSync(batchFile, '@echo off\nflowmaster %*');
    return;
  }

  // Pour Unix-like systems
  if (fs.existsSync(path.join(homeDir, '.zshrc'))) {
    rcFile = path.join(homeDir, '.zshrc');
  } else if (fs.existsSync(path.join(homeDir, '.bashrc'))) {
    rcFile = path.join(homeDir, '.bashrc');
  } else {
    rcFile = path.join(homeDir, '.profile');
  }

  // Ajouter l'alias
  const aliasLine = '\nalias fm="flowmaster"';
  fs.appendFileSync(rcFile, aliasLine);

  console.log(`\x1b[32m✓\x1b[0m Alias 'fm' added to ${rcFile}`);
  console.log('\x1b[33mℹ\x1b[0m Please restart your terminal or run:');
  console.log(`\x1b[36msource ${rcFile}\x1b[0m`);
}

function checkGitInstallation() {
  try {
    execSync('git --version', { stdio: 'ignore' });
  } catch (error) {
    console.error('\x1b[31m✗\x1b[0m Git is not installed. Please install Git first.');
    process.exit(1);
  }
}

function createInitialConfig() {
  const configDir = path.join(os.homedir(), '.flowmaster');
  const configFile = path.join(configDir, 'config.json');

  if (!fs.existsSync(configDir)) {
    fs.mkdirSync(configDir, { recursive: true });
  }

  if (!fs.existsSync(configFile)) {
    const defaultConfig = {
      defaultBranch: 'main',
      featurePrefix: 'feature',
      releasePrefix: 'release',
      hotfixPrefix: 'hotfix',
      versionPrefix: 'v'
    };

    fs.writeFileSync(configFile, JSON.stringify(defaultConfig, null, 2));
    console.log('\x1b[32m✓\x1b[0m Created default configuration file');
  }
}

// Chemin vers gitflow.sh
const gitflowPath = path.join(__dirname, '..', 'gitflow.sh');
const libPath = path.join(__dirname, '..', 'lib');

// Créer le dossier lib s'il n'existe pas
if (!fs.existsSync(libPath)) {
  fs.mkdirSync(libPath, { recursive: true });
}

// Copier gitflow.sh dans lib s'il n'y est pas
const libGitflowPath = path.join(libPath, 'gitflow.sh');
if (!fs.existsSync(libGitflowPath)) {
  fs.copyFileSync(gitflowPath, libGitflowPath);
}

// Rendre le script exécutable
try {
  fs.chmodSync(libGitflowPath, '755');
  console.log('✅ Successfully configured Flowmaster');
} catch (error) {
  console.error('❌ Failed to set permissions:', error.message);
  process.exit(1);
}

try {
  console.log('\x1b[36m⚙\x1b[0m Setting up Flowmaster...');
  
  checkGitInstallation();
  setupAlias();
  createInitialConfig();

  console.log('\x1b[32m✓\x1b[0m Flowmaster installed successfully!');
  console.log('\x1b[36mℹ\x1b[0m Use \x1b[33mflowmaster\x1b[0m or \x1b[33mfm\x1b[0m to start using the tool');
} catch (error) {
  console.error('\x1b[31m✗\x1b[0m Installation failed:', error.message);
  process.exit(1);
} 