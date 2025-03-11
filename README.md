# 🌊 FlowMaster CLI

A powerful and intuitive command-line tool for managing Git workflows with GitFlow methodology.

## ✨ Features

- 🎯 Interactive menu-driven interface
- 🌿 Feature branch management
- 🚀 Release management with pre-release support (alpha, beta, rc)
- 🔧 Hotfix handling
- 📝 Conventional commit creation
- 📊 Repository status monitoring
- 📘 Built-in workflow documentation
- 🔄 Automated changelog generation

## 🎯 Version Format

- Production: `X.Y.Z` (e.g., 1.0.0)
- Pre-release: `X.Y.Z-stage.N` where stage is:
  - `alpha.N`: Internal testing
  - `beta.N`: External testing
  - `rc.N`: Release candidate

## 🚀 Quick Start

1. Install FlowMaster:

```bash
npm install -g flowmaster-cli
```

2. Initialize a new project:

```bash
flowmaster init
```

This will:
- Set up Git repository if needed
- Create main and develop branches
- Set up basic project structure
- Configure Git hooks for commit message validation
- Create initial files (README.md, CHANGELOG.md, .gitignore, etc.)

3. Start the interactive menu:

```bash
flowmaster
```

4. For existing projects, reorganize to follow GitFlow:

```bash
flowmaster reorganize
```

This will:
- Analyze your current repository structure
- Set up main and develop branches if they don't exist
- Help rename branches to follow GitFlow naming conventions
- Configure Git hooks for commit message validation
- Create CHANGELOG.md if it doesn't exist

## 🚀 Installation

Pour installer FlowMaster CLI, exécutez la commande suivante :

```bash
npm install -g flowmaster-cli
```

Après l'installation, vous pouvez vérifier la version installée avec :

```bash
flowmaster --version
```

### Prérequis
- Node.js ≥ 12
- Git
- Permissions sudo (pour l'installation globale)

### Résolution des problèmes

Si vous rencontrez des erreurs de permissions :
```bash
# Donner les permissions d'exécution
sudo chmod +x $(which flowmaster)
sudo chmod +x $(which fm)

# Ou réinstaller avec sudo
sudo npm uninstall -g flowmaster-cli
sudo npm install -g flowmaster-cli
```

## 📝 Changelog Management

FlowMaster CLI automatically manages your project's changelog:

- 🔄 Automatically updates CHANGELOG.md when creating commits with conventional commit format
- 📊 Organizes changes into categories (Added, Modified, Fixed, Removed)
- 🚀 Finalizes changelog entries when releasing versions
- 💅 Maintains consistent formatting with emojis for better readability

### Changelog Scripts

FlowMaster includes scripts to help maintain your changelog:

```bash
# Fix and standardize the format of your changelog
npm run fix-changelog

# Standardize the format of your changelog
npm run standardize-changelog
```

## Contribuer

Nous accueillons les contributions ! Veuillez consulter notre [guide de contribution](CONTRIBUTING.md) pour plus d'informations sur la façon de contribuer à ce projet.

Veuillez également lire notre [code de conduite](CODE_OF_CONDUCT.md) pour vous assurer que notre communauté reste accueillante et respectueuse.

## 🧪 Testing

FlowMaster CLI includes comprehensive tests to ensure functionality works as expected. To run the tests:

```bash
# Run all tests
npm test

# Run specific test suites
npm run test:init        # Test initialization functionality
npm run test:reorganize  # Test project reorganization
npm run test:changelog   # Test changelog management

# Run tests with coverage report
npm run test:coverage
```

When contributing new features, please include tests to verify your implementation works correctly.

## 💖 Sponsorship

FlowMaster CLI is an open-source project that relies on your support. If you find this tool valuable, please consider [becoming a sponsor](SPONSORS.md)!

[Become a sponsor](SPONSORS.md) and have your logo here!

[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://paypal.me/marvinndg?country.x=SN&locale.x=fr_XC)
[![Sponsors](https://img.shields.io/github/sponsors/ndg23?label=Sponsors&style=social)](https://github.com/sponsors/ndg23)

<form action="https://www.paypal.com/cgi-bin/webscr" method="post" target="_top">
<input type="hidden" name="cmd" value="_s-xclick">
<input type="hidden" name="hosted_button_id" value="VOTRE_BUTTON_ID">
<input type="image" src="https://www.paypalobjects.com/fr_FR/i/btn/btn_subscribeCC_LG.gif" border="0" name="submit" alt="PayPal - The safer, easier way to pay online!">
</form>
