const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const flowmasterPath = path.join(__dirname, '..', 'dist', 'bin', 'flowmaster.js');
const testDir = path.join(__dirname, 'temp-changelog-test-dir');

describe('Changelog Management', () => {
  // Setup before each test
  beforeEach(() => {
    // Create a temporary test directory
    if (!fs.existsSync(testDir)) {
      fs.mkdirSync(testDir);
    }
    process.chdir(testDir);

    // Initialize git repository
    execSync('git init');
    execSync('git config --local user.name "Test User"');
    execSync('git config --local user.email "test@example.com"');

    // Create initial commit
    execSync('git checkout -b main');
    execSync('git commit --allow-empty -m "Initial commit"');

    // Initialize flowmaster
    const initScript = `
    #!/bin/bash
    echo "y" # Initialize git repo
    echo "changelog-test" # Project name
    echo "0.1.0" # Initial version
    echo "A test project for changelog" # Description
    echo "y" # Create basic structure
    echo "y" # Node.js project
    echo "y" # Set up Git hooks
    `;

    fs.writeFileSync('init-script.sh', initScript);
    fs.chmodSync('init-script.sh', 0o755);

    execSync(`cat init-script.sh | node ${flowmasterPath} init`, {
      encoding: 'utf8',
      stdio: ['pipe', 'pipe', 'pipe'],
    });
  });

  // Cleanup after each test
  afterEach(() => {
    // Clean up the test directory
    if (fs.existsSync(testDir)) {
      fs.rmSync(testDir, { recursive: true, force: true });
    }
  });

  // Test creating a conventional commit and updating changelog
  test('should update changelog when creating a conventional commit', () => {
    try {
      // Create a test file
      fs.writeFileSync('test-file.txt', 'Test content');

      // Add the file
      execSync('git add test-file.txt');

      // Create a conventional commit
      const commitScript = `
      #!/bin/bash
      echo "1" # Add all files
      echo "1" # feat type
      echo "test" # scope
      echo "add test file" # message
      echo "" # no breaking changes
      `;

      fs.writeFileSync('commit-script.sh', commitScript);
      fs.chmodSync('commit-script.sh', 0o755);

      // Run the commit command with the script providing input
      execSync(`cat commit-script.sh | node ${flowmasterPath} feature start test-feature`, {
        encoding: 'utf8',
        stdio: ['pipe', 'pipe', 'pipe'],
      });

      execSync(`cat commit-script.sh | node ${flowmasterPath} commit`, {
        encoding: 'utf8',
        stdio: ['pipe', 'pipe', 'pipe'],
      });

      // Verify that the changelog was updated
      const changelog = fs.readFileSync('CHANGELOG.md', 'utf8');
      expect(changelog).toContain('### Ajouté');
      expect(changelog).toContain('add test file');
    } catch (error) {
      console.error('Test failed:', error.message);
      if (error.stdout) console.error('stdout:', error.stdout);
      if (error.stderr) console.error('stderr:', error.stderr);
      throw error;
    }
  });

  // Test standardizing changelog format
  test('should standardize changelog format', () => {
    try {
      // Create a changelog with inconsistent formatting
      const inconsistentChangelog = `# Journal des modifications

## [0.1.0] - 2023-01-01
### Ajouté
- Feature 1
- Feature 2
### Modifié
- Change 1
- Change 2
### Corrigé
- Bug 1
- Bug 2
`;

      fs.writeFileSync('CHANGELOG.md', inconsistentChangelog);

      // Run the standardize-changelog script
      execSync(`node ${path.join(__dirname, '..', 'dist', 'scripts', 'standardize-changelog.js')}`, {
        encoding: 'utf8',
        stdio: ['pipe', 'pipe', 'pipe'],
      });

      // Verify that the changelog was standardized
      const standardizedChangelog = fs.readFileSync('CHANGELOG.md', 'utf8');
      expect(standardizedChangelog).toContain(
        '# 📝 Journal des modifications | Changelog | Registro de cambios'
      );
      expect(standardizedChangelog).toContain('## [0.1.0] - 2023-01-01 🚀');
      expect(standardizedChangelog).toContain('- ✨ Feature 1');
      expect(standardizedChangelog).toContain('- ✨ Feature 2');
      expect(standardizedChangelog).toContain('- 🔄 Change 1');
      expect(standardizedChangelog).toContain('- 🔄 Change 2');
      expect(standardizedChangelog).toContain('- 🐛 Bug 1');
      expect(standardizedChangelog).toContain('- 🐛 Bug 2');
    } catch (error) {
      console.error('Test failed:', error.message);
      if (error.stdout) console.error('stdout:', error.stdout);
      if (error.stderr) console.error('stderr:', error.stderr);
      throw error;
    }
  });

  // Test fixing changelog format
  test('should fix changelog format issues', () => {
    try {
      // Create a changelog with format issues
      const problematicChangelog = `# Journal des modifications

## [0.1.0] - 2023-01-01 🚀1 🚀
### Ajouté
- Feature 1
- Feature 2
### Modifié
- Change 1
- Change 2
### Corrigé
- Bug 1
- Bug 2
`;

      fs.writeFileSync('CHANGELOG.md', problematicChangelog);

      // Run the fix-changelog script
      execSync(`node ${path.join(__dirname, '..', 'dist', 'scripts', 'fix-changelog.js')}`, {
        encoding: 'utf8',
        stdio: ['pipe', 'pipe', 'pipe'],
      });

      // Verify that the changelog was fixed
      const fixedChangelog = fs.readFileSync('CHANGELOG.md', 'utf8');
      expect(fixedChangelog).toContain(
        '# 📝 Journal des modifications | Changelog | Registro de cambios'
      );
      expect(fixedChangelog).toContain('## [0.1.0] - 2025-02-24 🚀');
      expect(fixedChangelog).toContain('- ✨ Feature 1');
      expect(fixedChangelog).toContain('- ✨ Feature 2');
      expect(fixedChangelog).toContain('- 🔄 Change 1');
      expect(fixedChangelog).toContain('- 🔄 Change 2');
      expect(fixedChangelog).toContain('- 🐛 Bug 1');
      expect(fixedChangelog).toContain('- 🐛 Bug 2');
    } catch (error) {
      console.error('Test failed:', error.message);
      if (error.stdout) console.error('stdout:', error.stdout);
      if (error.stderr) console.error('stderr:', error.stderr);
      throw error;
    }
  });
});
