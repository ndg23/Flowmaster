const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

describe('FlowMaster CLI', () => {
  const flowmasterPath = path.join(__dirname, '../bin/flowmaster.js');
  const gitflowPath = path.join(__dirname, '../lib/gitflow.sh');

  beforeAll(() => {
    // S'assurer que gitflow.sh a les permissions d'exécution
    if (fs.existsSync(gitflowPath)) {
      execSync(`chmod +x ${gitflowPath}`);
    }
  });

  // Test si le fichier existe
  test('flowmaster script should exist', () => {
    expect(fs.existsSync(flowmasterPath)).toBe(true);
  });

  // Test si Git est installé
  test('should detect Git installation', () => {
    expect(() => {
      execSync('git --version');
    }).not.toThrow();
  });

  // Test si le script gitflow.sh existe
  test('gitflow.sh script should exist', () => {
    expect(fs.existsSync(gitflowPath)).toBe(true);
  });

  // Test d'exécution du menu avec mock
  test('should execute without errors', () => {
    // Créer un fichier gitflow.sh temporaire pour le test
    const tempScript = `#!/bin/bash
    echo "Menu mock"
    exit 0`;

    const tempPath = path.join(__dirname, 'temp-gitflow.sh');
    fs.writeFileSync(tempPath, tempScript);
    execSync(`chmod +x ${tempPath}`);

    try {
      execSync(`GITFLOW_SCRIPT="${tempPath}" node ${flowmasterPath}`, {
        env: { ...process.env, GITFLOW_SCRIPT: tempPath },
        stdio: 'pipe'
      });
    } finally {
      // Nettoyer le fichier temporaire
      fs.unlinkSync(tempPath);
    }
  });
}); 