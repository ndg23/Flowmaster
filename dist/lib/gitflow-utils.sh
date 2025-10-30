#!/bin/bash

# GitFlow Utils Module
# Contains common utility functions for GitFlow operations

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Function to display error messages and exit
error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
    if [[ "$2" != "no_exit" ]]; then
        exit 1
    fi
}

# Function to display success messages
success() {
    echo -e "${GREEN}SUCCESS: $1${NC}"
}

# Function to display info messages
info() {
    echo -e "${BLUE}INFO: $1${NC}"
}

# Function to display warning messages
warning() {
    echo -e "${YELLOW}WARNING: $1${NC}"
}

# Function to validate branch name format
validate_branch_name() {
    local branch=$1
    local prefix=$2

    # Check if branch name follows convention: feature/name
    if [[ ! $branch =~ ^$prefix/[a-z0-9-]+$ ]]; then
        error "Branch name must follow pattern: $prefix/name"
    fi
}

# Function to ensure clean work tree
ensure_clean_work_tree() {
    if ! git diff-index --quiet HEAD --; then
        error "Working tree has uncommitted changes. Please commit or stash them first." "no_exit"
        echo -e "${YELLOW}Would you like to create a commit now? [y/N]${NC}"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            create_commit
            return $?
        fi
        return 1
    fi
    return 0
}

# Function to check git repository
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        error "Not a git repository. Would you like to initialize one? [y/N]" "no_exit"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            git init
            echo -e "${GREEN}Git repository initialized.${NC}"
            return 0
        fi
        return 1
    fi
    return 0
}

# Function to check remote connection
check_remote_connection() {
    # Get the remote URL
    local remote_url=$(git config --get remote.origin.url)

    # If no remote URL is set, prompt to add one
    if [[ -z "$remote_url" ]]; then
        error "No remote repository configured. Would you like to add one? [y/N]" "no_exit"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            echo -e "\n${YELLOW}Enter HTTPS repository URL:${NC}"
            echo -e "Example: https://gitlab.com/username/repository.git"
            read -r repo_url
            git remote add origin "$repo_url"
            success "Remote repository added"
            return 0
        fi
        return 1
    fi

    # Test connection using HTTPS
    if ! git ls-remote --quiet origin &>/dev/null; then
        error "Failed to connect to remote repository. Please check your:" "no_exit"
        echo -e "1. Internet connection"
        echo -e "2. Repository URL: $remote_url"
        echo -e "3. Git credentials"

        echo -e "\n${YELLOW}Would you like to see troubleshooting steps? [y/N]${NC}"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            echo -e "\n${BLUE}HTTPS Troubleshooting Steps:${NC}"
            echo -e "1. Verify your repository URL:"
            echo -e "   git remote -v"
            echo -e "2. Configure Git credentials:"
            echo -e "   git config --global credential.helper store"
            echo -e "3. Update remote URL if needed:"
            echo -e "   git remote set-url origin https://gitlab.com/username/repository.git"
            echo -e "4. Ensure you have access to the repository\n"
            read -p "Press Enter to continue..."
        fi
        return 1
    fi
    return 0
}

# Function to ensure repository is properly configured
check_repository_config() {
    # Check if user.name and user.email are configured
    if [[ -z "$(git config user.name)" ]] || [[ -z "$(git config user.email)" ]]; then
        error "Git user.name or user.email not configured. Would you like to configure them now? [y/N]" "no_exit"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            echo -e "\n${YELLOW}Enter your name:${NC}"
            read -r git_name
            echo -e "\n${YELLOW}Enter your email:${NC}"
            read -r git_email
            git config --global user.name "$git_name"
            git config --global user.email "$git_email"
            success "Git configuration updated"
            return 0
        fi
        return 1
    fi
    return 0
}

# Function to ensure develop branch exists
ensure_develop_branch() {
    # Check if develop branch exists locally
    if ! git show-ref --verify --quiet refs/heads/develop; then
        info "Develop branch doesn't exist. Creating it..."

        # Check if main/master branch exists
        local main_branch="main"
        if git show-ref --verify --quiet refs/heads/master; then
            main_branch="master"
        fi

        # Create develop from main/master if it exists
        if git show-ref --verify --quiet refs/heads/$main_branch; then
            git checkout $main_branch || error "Failed to checkout $main_branch branch"
            git pull origin $main_branch || warning "Failed to pull latest $main_branch changes"
            git checkout -b develop || error "Failed to create develop branch"
            git push -u origin develop || warning "Failed to push develop branch"
            success "Created develop branch from $main_branch"
        else
            # Create develop as first branch
            git checkout --orphan develop || error "Failed to create develop branch"
            git reset --hard || error "Failed to reset develop branch"
            git commit --allow-empty -m "chore: Initialize develop branch" || error "Failed to create initial commit"
            git push -u origin develop || warning "Failed to push develop branch"
            success "Initialized new develop branch"
        fi
    fi

    # Ensure we're on develop branch
    git checkout develop || error "Failed to checkout develop branch"
    git pull origin develop || warning "Failed to pull latest develop changes"
}

# Function to handle git errors
handle_git_error() {
    local error_msg=$1
    local action=$2

    if [[ $error_msg =~ "refusing to merge unrelated histories" ]]; then
        error "Les historiques des branches sont différents." "no_exit"
        echo -e "\n${YELLOW}Options disponibles :${NC}"
        echo -e "1) Forcer le merge avec --allow-unrelated-histories"
        echo -e "2) Annuler l'opération"
        read -p "Choisissez une option [1-2]: " choice

        case $choice in
            1)
                info "Tentative de merge forcé..."
                if ! git merge --allow-unrelated-histories "$action"; then
                    error "Échec du merge forcé. Résolvez les conflits manuellement."
                fi
                ;;
            *)
                error "Opération annulée"
                ;;
        esac
        return 1
    elif [[ $error_msg =~ "Permission denied" ]]; then
        error "Permissions Git insuffisantes. Vérifiez vos droits d'accès." "no_exit"
        echo -e "\n${YELLOW}Suggestions :${NC}"
        echo -e "1) Vérifiez vos clés SSH"
        echo -e "2) Vérifiez vos permissions sur le dépôt"
        echo -e "3) Contactez votre administrateur"
        return 1
    elif [[ $error_msg =~ "cannot lock ref" ]]; then
        error "Impossible de verrouiller la référence. Un autre processus Git est peut-être en cours." "no_exit"
        echo -e "\n${YELLOW}Solutions possibles :${NC}"
        echo -e "1) Attendez quelques instants et réessayez"
        echo -e "2) Vérifiez les processus Git en cours"
        echo -e "3) Supprimez manuellement les fichiers .lock si nécessaire"
        return 1
    elif [[ $error_msg =~ "conflict" ]]; then
        error "Conflits détectés." "no_exit"
        echo -e "\n${YELLOW}Options :${NC}"
        echo -e "1) Résoudre les conflits manuellement"
        echo -e "2) Annuler le merge"
        read -p "Choisissez une option [1-2]: " choice

        case $choice in
            1)
                info "Résolvez les conflits puis utilisez:"
                echo -e "git add <fichiers>"
                echo -e "git commit -m 'resolve conflicts'"
                ;;
            *)
                git merge --abort
                error "Merge annulé"
                ;;
        esac
        return 1
    fi

    # Erreur générique
    error "Une erreur Git s'est produite: $error_msg"
    return 1
}

# Function to safely execute git commands
safe_git_command() {
    local command=$1
    local error_context=$2
    local output

    # Exécute la commande et capture la sortie et l'erreur
    if ! output=$(eval "$command" 2>&1); then
        handle_git_error "$output" "$error_context"
        return 1
    fi
    return 0
}

# Function to get current version
get_current_version() {
    # Try to get the latest tag
    local latest_tag=$(git describe --tags --abbrev=0 2>/dev/null)
    if [ -z "$latest_tag" ]; then
        echo "0.0.0"
    else
        # Remove 'v' prefix if present
        echo "${latest_tag#v}"
    fi
}