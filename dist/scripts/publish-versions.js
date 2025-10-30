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
exports.exec = exec;
exports.updatePackageJson = updatePackageJson;
const child_process_1 = require("child_process");
const semver = __importStar(require("semver"));
const fs = __importStar(require("fs"));
const path = __importStar(require("path"));
function exec(command) {
    try {
        return (0, child_process_1.execSync)(command, { encoding: 'utf8' }).trim();
    }
    catch (error) {
        console.error(`Error executing command: ${command}`);
        console.error(error && error.message ? error.message : 'Unknown error occurred');
        process.exit(1);
    }
}
function updatePackageJson(version) {
    const packagePath = path.join(process.cwd(), 'package.json');
    const pkg = JSON.parse(fs.readFileSync(packagePath, 'utf8'));
    pkg.version = version;
    pkg.name = pkg.name || 'flowmaster-cli';
    pkg.description = pkg.description || 'A modern GitFlow CLI tool';
    pkg.main = pkg.main || 'index.js';
    pkg.scripts = pkg.scripts || {};
    pkg.scripts.test = 'jest';
    pkg.scripts['test:watch'] = 'jest --watch';
    pkg.scripts['test:coverage'] = 'jest --coverage';
    pkg.jest = {
        testEnvironment: 'node',
        testMatch: ['**/__tests__/**/*.js', '**/?(*.)+(spec|test).js'],
        coverageDirectory: 'coverage',
        collectCoverageFrom: ['src/**/*.js', '!**/node_modules/**', '!**/vendor/**'],
    };
    fs.writeFileSync(packagePath, JSON.stringify(pkg, null, 2));
}
const tags = exec('git tag')
    .split('\n')
    .filter((tag) => tag.startsWith('v'))
    .map((tag) => tag.substring(1))
    .sort((a, b) => semver.compare(a, b));
if (tags.length === 0) {
    console.error('❌ No tags found');
    process.exit(1);
}
console.log('🏷️  Publishing tags:', tags.join(', '));
const currentBranch = exec('git rev-parse --abbrev-ref HEAD');
tags.forEach((version) => {
    try {
        console.log(`\n📦 Processing version ${version}...`);
        exec(`git checkout v${version}`);
        updatePackageJson(version);
        const npmTag = version.includes('-alpha')
            ? 'alpha'
            : version.includes('-beta')
                ? 'beta'
                : version.includes('-rc')
                    ? 'rc'
                    : 'latest';
        console.log(`Publishing version ${version} with tag ${npmTag}...`);
        exec(`npm publish --tag ${npmTag} --access public`);
        console.log(`✅ Successfully published version ${version}`);
    }
    catch (error) {
        console.error(`❌ Failed to publish version ${version}`);
        console.error(error ? error.message : 'Unknown error occurred');
    }
});
exec(`git checkout ${currentBranch}`);
console.log('\n✨ All versions published successfully!');
//# sourceMappingURL=publish-versions.js.map