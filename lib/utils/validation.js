const semver = require('semver');

function validateBranchName(name) {
  if (!name) {
    return 'Branch name is required';
  }
  if (!/^[a-z0-9-]+$/.test(name)) {
    return 'Branch name must contain only lowercase letters, numbers, and hyphens';
  }
  return true;
}

function validateVersion(version) {
  if (!semver.valid(version)) {
    return 'Invalid version number. Please use semantic versioning (e.g., 1.0.0, 1.1.0-alpha.1)';
  }
  return true;
}

module.exports = {
  validateBranchName,
  validateVersion
}; 