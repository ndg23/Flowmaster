#!/bin/bash

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default installation paths
INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="gitflow"
TEMP_DIR="/tmp/gitflow"
REPO_URL="https://github.com/yourusername/gitflow.git"  # Update this with your actual repo URL

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

# Check if running with sudo/root permissions
if [ "$EUID" -ne 0 ]; then
    error "Please run this script with sudo permissions"
fi

# Check if git is installed
if ! command -v git &> /dev/null; then
    error "Git is not installed. Please install git first."
fi

echo "🚀 Installing GitFlow..."

# Create and clean temporary directory
rm -rf "$TEMP_DIR" 2>/dev/null
mkdir -p "$TEMP_DIR" || error "Failed to create temporary directory"

# Clone the latest version
info "Downloading latest version..."
if ! git clone --depth 1 "$REPO_URL" "$TEMP_DIR" 2>/dev/null; then
    error "Failed to download latest version. Please check your internet connection."
fi

# Copy the script to installation directory
info "Installing GitFlow..."
cp "$TEMP_DIR/gitflow.sh" "$INSTALL_DIR/$SCRIPT_NAME" || error "Failed to install script"
chmod +x "$INSTALL_DIR/$SCRIPT_NAME" || error "Failed to make script executable"

# Install bash completion
if [ -d "/etc/bash_completion.d" ]; then
    info "Installing bash completion..."
    if [ -f "$TEMP_DIR/completion/gitflow-completion.bash" ]; then
        cp "$TEMP_DIR/completion/gitflow-completion.bash" "/etc/bash_completion.d/" || \
            error "Failed to install bash completion"
    fi
fi

# Set up git alias
info "Setting up git alias..."
git config --global alias.flow '!gitflow' || warning "Failed to set up git alias"

# Clean up
rm -rf "$TEMP_DIR"

echo
success "GitFlow has been successfully installed! 🎉"
echo
echo -e "${YELLOW}To start using GitFlow, either:${NC}"
echo -e "1. Run ${GREEN}exec bash${NC} to reload your shell"
echo -e "2. Or restart your terminal"
echo
echo -e "${BLUE}You can then use GitFlow with:${NC}"
echo -e "  ${GREEN}gitflow${NC} or ${GREEN}git flow${NC}"
echo

# Don't try to reload bashrc as it won't work with sudo
# Instead, instruct the user to restart their shell 