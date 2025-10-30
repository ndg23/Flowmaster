#!/usr/bin/env node
"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
const fs = __importStar(require("fs"));
const path = __importStar(require("path"));
const changelogPath = path.join(__dirname, '..', 'CHANGELOG.md');
let changelog = fs.readFileSync(changelogPath, 'utf8');
changelog = changelog.replace(/^# .*$/m, '# 📝 Journal des modifications | Changelog | Registro de cambios');
const dateFixRegex = /^## \[([\d\.]+(?:-(?:alpha|beta|rc)\.[\d]+)?)\] - ([\d-]+\s+🚀\d+\s+🚀|[\d-]+\s+🚀)/gm;
changelog = changelog.replace(dateFixRegex, (match, version) => {
    return `## [${version}] - 2025-02-24 🚀`;
});
const addEmojisToSection = (section, emoji) => {
    const sectionRegex = new RegExp(`(^${section}\\n(?:- (?!${emoji}|[💰📄🌐⚙️🔄📊🐛🔧🔍🗑️📦]).*\\n)*?)`, 'gm');
    changelog = changelog.replace(sectionRegex, (match) => {
        return match.replace(new RegExp(`^- ([^💰📄🌐⚙️🔄📊🐛🔧🔍🗑️📦])`, 'gm'), `- ${emoji} $1`);
    });
};
addEmojisToSection('### Ajouté', '✨');
addEmojisToSection('### Modifié', '🔄');
addEmojisToSection('### Corrigé', '🐛');
addEmojisToSection('### Supprimé', '🗑️');
fs.writeFileSync(changelogPath, changelog);
console.log('✅ CHANGELOG.md has been fixed and standardized');
//# sourceMappingURL=fix-changelog.js.map