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