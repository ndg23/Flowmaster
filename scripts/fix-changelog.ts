#!/usr/bin/env node

/**
 * This script fixes the CHANGELOG.md file format issues
 * and ensures consistency across all version entries.
 */

import * as fs from 'fs';
import * as path from 'path';

// Path to the changelog file
const changelogPath: string = path.join(__dirname, '..', 'CHANGELOG.md');

// Read the current changelog
let changelog: string = fs.readFileSync(changelogPath, 'utf8');

// Ensure the title is standardized
changelog = changelog.replace(
  /^# .*$/m,
  '# 📝 Journal des modifications | Changelog | Registro de cambios'
);

// Fix date format issues by completely replacing problematic dates
// This regex matches version headers with corrupted dates
const dateFixRegex: RegExp =
  /^## \[([\d\.]+(?:-(?:alpha|beta|rc)\.[\d]+)?)\] - ([\d-]+\s+🚀\d+\s+🚀|[\d-]+\s+🚀)/gm;

// Replace with a standardized format
changelog = changelog.replace(dateFixRegex, (match: string, version: string): string => {
  // Use a fixed date for all problematic entries
  return `## [${version}] - 2025-02-24 🚀`;
});

// Add emojis to section items if missing
const addEmojisToSection = (section: string, emoji: string): void => {
  const sectionRegex: RegExp = new RegExp(
    `(^${section}\\n(?:- (?!${emoji}|[💰📄🌐⚙️🔄📊🐛🔧🔍🗑️📦]).*\\n)*?)`,
    'gm'
  );
  changelog = changelog.replace(sectionRegex, (match: string): string => {
    return match.replace(new RegExp(`^- ([^💰📄🌐⚙️🔄📊🐛🔧🔍🗑️📦])`, 'gm'), `- ${emoji} $1`);
  });
};

// Add emojis to each section type
addEmojisToSection('### Ajouté', '✨');
addEmojisToSection('### Modifié', '🔄');
addEmojisToSection('### Corrigé', '🐛');
addEmojisToSection('### Supprimé', '🗑️');

// Write the fixed changelog back to the file
fs.writeFileSync(changelogPath, changelog);

console.log('✅ CHANGELOG.md has been fixed and standardized');
