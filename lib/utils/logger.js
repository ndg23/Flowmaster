const chalk = require('chalk');

class Logger {
  info(message) {
    console.log(chalk.blue(`INFO: ${message}`));
  }

  success(message) {
    console.log(chalk.green(`SUCCESS: ${message}`));
  }

  error(message, error = null) {
    console.error(chalk.red(`ERROR: ${message}`));
    if (error) {
      console.error(chalk.red(error.stack));
    }
  }

  warning(message) {
    console.warn(chalk.yellow(`WARNING: ${message}`));
  }
}

module.exports = new Logger(); 