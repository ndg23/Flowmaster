#!/usr/bin/env node

import * as fs from 'fs';
import * as path from 'path';
import { version } from '../package.json';

// Mettre à jour le CHANGELOG.md
const changelogPath: string = path.join(__dirname, '..', 'CHANGELOG.md');
const date: string = new Date().toISOString().split('T')[0] || new Date().toISOString();

const newEntry: string = `
## [${version}] - ${date} 🚀
### Ajouté
- ✨ Correction des problèmes d'installation npm
- ✨ Amélioration de la gestion des fichiers
### Modifié
- 🔄 Restructuration du package npm
### Corrigé
- 🐛 Problème de permissions sur gitflow.sh
- 🐛 Gestion des chemins de fichiers
`;

let changelog: string = fs.readFileSync(changelogPath, 'utf8');
changelog = changelog.replace(
  '# 📝 Journal des modifications | Changelog | Registro de cambios',
  '# 📝 Journal des modifications | Changelog | Registro de cambios\n' + newEntry
);
fs.writeFileSync(changelogPath, changelog);

console.log(`✅ Updated CHANGELOG.md for version ${version}`);
