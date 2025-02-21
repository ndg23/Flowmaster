#!/usr/bin/env node

const { execSync } = require('child_process');
const semver = require('semver');

// Fonction pour exécuter une commande shell
function exec(command) {
  try {
    return execSync(command, { encoding: 'utf8' }).trim();
  } catch (error) {
    console.error(`Error executing command: ${command}`);
    console.error(error.message);
    process.exit(1);
  }
}

// Récupérer tous les tags git
const tags = exec('git tag')
  .split('\n')
  .filter(tag => tag.startsWith('v'))
  .map(tag => ({
    version: tag.substring(1),
    tag: tag,
    type: tag.includes('-alpha') ? 'alpha' :
          tag.includes('-beta') ? 'beta' :
          tag.includes('-rc') ? 'rc' : 'release'
  }))
  .sort((a, b) => semver.compare(b.version, a.version)); // Tri décroissant

// Grouper les tags par type de version
const groupedTags = tags.reduce((acc, tag) => {
  const base = tag.version.split('-')[0]; // Version de base sans préfixe
  const key = `${base}-${tag.type}`;
  if (!acc[key]) acc[key] = [];
  acc[key].push(tag);
  return acc;
}, {});

console.log('🔍 Analyzing tags...\n');

// Tags à conserver
const tagsToKeep = new Set();
// Tags à supprimer
const tagsToDelete = new Set();

// Pour chaque groupe, garder uniquement la version la plus récente
Object.entries(groupedTags).forEach(([key, versions]) => {
  if (versions.length > 0) {
    // Garder la version la plus récente
    tagsToKeep.add(versions[0].tag);
    
    // Marquer les autres versions pour suppression
    versions.slice(1).forEach(v => tagsToDelete.add(v.tag));
  }
});

// Afficher les tags à conserver
console.log('🟢 Tags to keep:');
tagsToKeep.forEach(tag => {
  console.log(`   ${tag}`);
});

// Afficher les tags à supprimer
console.log('\n🔴 Tags to delete:');
tagsToDelete.forEach(tag => {
  console.log(`   ${tag}`);
});

// Demander confirmation
console.log('\n⚠️  This operation will delete the tags marked in red');
const readline = require('readline').createInterface({
  input: process.stdin,
  output: process.stdout
});

readline.question('Continue? [y/N] ', (answer) => {
  if (answer.toLowerCase() === 'y') {
    // Supprimer les tags locaux et distants
    tagsToDelete.forEach(tag => {
      try {
        // Supprimer tag local
        exec(`git tag -d ${tag}`);
        console.log(`✅ Deleted local tag: ${tag}`);
        
        // Supprimer tag distant
        exec(`git push origin :refs/tags/${tag}`);
        console.log(`✅ Deleted remote tag: ${tag}`);
      } catch (error) {
        console.error(`❌ Failed to delete tag ${tag}:`, error.message);
      }
    });
    console.log('\n✨ Tag cleanup completed!');
  } else {
    console.log('\n❌ Operation cancelled');
  }
  readline.close();
}); 