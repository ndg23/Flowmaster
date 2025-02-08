#!/bin/bash

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default installation paths
INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="gitflow"

# Function to display error messages
error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
    exit 1
}

# Function to display success messages
success() {
    echo -e "${GREEN}SUCCESS: $1${NC}"
}

# Function to display warning messages
warning() {
    echo -e "${YELLOW}WARNING: $1${NC}"
}

# Check if running with sudo/root permissions
if [ "$EUID" -ne 0 ]; then
    error "Please run this script with sudo permissions"
fi

echo "🗑️  Uninstalling GitFlow..."

# Remove the main script
if [ -f "$INSTALL_DIR/$SCRIPT_NAME" ]; then
    rm "$INSTALL_DIR/$SCRIPT_NAME" || error "Failed to remove $INSTALL_DIR/$SCRIPT_NAME"
    success "Removed $INSTALL_DIR/$SCRIPT_NAME"
else
    warning "GitFlow script not found in $INSTALL_DIR"
fi

# Remove git aliases if they exist
if git config --global --get alias.flow >/dev/null; then
    git config --global --unset alias.flow
    success "Removed git flow alias"
    
    # Unset the alias in the current shell
    unalias flow 2>/dev/null || true
    success "Removed flow alias from current shell"
else
    warning "Git flow alias not found"
fi

# Remove completion script if it exists
COMPLETION_DIR="/etc/bash_completion.d"
if [ -f "$COMPLETION_DIR/gitflow-completion.bash" ]; then
    rm "$COMPLETION_DIR/gitflow-completion.bash" || error "Failed to remove completion script"
    success "Removed completion script"
else
    warning "Completion script not found"
fi

# Clean up any temporary files
if [ -d "/tmp/gitflow" ]; then
    rm -rf "/tmp/gitflow"
    success "Cleaned up temporary files"
fi

echo
success "GitFlow has been successfully uninstalled! 👋"
echo
echo -e "${YELLOW}Note: Your git repositories and configurations remain unchanged.${NC}"
echo -e "${YELLOW}Please run 'exec bash' or restart your terminal to complete the uninstallation.${NC}"
echo

# Don't try to reload bashrc as it won't work with sudo
# Instead, instruct the user to restart their shell 