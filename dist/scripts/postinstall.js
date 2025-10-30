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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const fs = __importStar(require("fs"));
const path = __importStar(require("path"));
const child_process_1 = require("child_process");
const chalk_1 = __importDefault(require("chalk"));
function installGlobally() {
    try {
        const npmRoot = (0, child_process_1.execSync)('npm root -g', { encoding: 'utf8' }).trim();
        const binPath = path.join(npmRoot, '..', 'bin');
        const libPath = path.join(npmRoot, 'flowmaster-cli', 'lib');
        if (!fs.existsSync(libPath)) {
            fs.mkdirSync(libPath, { recursive: true });
        }
        const gitflowSrc = path.join(__dirname, '..', 'gitflow.sh');
        const gitflowDest = path.join(libPath, 'gitflow.sh');
        fs.copyFileSync(gitflowSrc, gitflowDest);
        const filesToChmod = [
            path.join(binPath, 'flowmaster'),
            path.join(binPath, 'fm'),
            gitflowDest,
        ];
        filesToChmod.forEach((file) => {
            if (fs.existsSync(file)) {
                fs.chmodSync(file, '755');
            }
        });
        console.log('✅ Flowmaster installed successfully!');
        console.log('You can now use:');
        console.log('  • flowmaster');
        console.log('  • fm');
        console.log(chalk_1.default.cyan('\n💖 Enjoy FlowMaster CLI? Consider supporting the development!\n'));
        console.log(chalk_1.default.white('PayPal: https://paypal.me/VOTRE_USERNAME_PAYPAL'));
        console.log(chalk_1.default.white('GitHub Sponsors: https://github.com/sponsors/ndg23\n'));
    }
    catch (error) {
        if (error.code === 'EACCES') {
            console.error('⚠️  Permission denied. Please try:');
            console.error('sudo npm install -g flowmaster-cli');
        }
        else {
            console.error('❌ Installation failed:', error.message);
        }
        process.exit(1);
    }
}
installGlobally();
//# sourceMappingURL=postinstall.js.map