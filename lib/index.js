const feature = require('./commands/feature');
const release = require('./commands/release');
const hotfix = require('./commands/hotfix');
const git = require('./utils/git');
const logger = require('./utils/logger');

module.exports = {
  commands: {
    feature,
    release,
    hotfix
  },
  utils: {
    git,
    logger
  }
}; 