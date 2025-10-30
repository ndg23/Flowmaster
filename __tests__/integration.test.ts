import { execSync } from 'child_process';
import * as fs from 'fs';
import * as path from 'path';

const flowmasterPath: string = path.join(__dirname, '..', 'dist', 'bin', 'flowmaster.js');
const testDir: string = path.join(__dirname, 'integration-test-dir');

describe('FlowMaster Integration Tests', () => {
  beforeAll(() => {
    // Create a temporary test directory for integration tests
    if (!fs.existsSync(testDir)) {
      fs.mkdirSync(testDir, { recursive: true });
    }
    process.chdir(testDir);
  });

  afterAll(() => {
    // Clean up the test directory
    process.chdir(__dirname);
    if (fs.existsSync(testDir)) {
      fs.rmSync(testDir, { recursive: true, force: true });
    }
  });

  beforeEach(() => {
    // Initialize git repo for each test
    try {
      execSync('git init');
      execSync('git config --local user.name "Integration Test User"');
      execSync('git config --local user.email "integration@test.com"');
    } catch (error) {
      console.error('Failed to initialize git:', error);
    }
  });

  afterEach(() => {
    // Clean up git repo after each test
    try {
      fs.rmSync('.git', { recursive: true, force: true });
      // Remove any created files
      const files: string[] = fs.readdirSync('.');
      files.forEach((file: string) => {
        if (file !== 'node_modules' && !file.startsWith('.')) {
          fs.rmSync(file, { recursive: true, force: true });
        }
      });
    } catch (error) {
      console.error('Failed to cleanup:', error);
    }
  });

  test('Basic GitFlow initialization works', () => {
    try {
      // Create a simple init script that provides minimal input
      const initScript = `#!/bin/bash
echo "y"  # Initialize git repo
echo "test-project"  # Project name
echo "1.0.0"  # Version
echo "Test project"  # Description
echo "n"  # No basic structure
echo "n"  # No Node.js project
echo "n"  # No Git hooks
`;
      fs.writeFileSync('init-script.sh', initScript);
      fs.chmodSync('init-script.sh', '755');

      // Run init command
      execSync(`cat init-script.sh | node ${flowmasterPath} init`, {
        encoding: 'utf8',
        stdio: ['pipe', 'pipe', 'pipe'],
      });

      // Verify basic git flow setup
      const branches = execSync('git branch').toString();
      expect(branches).toContain('develop');

      console.log('✅ Basic initialization test passed!');
    } catch (error: any) {
      console.error('Basic init test failed:', error.message);
      if (error.stdout) console.error('stdout:', error.stdout);
      if (error.stderr) console.error('stderr:', error.stderr);
      throw error;
    }
  });

  test('Feature branch operations work', () => {
    try {
      // Initialize first
      const initScript = `#!/bin/bash
echo "y"
echo "feature-test"
echo "1.0.0"
echo "Feature test"
echo "n"
echo "n"
echo "n"
`;
      fs.writeFileSync('init-script.sh', initScript);
      fs.chmodSync('init-script.sh', '755');
      execSync(`cat init-script.sh | node ${flowmasterPath} init`, {
        encoding: 'utf8',
        stdio: ['pipe', 'pipe', 'pipe'],
      });

      // Just test that feature start command executes without error
      execSync(`echo "y" | node ${flowmasterPath} feature start test-feature`, {
        encoding: 'utf8',
        stdio: ['pipe', 'pipe', 'pipe'],
      });

      // Verify feature branch exists
      const branches = execSync('git branch').toString();
      expect(branches).toContain('feature/test-feature');

      console.log('✅ Feature start test passed!');
    } catch (error: any) {
      console.error('Feature test failed:', error.message);
      if (error.stdout) console.error('stdout:', error.stdout);
      if (error.stderr) console.error('stderr:', error.stderr);
      throw error;
    }
  });

  test('Error handling: invalid operations', () => {
    try {
      // Try to start a feature without initialization (should fail)
      let failed = false;
      try {
        execSync(`node ${flowmasterPath} feature start test-feature`, {
          encoding: 'utf8',
          stdio: ['pipe', 'pipe', 'pipe'],
        });
      } catch {
        failed = true;
      }
      expect(failed).toBe(true);

      // Initialize first
      const initScript = `#!/bin/bash
echo "y"
echo "error-test"
echo "1.0.0"
echo "Error test"
echo "n"
echo "n"
echo "n"
`;
      fs.writeFileSync('init-script.sh', initScript);
      fs.chmodSync('init-script.sh', '755');
      execSync(`cat init-script.sh | node ${flowmasterPath} init`, {
        encoding: 'utf8',
        stdio: ['pipe', 'pipe', 'pipe'],
      });

      // Try to start a feature with invalid name (should fail)
      failed = false;
      try {
        execSync(`node ${flowmasterPath} feature start "invalid name with spaces"`, {
          encoding: 'utf8',
          stdio: ['pipe', 'pipe', 'pipe'],
        });
      } catch {
        failed = true;
      }
      expect(failed).toBe(true);

      console.log('✅ Error handling tests passed!');
    } catch (error: any) {
      console.error('Error handling test failed:', error.message);
      throw error;
    }
  });
});
