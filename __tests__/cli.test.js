const { execSync } = require('child_process');
const { join } = require('path');
const fs = require('fs');
const path = require('path');

const flowmasterPath = path.join(__dirname, '..', 'bin', 'flowmaster.js');
const testDir = path.join(__dirname, 'temp-test-dir');

describe('FlowMaster CLI', () => {
    // Setup before each test
    beforeEach(() => {
        // Create a temporary test directory
        if (!fs.existsSync(testDir)) {
            fs.mkdirSync(testDir);
        }
        process.chdir(testDir);
    });

    // Cleanup after each test
    afterEach(() => {
        // Clean up the test directory
        if (fs.existsSync(testDir)) {
            fs.rmSync(testDir, { recursive: true, force: true });
        }
    });

    // Test version command
    test('should display version number', () => {
        const output = execSync(`node ${flowmasterPath} --version`).toString();
        expect(output).toMatch(/\d+\.\d+\.\d+/);
    });

    // Test help command
    test('should display help information', () => {
        const output = execSync(`node ${flowmasterPath} --help`).toString();
        expect(output).toContain('Usage:');
        expect(output).toContain('Options:');
        expect(output).toContain('Commands:');
    });

    // Test feature command help
    test('should display feature command help', () => {
        const output = execSync(`node ${flowmasterPath} feature --help`).toString();
        expect(output).toContain('feature');
        expect(output).toContain('start');
        expect(output).toContain('finish');
    });

    // Test init command
    test('should initialize git flow', () => {
        try {
            // Initialize Git
            execSync('git init');
            execSync('git config --local user.name "Test User"');
            execSync('git config --local user.email "test@example.com"');

            // Create initial commit
            execSync('git checkout -b main');
            execSync('git commit --allow-empty -m "Initial commit"');

            // Execute flowmaster init
            const output = execSync(`node ${flowmasterPath} init`, {
                encoding: 'utf8',
                stdio: ['pipe', 'pipe', 'pipe']
            });

            // Verify that the main branches were created
            const branches = execSync('git branch').toString();
            expect(branches).toContain('main');
            expect(branches).toContain('develop');
        } catch (error) {
            console.error('Test failed:', error.message);
            if (error.stdout) console.error('stdout:', error.stdout);
            if (error.stderr) console.error('stderr:', error.stderr);
            throw error;
        }
    });

    // Test comprehensive init command
    test('should initialize a complete project structure', () => {
        try {
            // Execute flowmaster init with automated responses
            // We'll use a temporary script to provide automated responses
            const initScript = `
      #!/bin/bash
      echo "y" # Initialize git repo
      echo "test-project" # Project name
      echo "0.1.0" # Initial version
      echo "A test project" # Description
      echo "y" # Create basic structure
      echo "y" # Node.js project
      echo "y" # Set up Git hooks
      `;

            fs.writeFileSync('init-script.sh', initScript);
            fs.chmodSync('init-script.sh', 0o755);

            // Run the init command with the script providing input
            execSync(`cat init-script.sh | node ${flowmasterPath} init`, {
                encoding: 'utf8',
                stdio: ['pipe', 'pipe', 'pipe']
            });

            // Verify that the project structure was created
            expect(fs.existsSync('README.md')).toBe(true);
            expect(fs.existsSync('CHANGELOG.md')).toBe(true);
            expect(fs.existsSync('.gitignore')).toBe(true);
            expect(fs.existsSync('LICENSE')).toBe(true);
            expect(fs.existsSync('package.json')).toBe(true);
            expect(fs.existsSync('src')).toBe(true);
            expect(fs.existsSync('docs')).toBe(true);
            expect(fs.existsSync('tests')).toBe(true);
            expect(fs.existsSync('.git/hooks/commit-msg')).toBe(true);

            // Verify package.json content
            const packageJson = JSON.parse(fs.readFileSync('package.json', 'utf8'));
            expect(packageJson.name).toBe('test-project');
            expect(packageJson.version).toBe('0.1.0');
            expect(packageJson.description).toBe('A test project');

            // Verify that the git branches were created
            const branches = execSync('git branch').toString();
            expect(branches).toContain('main');
            expect(branches).toContain('develop');
        } catch (error) {
            console.error('Test failed:', error.message);
            if (error.stdout) console.error('stdout:', error.stdout);
            if (error.stderr) console.error('stderr:', error.stderr);
            throw error;
        }
    });

    // Test reorganize command
    test('should reorganize an existing project', () => {
        try {
            // Set up a git repository with non-standard branches
            execSync('git init');
            execSync('git config --local user.name "Test User"');
            execSync('git config --local user.email "test@example.com"');

            // Create initial commit on master
            execSync('git checkout -b master');
            execSync('git commit --allow-empty -m "Initial commit"');

            // Create a non-standard branch
            execSync('git checkout -b my-feature');
            execSync('git commit --allow-empty -m "Add feature"');

            // Create a script to provide automated responses
            const reorganizeScript = `
      #!/bin/bash
      echo "master" # Use master as main branch
      echo "y" # Rename branches
      echo "feature" # Branch type
      echo "new-feature" # New name
      echo "y" # Set up Git hooks
      `;

            fs.writeFileSync('reorganize-script.sh', reorganizeScript);
            fs.chmodSync('reorganize-script.sh', 0o755);

            // Run the reorganize command with the script providing input
            execSync(`cat reorganize-script.sh | node ${flowmasterPath} reorganize`, {
                encoding: 'utf8',
                stdio: ['pipe', 'pipe', 'pipe']
            });

            // Verify that the branches were reorganized
            const branches = execSync('git branch').toString();
            expect(branches).toContain('master');
            expect(branches).toContain('develop');
            expect(branches).toContain('feature/new-feature');
            expect(branches).not.toContain('my-feature');

            // Verify that CHANGELOG.md was created
            expect(fs.existsSync('CHANGELOG.md')).toBe(true);

            // Verify that Git hooks were set up
            expect(fs.existsSync('.git/hooks/commit-msg')).toBe(true);
        } catch (error) {
            console.error('Test failed:', error.message);
            if (error.stdout) console.error('stdout:', error.stdout);
            if (error.stderr) console.error('stderr:', error.stderr);
            throw error;
        }
    });

    // Test feature start command
    test('should start a new feature', () => {
        try {
            // Initialize Git and flowmaster
            execSync('git init');
            execSync('git config --local user.name "Test User"');
            execSync('git config --local user.email "test@example.com"');

            // Create initial commit
            execSync('git checkout -b main');
            execSync('git commit --allow-empty -m "Initial commit"');

            // Initialize flowmaster
            execSync(`node ${flowmasterPath} init`);

            // Start a new feature
            const featureName = 'test-feature';
            execSync(`node ${flowmasterPath} feature start ${featureName}`, {
                encoding: 'utf8',
                stdio: ['pipe', 'pipe', 'pipe']
            });

            // Verify that the feature branch was created
            const branches = execSync('git branch').toString();
            expect(branches).toContain(`feature/${featureName}`);
        } catch (error) {
            console.error('Test failed:', error.message);
            if (error.stdout) console.error('stdout:', error.stdout);
            if (error.stderr) console.error('stderr:', error.stderr);
            throw error;
        }
    });

    // Test status command
    test('should show status', () => {
        try {
            // Initialize Git and flowmaster
            execSync('git init');
            execSync('git config --local user.name "Test User"');
            execSync('git config --local user.email "test@example.com"');

            // Create initial commit
            execSync('git checkout -b main');
            execSync('git commit --allow-empty -m "Initial commit"');

            // Initialize flowmaster
            execSync(`node ${flowmasterPath} init`);

            // Check status
            const output = execSync(`node ${flowmasterPath} status`, {
                encoding: 'utf8',
                stdio: ['pipe', 'pipe', 'pipe']
            });

            expect(output).toContain('Current branch');
        } catch (error) {
            console.error('Test failed:', error.message);
            if (error.stdout) console.error('stdout:', error.stdout);
            if (error.stderr) console.error('stderr:', error.stderr);
            throw error;
        }
    });

    // Test invalid command
    test('should handle invalid commands', () => {
        try {
            execSync(`node ${flowmasterPath} invalid-command`);
            // If the above command doesn't throw, the test should fail
            fail('Expected invalid command to throw an error');
        } catch (error) {
            expect(error.message).toContain('Invalid command');
        }
    });
});