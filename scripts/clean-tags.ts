#!/usr/bin/env node

import { execSync } from 'child_process';
import * as readline from 'readline';
import * as semver from 'semver';

interface TagInfo {
  version: string;
  tag: string;
  type: 'alpha' | 'beta' | 'rc' | 'release';
}

// Fonction pour exécuter une commande shell
function exec(command: string): string {
  try {
    return execSync(command, { encoding: 'utf8' }).trim();
  } catch (error: any) {
    console.error(`Error executing command: ${command}`);
    console.error(error.message);
    process.exit(1);
  }
}

// Récupérer tous les tags git
const tags: TagInfo[] = exec('git tag')
  .split('\n')
  .filter((tag: string) => tag.startsWith('v'))
  .map(
    (tag: string): TagInfo => ({
      version: tag.substring(1),
      tag: tag,
      type: tag.includes('-alpha')
        ? 'alpha'
        : tag.includes('-beta')
          ? 'beta'
          : tag.includes('-rc')
            ? 'rc'
            : 'release',
    })
  )
  .sort((a: TagInfo, b: TagInfo) => semver.compare(b.version, a.version)); // Tri décroissant

// Grouper les tags par type de version
const groupedTags: Record<string, TagInfo[]> = tags.reduce(
  (acc: Record<string, TagInfo[]>, tag: TagInfo) => {
    const base: string = tag.version.split('-')[0] || tag.version; // Version de base sans préfixe
    const key: string = `${base}-${tag.type}`;
    if (!acc[key]) acc[key] = [];
    acc[key].push(tag);
    return acc;
  },
  {}
);

console.log('🔍 Analyzing tags...\n');

// Tags à conserver
const tagsToKeep: Set<string> = new Set();
// Tags à supprimer
const tagsToDelete: Set<string> = new Set();

// Pour chaque groupe, garder uniquement la version la plus récente
Object.entries(groupedTags).forEach(([, versions]: [string, TagInfo[]]) => {
  if (versions.length > 0 && versions[0]) {
    // Garder la version la plus récente
    tagsToKeep.add(versions[0].tag);

    // Marquer les autres versions pour suppression
    versions.slice(1).forEach((v: TagInfo) => tagsToDelete.add(v.tag));
  }
});

// Afficher les tags à conserver
console.log('🟢 Tags to keep:');
tagsToKeep.forEach((tag: string) => {
  console.log(`   ${tag}`);
});

// Afficher les tags à supprimer
console.log('\n🔴 Tags to delete:');
tagsToDelete.forEach((tag: string) => {
  console.log(`   ${tag}`);
});

// Demander confirmation
console.log('\n⚠️  This operation will delete the tags marked in red');
const rl: readline.Interface = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

rl.question('Continue? [y/N] ', (answer: string) => {
  if (answer.toLowerCase() === 'y') {
    // Supprimer les tags locaux et distants
    tagsToDelete.forEach((tag: string) => {
      try {
        // Supprimer tag local
        exec(`git tag -d ${tag}`);
        console.log(`✅ Deleted local tag: ${tag}`);

        // Supprimer tag distant
        exec(`git push origin :refs/tags/${tag}`);
        console.log(`✅ Deleted remote tag: ${tag}`);
      } catch (error: any) {
        console.error(`❌ Failed to delete tag ${tag}:`, error.message);
      }
    });
    console.log('\n✨ Tag cleanup completed!');
  } else {
    console.log('\n❌ Operation cancelled');
  }
  rl.close();
});
