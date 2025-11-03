const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');
const os = require('os');

describe('FlowMaster Integration Tests', () => {
  let testDir;
  let originalCwd;

  beforeEach(() => {
    // Sauvegarder le répertoire courant
    originalCwd = process.cwd();
    
    // Créer un répertoire temporaire pour les tests
    testDir = fs.mkdtempSync(path.join(os.tmpdir(), 'flowmaster-test-'));
    process.chdir(testDir);
    
    // Initialiser un repo git
    execSync('git init', { stdio: 'pipe' });
    execSync('git config user.name "Test User"', { stdio: 'pipe' });
    execSync('git config user.email "test@example.com"', { stdio: 'pipe' });
  });

  afterEach(() => {
    // Restaurer le répertoire original
    process.chdir(originalCwd);
    
    // Nettoyer après les tests
    fs.rmSync(testDir, { recursive: true, force: true });
  });

  test('should initialize a new git repository', () => {
    expect(() => {
      const output = execSync('git status', { stdio: 'pipe' });
      expect(output.toString()).toContain('On branch');
    }).not.toThrow();
  });

  // Ajoutez d'autres tests d'intégration selon vos besoins
}); 