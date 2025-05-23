#!/usr/bin/env node

const { execSync } = require('child_process');
const semver = require('semver');
const fs = require('fs');
const path = require('path');

// Fonction pour exécuter une commande shell
function exec(command) {
  try {
    return execSync(command, { encoding: 'utf8' }).trim();
  } catch (error) {
    console.error(`Error executing command: ${command}`);
    console.error((error && error.message) ? error.message : 'Unknown error occurred');
    process.exit(1);
  }
}

// Fonction pour mettre à jour package.json
function updatePackageJson(version) {
  const packagePath = path.join(process.cwd(), 'package.json');
  const pkg = require(packagePath);
  
  pkg.version = version;
  
  // Ensure required fields are present
  pkg.name = pkg.name || 'flowmaster-cli';
  pkg.description = pkg.description || 'A modern GitFlow CLI tool';
  pkg.main = pkg.main || 'index.js';
  
  // Add test configuration
  pkg.scripts = pkg.scripts || {};
  pkg.scripts.test = 'jest';
  pkg.scripts['test:watch'] = 'jest --watch';
  pkg.scripts['test:coverage'] = 'jest --coverage';
  
  // Add Jest configuration
  pkg.jest = {
    testEnvironment: 'node',
    testMatch: ['**/__tests__/**/*.js', '**/?(*.)+(spec|test).js'],
    coverageDirectory: 'coverage',
    collectCoverageFrom: [
      'src/**/*.js',
      '!**/node_modules/**',
      '!**/vendor/**'
    ]
  };

  fs.writeFileSync(packagePath, JSON.stringify(pkg, null, 2));
}

// Récupérer tous les tags git
const tags = exec('git tag')
  .split('\n')
  .filter(tag => tag.startsWith('v'))
  .map(tag => tag.substring(1))
  .sort((a, b) => semver.compare(a, b));

if (tags.length === 0) {
  console.error('❌ No tags found');
  process.exit(1);
}

console.log('🏷️  Publishing tags:', tags.join(', '));

// Sauvegarder la branche actuelle
const currentBranch = exec('git rev-parse --abbrev-ref HEAD');

// Publier chaque version
tags.forEach(version => {
  try {
    console.log(`\n📦 Processing version ${version}...`);
    
    // Checkout le tag
    exec(`git checkout v${version}`);
    
    // Mettre à jour package.json
    updatePackageJson(version);
    
    // Déterminer le tag npm
    const npmTag = version.includes('-alpha') ? 'alpha' :
                  version.includes('-beta') ? 'beta' :
                  version.includes('-rc') ? 'rc' : 'latest';
    
    console.log(`Publishing version ${version} with tag ${npmTag}...`);
    exec(`npm publish --tag ${npmTag} --access public`);
    
    console.log(`✅ Successfully published version ${version}`);
    
  } catch (error) {
    console.error(`❌ Failed to publish version ${version}`);
    console.error(error ? error.message : 'Unknown error occurred');
  }
});

// Retourner à la branche d'origine
exec(`git checkout ${currentBranch}`);

console.log('\n✨ All versions published successfully!');

// Export functions for testing
module.exports = {
  exec,
  updatePackageJson
}; 
