#!/usr/bin/env node
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const child_process_1 = require("child_process");
const package_json_1 = require("../package.json");
function exec(command) {
    try {
        return (0, child_process_1.execSync)(command, { encoding: 'utf8', stdio: 'inherit' });
    }
    catch {
        console.error(`Failed to execute: ${command}`);
        process.exit(1);
    }
}
const currentBranch = (0, child_process_1.execSync)('git rev-parse --abbrev-ref HEAD', {
    encoding: 'utf8',
}).trim();
if (currentBranch !== 'main') {
    console.error('❌ Must be on main branch to publish');
    process.exit(1);
}
if ((0, child_process_1.execSync)('git status --porcelain', { encoding: 'utf8' }).length > 0) {
    console.error('❌ Working directory not clean');
    process.exit(1);
}
console.log(`📦 Publishing version ${package_json_1.version}...`);
try {
    exec('rm -rf lib');
    exec('npm run build');
    exec('npm publish --access public');
    exec(`git tag -a v${package_json_1.version} -m "Release version ${package_json_1.version}"`);
    exec('git push origin --tags');
    console.log(`✅ Successfully published version ${package_json_1.version}`);
}
catch (error) {
    console.error('❌ Failed to publish:', error.message);
    process.exit(1);
}
//# sourceMappingURL=publish-npm.js.map