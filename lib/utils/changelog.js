const fs = require('fs').promises;
const path = require('path');
const logger = require('./logger');

async function updateChangelog(version) {
  const changelogPath = path.join(process.cwd(), 'CHANGELOG.md');
  const date = new Date().toISOString().split('T')[0];
  
  try {
    let content = await fs.readFile(changelogPath, 'utf8');
    const newEntry = `\n## [${version}] - ${date}\n### Added\n### Changed\n### Fixed\n### Removed\n`;
    
    content = content.replace(/^/, `# Changelog\n${newEntry}`);
    await fs.writeFile(changelogPath, content);
    logger.success('Updated CHANGELOG.md');
  } catch (error) {
    logger.error('Failed to update changelog', error);
    throw error;
  }
}

module.exports = {
  updateChangelog
}; 