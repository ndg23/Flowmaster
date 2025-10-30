#!/usr/bin/env node

import { execSync } from 'child_process';
import { version } from '../package.json';

// Fonction pour exécuter une commande
function exec(command: string): string {
  try {
    return execSync(command, { encoding: 'utf8', stdio: 'inherit' });
  } catch {
    console.error(`Failed to execute: ${command}`);
    process.exit(1);
  }
}

// Vérifier qu'on est sur la branche main
const currentBranch: string = execSync('git rev-parse --abbrev-ref HEAD', {
  encoding: 'utf8',
}).trim();
if (currentBranch !== 'main') {
  console.error('❌ Must be on main branch to publish');
  process.exit(1);
}

// Vérifier les changements non commités
if (execSync('git status --porcelain', { encoding: 'utf8' }).length > 0) {
  console.error('❌ Working directory not clean');
  process.exit(1);
}

console.log(`📦 Publishing version ${version}...`);

try {
  // Nettoyer et préparer
  exec('rm -rf lib');
  exec('npm run build');

  // Publication sur npm
  exec('npm publish --access public');

  // Créer le tag git
  exec(`git tag -a v${version} -m "Release version ${version}"`);

  // Pousser le tag
  exec('git push origin --tags');

  console.log(`✅ Successfully published version ${version}`);
} catch (error: any) {
  console.error('❌ Failed to publish:', error.message);
  process.exit(1);
}
