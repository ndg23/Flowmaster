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
const child_process_1 = require("child_process");
const readline = __importStar(require("readline"));
const semver = __importStar(require("semver"));
function exec(command) {
    try {
        return (0, child_process_1.execSync)(command, { encoding: 'utf8' }).trim();
    }
    catch (error) {
        console.error(`Error executing command: ${command}`);
        console.error(error.message);
        process.exit(1);
    }
}
const tags = exec('git tag')
    .split('\n')
    .filter((tag) => tag.startsWith('v'))
    .map((tag) => ({
    version: tag.substring(1),
    tag: tag,
    type: tag.includes('-alpha')
        ? 'alpha'
        : tag.includes('-beta')
            ? 'beta'
            : tag.includes('-rc')
                ? 'rc'
                : 'release',
}))
    .sort((a, b) => semver.compare(b.version, a.version));
const groupedTags = tags.reduce((acc, tag) => {
    const base = tag.version.split('-')[0] || tag.version;
    const key = `${base}-${tag.type}`;
    if (!acc[key])
        acc[key] = [];
    acc[key].push(tag);
    return acc;
}, {});
console.log('🔍 Analyzing tags...\n');
const tagsToKeep = new Set();
const tagsToDelete = new Set();
Object.entries(groupedTags).forEach(([, versions]) => {
    if (versions.length > 0 && versions[0]) {
        tagsToKeep.add(versions[0].tag);
        versions.slice(1).forEach((v) => tagsToDelete.add(v.tag));
    }
});
console.log('🟢 Tags to keep:');
tagsToKeep.forEach((tag) => {
    console.log(`   ${tag}`);
});
console.log('\n🔴 Tags to delete:');
tagsToDelete.forEach((tag) => {
    console.log(`   ${tag}`);
});
console.log('\n⚠️  This operation will delete the tags marked in red');
const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
});
rl.question('Continue? [y/N] ', (answer) => {
    if (answer.toLowerCase() === 'y') {
        tagsToDelete.forEach((tag) => {
            try {
                exec(`git tag -d ${tag}`);
                console.log(`✅ Deleted local tag: ${tag}`);
                exec(`git push origin :refs/tags/${tag}`);
                console.log(`✅ Deleted remote tag: ${tag}`);
            }
            catch (error) {
                console.error(`❌ Failed to delete tag ${tag}:`, error.message);
            }
        });
        console.log('\n✨ Tag cleanup completed!');
    }
    else {
        console.log('\n❌ Operation cancelled');
    }
    rl.close();
});
//# sourceMappingURL=clean-tags.js.map