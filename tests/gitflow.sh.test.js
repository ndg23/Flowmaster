const { execSync } = require('child_process');
const path = require('path');

describe('GitFlow Shell Script', () => {
  const gitflowPath = path.join(__dirname, '../lib/gitflow.sh');

  // Test des permissions d'exécution
  test('gitflow.sh should be executable', () => {
    expect(() => {
      execSync(`test -x ${gitflowPath}`);
    }).not.toThrow();
  });

  // Test de la syntaxe du script
  test('gitflow.sh should have valid syntax', () => {
    expect(() => {
      execSync(`bash -n ${gitflowPath}`);
    }).not.toThrow();
  });
}); 