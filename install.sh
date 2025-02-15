#!/bin/bash

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default installation paths
INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="flowmaster"
TEMP_DIR="/tmp/flowmaster"
REPO_URL="https://github.com/ndg23/Flowmaster.git"

# Function to display error messages
error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
    exit 1
}

# Function to display success messages
success() {
    echo -e "${GREEN}SUCCESS: $1${NC}"
}

# Function to display info messages
info() {
    echo -e "${BLUE}INFO: $1${NC}"
}

# Function to get latest version
get_latest_version() {
    git ls-remote --tags --refs "$REPO_URL" | \
    awk -F'/' '{print $3}' | \
    sed 's/^v//' | \
    sort -t. -k1,1n -k2,2n -k3,3n | \
    tail -n1
}

# Function to get current version
get_current_version() {
    if [ -f "$INSTALL_DIR/$SCRIPT_NAME" ]; then
        grep "VERSION=" "$INSTALL_DIR/$SCRIPT_NAME" | cut -d'"' -f2
    else
        echo "0.0.0"
    fi
}

# Function to install or upgrade
install_or_upgrade() {
    local force=$1
    local current_version=$(get_current_version)
    local latest_version=$(get_latest_version)
    
    if [ "$force" != "force" ] && [ "$current_version" = "$latest_version" ]; then
        info "Vous avez déjà la dernière version (v$current_version)"
        return 0
    fi
    
    info "Installation de la version v$latest_version..."
    
    # Create and clean temporary directory
    rm -rf "$TEMP_DIR" 2>/dev/null
    mkdir -p "$TEMP_DIR" || error "Failed to create temporary directory"
    
    # Clone the latest version
    info "Téléchargement de la dernière version..."
    if ! git clone --depth 1 --branch "v$latest_version" "$REPO_URL" "$TEMP_DIR" 2>/dev/null; then
        error "Failed to download latest version"
    fi
    
    # Install the script
    info "Installation des fichiers..."
    cp "$TEMP_DIR/gitflow.sh" "$INSTALL_DIR/$SCRIPT_NAME" || \
        error "Failed to install script"
    chmod +x "$INSTALL_DIR/$SCRIPT_NAME" || \
        error "Failed to set executable permissions"
    
    # Set up aliases
    info "Configuration des alias..."
    echo "alias fm='flowmaster'" | sudo tee /etc/profile.d/flowmaster.sh >/dev/null
    chmod +x /etc/profile.d/flowmaster.sh
    
    # Clean up
    rm -rf "$TEMP_DIR"
    
    success "FlowMaster v$latest_version a été installé avec succès! 🎉"
}

# Check if running with sudo/root permissions
if [ "$EUID" -ne 0 ]; then
    error "Please run this script with sudo permissions"
fi

# Check if git is installed
if ! command -v git &> /dev/null; then
    error "Git is not installed. Please install git first."
fi

# Handle upgrade command
if [ "$1" = "upgrade" ]; then
    info "Recherche de mises à jour..."
    install_or_upgrade "force"
else
    install_or_upgrade
fi

# Install bash completion
if [ -d "/etc/bash_completion.d" ]; then
    info "Installing bash completion..."
    if [ -f "$TEMP_DIR/completion/flowmaster-completion.bash" ]; then
        cp "$TEMP_DIR/completion/flowmaster-completion.bash" "/etc/bash_completion.d/" || \
            error "Failed to install bash completion"
    fi
fi

echo
echo -e "${YELLOW}To start using Flowmaster, either:${NC}"
echo -e "1. Run ${GREEN}exec bash${NC} to reload your shell"
echo -e "2. Or restart your terminal"
echo
echo -e "${BLUE}You can then use Flowmaster with:${NC}"
echo -e "  ${GREEN}flowmaster${NC} or ${GREEN}fm${NC}"
echo
echo -e "${BLUE}Branch Naming Convention:${NC}"
echo -e "  ${GREEN}prefix/type/ticket/description${NC}"
echo
echo -e "${BLUE}Where:${NC}"
echo -e "• ${YELLOW}prefix${NC}      : feature, hotfix, release"
echo -e "• ${YELLOW}type${NC}        : The type of change you're making:"
echo -e "    ${GREEN}feat${NC}     : New feature"
echo -e "    ${GREEN}fix${NC}      : Bug fix"
echo -e "    ${GREEN}docs${NC}     : Documentation changes"
echo -e "    ${GREEN}style${NC}    : Code style changes (formatting, etc.)"
echo -e "    ${GREEN}refactor${NC} : Code refactoring"
echo -e "    ${GREEN}perf${NC}     : Performance improvements"
echo -e "    ${GREEN}test${NC}     : Adding or updating tests"
echo -e "    ${GREEN}chore${NC}    : Maintenance tasks"
echo -e "• ${YELLOW}ticket${NC}      : Your ticket ID (e.g., JIRA-123)"
echo -e "• ${YELLOW}description${NC}  : Brief description in kebab-case"
echo
echo -e "${BLUE}Examples:${NC}"
echo -e "  ${GREEN}feature/feat/JIRA-123/add-login-page${NC}"
echo -e "  ${GREEN}hotfix/fix/JIRA-456/fix-security-issue${NC}"
echo -e "  ${GREEN}feature/refactor/JIRA-789/optimize-database-queries${NC}"
echo

# Don't try to reload bashrc as it won't work with sudo
# Instead, instruct the user to restart their shell 