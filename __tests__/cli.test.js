const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

describe('FlowMaster CLI', () => {
  const rootDir = path.join(__dirname, '..');  // Chemin vers la racine du projet
  const testDir = path.join(__dirname, 'test-repo');
  const flowmasterPath = path.join(rootDir, 'bin', 'flowmaster.js');

  beforeAll(() => {
    // Vérifier que flowmaster.js existe
    if (!fs.existsSync(flowmasterPath)) {
      throw new Error(`flowmaster.js not found at ${flowmasterPath}`);
    }
  });

  test('should display version number', () => {
    const output = execSync(`node ${flowmasterPath} --version`).toString();
    expect(output).toMatch(/\d+\.\d+\.\d+/); // Check the version format
  });

  test('should initialize git flow', () => {
    // Assuming the init command creates a specific file or directory
    execSync(`node ${flowmasterPath} init`);
    
    // Check if a specific file or directory was created
    const expectedFilePath = path.join(__dirname, '..', 'test-repo', 'some-config-file.json'); // Adjust as necessary
    expect(fs.existsSync(expectedFilePath)).toBe(true);

    // Clean up after test
    if (fs.existsSync(expectedFilePath)) {
      fs.unlinkSync(expectedFilePath);
    }
  });



  // Add more tests for other commands if necessary

  afterAll(() => {
    // Nettoyage final
    if (fs.existsSync(testDir)) {
      fs.rmSync(testDir, { recursive: true, force: true });
    }
  });
});