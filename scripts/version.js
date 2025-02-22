#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { version } = require('../package.json');

// Mettre à jour le CHANGELOG.md
const changelogPath = path.join(__dirname, '..', 'CHANGELOG.md');
const date = new Date().toISOString().split('T')[0];

const newEntry = `
## [${version}] - ${date}
### Ajouté
- Correction des problèmes d'installation npm
- Amélioration de la gestion des fichiers
### Modifié
- Restructuration du package npm
### Corrigé
- Problème de permissions sur gitflow.sh
- Gestion des chemins de fichiers
`;

let changelog = fs.readFileSync(changelogPath, 'utf8');
changelog = changelog.replace('# Journal des modifications', '# Journal des modifications\n' + newEntry);
fs.writeFileSync(changelogPath, changelog);

console.log(`✅ Updated CHANGELOG.md for version ${version}`); 