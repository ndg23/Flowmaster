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
const package_json_1 = require("../package.json");
const changelogPath = path.join(__dirname, '..', 'CHANGELOG.md');
const date = new Date().toISOString().split('T')[0] || new Date().toISOString();
const newEntry = `
## [${package_json_1.version}] - ${date} 🚀
### Ajouté
- ✨ Correction des problèmes d'installation npm
- ✨ Amélioration de la gestion des fichiers
### Modifié
- 🔄 Restructuration du package npm
### Corrigé
- 🐛 Problème de permissions sur gitflow.sh
- 🐛 Gestion des chemins de fichiers
`;
let changelog = fs.readFileSync(changelogPath, 'utf8');
changelog = changelog.replace('# 📝 Journal des modifications | Changelog | Registro de cambios', '# 📝 Journal des modifications | Changelog | Registro de cambios\n' + newEntry);
fs.writeFileSync(changelogPath, changelog);
console.log(`✅ Updated CHANGELOG.md for version ${package_json_1.version}`);
//# sourceMappingURL=version.js.map