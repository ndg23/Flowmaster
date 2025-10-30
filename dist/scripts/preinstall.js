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
const fs = __importStar(require("fs"));
function checkPrerequisites() {
    try {
        (0, child_process_1.execSync)('git --version', { stdio: 'ignore' });
        const nodeVersion = process.version.match(/^v(\d+)/)?.[1] || '0';
        if (parseInt(nodeVersion) < 12) {
            throw new Error('Node.js 12 or higher is required');
        }
        const npmRoot = (0, child_process_1.execSync)('npm root -g', { encoding: 'utf8' }).trim();
        try {
            fs.accessSync(npmRoot, fs.constants.W_OK);
        }
        catch {
            throw new Error('EACCES');
        }
    }
    catch (error) {
        if (error.message === 'EACCES') {
            console.error('⚠️  Insufficient permissions. Please install with sudo:');
            console.error('sudo npm install -g flowmaster-cli');
        }
        else {
            console.error('❌ Prerequisites check failed:', error.message);
        }
        process.exit(1);
    }
}
checkPrerequisites();
//# sourceMappingURL=preinstall.js.map