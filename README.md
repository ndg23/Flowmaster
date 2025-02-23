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

3. Start the interactive menu:

```bash
flowmaster
```

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

## 📚 Documentation

For more detailed information on how to use FlowMaster, please refer to the [documentation](https://flowmaster-cli.readthedocs.io).

## Contribuer

Nous accueillons les contributions ! Veuillez consulter notre [guide de contribution](CONTRIBUTING.md) pour plus d'informations sur la façon de contribuer à ce projet.

Veuillez également lire notre [code de conduite](CODE_OF_CONDUCT.md) pour vous assurer que notre communauté reste accueillante et respectueuse.
