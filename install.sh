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
    # Get all branches and sort by commit date
    local latest_branch=$(git ls-remote --heads "$REPO_URL" | \
                         awk -F'/' '{print $3}' | \
                         grep -E '^(develop|main|master)$' | \
                         while read branch; do
                             echo "$(git ls-remote -h "$REPO_URL" "$branch" | cut -f1) $branch"
                         done | \
                         sort -r | \
                         head -n1 | \
                         cut -d' ' -f2)
    
    # Get version from the most recent branch
    if [ -n "$latest_branch" ]; then
        # Try to get version from package.json or similar file
        local version=$(git ls-remote --refs "$REPO_URL" "$latest_branch" | \
                       git archive --remote="$REPO_URL" "$latest_branch" VERSION 2>/dev/null | \
                       tar -xO 2>/dev/null || echo "")
        
        if [ -z "$version" ]; then
            # If no version file, use latest tag on that branch
            version=$(git ls-remote --tags --refs "$REPO_URL" | \
                     awk -F'/' '{print $3}' | \
                     sed 's/^v//' | \
                     sort -t. -k1,1n -k2,2n -k3,3n | \
                     tail -n1)
        fi
        
        echo "$version"
    else
        error "Impossible de déterminer la dernière version"
        return 1
    fi
}

# Function to get current version
get_current_version() {
    if [ -f "$INSTALL_DIR/$SCRIPT_NAME" ]; then
        grep "VERSION=" "$INSTALL_DIR/$SCRIPT_NAME" | cut -d'"' -f2
    else
        echo "0.0.0"
    fi
}

# Function to suggest next version
suggest_next_version() {
    local current_version=$1
    local versions=($(git ls-remote --tags --refs "$REPO_URL" | \
                      awk -F'/' '{print $3}' | \
                      sed 's/^v//' | \
                      sort -t. -k1,1n -k2,2n -k3,3n))
    
    echo -e "\n${YELLOW}Versions disponibles :${NC}"
    echo -e "${BLUE}Versions actuelles :${NC}"
    for v in "${versions[@]}"; do
        echo -e "  ${GREEN}$v${NC}"
    done
    
    # Parse current version
    if [[ $current_version =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)(-((alpha|beta|rc)\.([0-9]+)))?$ ]]; then
        local major="${BASH_REMATCH[1]}"
        local minor="${BASH_REMATCH[2]}"
        local patch="${BASH_REMATCH[3]}"
        local prerelease="${BASH_REMATCH[5]}"
        local prerelease_num="${BASH_REMATCH[6]}"
        
        echo -e "\n${BLUE}Suggestions pour la prochaine version :${NC}"
        
        # Suggest next versions
        if [ -z "$prerelease" ]; then
            # For release versions
            echo -e "1) ${GREEN}$major.$minor.$((patch+1))${NC} (patch)"
            echo -e "2) ${GREEN}$major.$((minor+1)).0${NC} (minor)"
            echo -e "3) ${GREEN}$((major+1)).0.0${NC} (major)"
            echo -e "4) ${GREEN}$major.$minor.$patch-alpha.1${NC} (nouvelle alpha)"
            echo -e "5) ${YELLOW}Version personnalisée${NC}"
        else
            # For pre-release versions
            case "$prerelease" in
                "alpha")
                    echo -e "1) ${GREEN}$major.$minor.$patch-alpha.$((prerelease_num+1))${NC} (next alpha)"
                    echo -e "2) ${GREEN}$major.$minor.$patch-beta.1${NC} (start beta)"
                    echo -e "3) ${GREEN}$major.$minor.$patch${NC} (release finale)"
                    ;;
                "beta")
                    echo -e "1) ${GREEN}$major.$minor.$patch-beta.$((prerelease_num+1))${NC} (next beta)"
                    echo -e "2) ${GREEN}$major.$minor.$patch-rc.1${NC} (start rc)"
                    echo -e "3) ${GREEN}$major.$minor.$patch${NC} (release finale)"
                    ;;
                "rc")
                    echo -e "1) ${GREEN}$major.$minor.$patch-rc.$((prerelease_num+1))${NC} (next rc)"
                    echo -e "2) ${GREEN}$major.$minor.$patch${NC} (release finale)"
                    ;;
            esac
            echo -e "4) ${YELLOW}Version personnalisée${NC}"
        fi
        
        # Get user choice
        while true; do
            read -p "Choisissez une option: " choice
            case "$choice" in
                1|2|3)
                    if [ -z "$prerelease" ]; then
                        case "$choice" in
                            1) echo "$major.$minor.$((patch+1))";;
                            2) echo "$major.$((minor+1)).0";;
                            3) echo "$((major+1)).0.0";;
                        esac
                    else
                        case "$prerelease" in
                            "alpha")
                                case "$choice" in
                                    1) echo "$major.$minor.$patch-alpha.$((prerelease_num+1))";;
                                    2) echo "$major.$minor.$patch-beta.1";;
                                    3) echo "$major.$minor.$patch";;
                                esac
                                ;;
                            "beta")
                                case "$choice" in
                                    1) echo "$major.$minor.$patch-beta.$((prerelease_num+1))";;
                                    2) echo "$major.$minor.$patch-rc.1";;
                                    3) echo "$major.$minor.$patch";;
                                esac
                                ;;
                            "rc")
                                case "$choice" in
                                    1) echo "$major.$minor.$patch-rc.$((prerelease_num+1))";;
                                    2) echo "$major.$minor.$patch";;
                                esac
                                ;;
                        esac
                    fi
                    return 0
                    ;;
                4|5)
                    read -p "Entrez la version personnalisée (format X.Y.Z[-prerelease.N]): " custom_version
                    if [[ $custom_version =~ ^[0-9]+\.[0-9]+\.[0-9]+(-((alpha|beta|rc)\.[0-9]+))?$ ]]; then
                        echo "$custom_version"
                        return 0
                    else
                        error "Format de version invalide"
                    fi
                    ;;
                *)
                    echo -e "${RED}Option invalide${NC}"
                    ;;
            esac
        done
    else
        error "Version actuelle invalide: $current_version"
    fi
}

# Function to install or upgrade
install_or_upgrade() {
    local force=$1
    local current_version=$(get_current_version)
    
    if [ "$force" = "force" ]; then
        local latest_version=$(suggest_next_version "$current_version")
    else
        local latest_version=$(get_latest_version)
        if [ "$current_version" = "$latest_version" ]; then
            info "Vous avez déjà la dernière version (v$current_version)"
            return 0
        fi
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
    
    # Set up aliases based on OS
    info "Configuration des alias..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS - Add to .zshrc if it exists, otherwise .bash_profile
        if [ -f "$HOME/.zshrc" ]; then
            echo "alias fm='flowmaster'" >> "$HOME/.zshrc"
            info "Alias ajouté à ~/.zshrc"
        else
            echo "alias fm='flowmaster'" >> "$HOME/.bash_profile"
            info "Alias ajouté à ~/.bash_profile"
        fi
    else
        # Linux - Use /etc/profile.d/
        mkdir -p /etc/profile.d
        echo "alias fm='flowmaster'" | sudo tee /etc/profile.d/flowmaster.sh >/dev/null
        chmod +x /etc/profile.d/flowmaster.sh
    fi
    
    # Clean up
    rm -rf "$TEMP_DIR"
    
    success "FlowMaster v$latest_version a été installé avec succès! 🎉"
    
    # Show appropriate reload command based on OS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if [ -f "$HOME/.zshrc" ]; then
            echo -e "\n${YELLOW}Pour activer l'alias, exécutez :${NC}"
            echo -e "${GREEN}source ~/.zshrc${NC}"
        else
            echo -e "\n${YELLOW}Pour activer l'alias, exécutez :${NC}"
            echo -e "${GREEN}source ~/.bash_profile${NC}"
        fi
    else
        echo -e "\n${YELLOW}Pour activer l'alias, exécutez :${NC}"
        echo -e "${GREEN}source /etc/profile.d/flowmaster.sh${NC}"
    fi
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