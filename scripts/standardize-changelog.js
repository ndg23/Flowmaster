#!/usr/bin/env node

/**
 * This script standardizes the format of the CHANGELOG.md file
 * to ensure consistency across all version entries.
 */

const fs = require('fs');
const path = require('path');

// Path to the changelog file
const changelogPath = path.join(__dirname, '..', 'CHANGELOG.md');

// Read the current changelog
let changelog = fs.readFileSync(changelogPath, 'utf8');

// Ensure the title is standardized
changelog = changelog.replace(/^# .*$/m, '# 📝 Journal des modifications | Changelog | Registro de cambios');

// Fix date format issues (like "2025-02-2 🚀4 🚀")
changelog = changelog.replace(/^## \[([\d\.]+(?:-(?:alpha|beta|rc)\.[\d]+)?)\] - ([\d-]+)\s+🚀\d+\s+🚀/gm, '## [$1] - $2 🚀');

// Standardize version headers to include the rocket emoji if missing
changelog = changelog.replace(/^## \[([\d\.]+(?:-(?:alpha|beta|rc)\.[\d]+)?)\] - ([\d-]+)(?!\s+🚀)/gm, '## [$1] - $2 🚀');

// Add emojis to section items if missing
const addEmojisToSection = (section, emoji) => {
    const sectionRegex = new RegExp(`(^${section}\\n(?:- (?!${emoji}).*\\n)*?)`, 'gm');
    changelog = changelog.replace(sectionRegex, (match) => {
        return match.replace(/^- ([^✨🔄🐛🗑️💰📄🌐⚙️📊🔧🔍📦])/gm, `- ${emoji} $1`);
    });
};

// Add emojis to each section type
addEmojisToSection('### Ajouté', '✨');
addEmojisToSection('### Modifié', '🔄');
addEmojisToSection('### Corrigé', '🐛');
addEmojisToSection('### Supprimé', '🗑️');

// Write the standardized changelog back to the file
fs.writeFileSync(changelogPath, changelog);

console.log('✅ CHANGELOG.md has been standardized for consistent formatting');