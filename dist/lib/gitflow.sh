#!/bin/bash

# GitFlow Main Script
# Modular GitFlow implementation using separate modules

# At the beginning of the file, add version
VERSION="1.1.2-alpha.2"

# Source all modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load modules
source "$SCRIPT_DIR/gitflow-utils.sh"
source "$SCRIPT_DIR/gitflow-feature.sh"
source "$SCRIPT_DIR/gitflow-release.sh"
source "$SCRIPT_DIR/gitflow-hotfix.sh"
source "$SCRIPT_DIR/gitflow-commit.sh"
source "$SCRIPT_DIR/gitflow-ui.sh"

# Function to show status
show_status() {
    echo
    echo -e "${BOLD}Repository Status${NC}"
    echo -e "${CYAN}═══════════════════════════════════${NC}"

    # Show current branch
    local current_branch=$(git branch --show-current 2>/dev/null || echo 'Not a git repository')
    echo -e "${BLUE}Current branch:${NC} $current_branch"

    # Show current version
    local current_version=$(get_current_version)
    echo -e "${BLUE}Current version:${NC} $current_version"

    # Show recent commits
    echo
    echo -e "${YELLOW}Recent commits:${NC}"
    git log --oneline -5 2>/dev/null || echo "No commits yet"

    # Show branch status
    echo
    echo -e "${YELLOW}Branch status:${NC}"
    git status --porcelain --branch 2>/dev/null || echo "Not a git repository"

    echo
}

# Function to check for updates (placeholder)
check_for_updates() {
    info "Checking for updates..."
    warning "Update check not implemented yet"
}

# Function to get feature name (placeholder - should be implemented in UI)
get_feature_name() {
    echo -e "${YELLOW}Enter feature name:${NC}"
    read -p "> " branch_name
    branch_name="feature/$branch_name"
}

# Function to get version (placeholder - should be implemented in UI)
get_version() {
    echo -e "${YELLOW}Enter version:${NC}"
    read -p "> " version
}

# Function to initialize project (placeholder - basic implementation)
init_project() {
    info "Initializing GitFlow project..."

    # Check git repo
    check_git_repo || return 1

    # Configure repository
    check_repository_config || return 1

    # Ensure develop branch
    ensure_develop_branch || return 1

    # Create basic files
    if [ ! -f "README.md" ]; then
        echo "# Project

This project uses GitFlow workflow managed by FlowMaster CLI.
" > README.md
        git add README.md
        git commit -m "docs: add README.md"
    fi

    if [ ! -f "CHANGELOG.md" ]; then
        echo "# 📝 Journal des modifications | Changelog | Registro de cambios

## [Unreleased]
### Ajouté
### Modifié
### Corrigé
### Supprimé
" > CHANGELOG.md
        git add CHANGELOG.md
        git commit -m "docs: add CHANGELOG.md"
    fi

    success "GitFlow project initialized successfully"
}

# Function to reorganize project (placeholder - basic implementation)
reorganize_project() {
    info "Reorganizing project to follow GitFlow..."

    # Check git repo
    check_git_repo || return 1

    # Configure repository
    check_repository_config || return 1

    # Ensure develop branch
    ensure_develop_branch || return 1

    success "Project reorganized successfully"
}

# Main function to process command-line arguments
main() {
    if [ $# -eq 0 ]; then
        # No arguments, run interactive menu
        run_interactive_menu
    else
        # Process command
        case "$1" in
            "init")
                init_project
                ;;
            "reorganize")
                reorganize_project
                ;;
            "feature")
                if [ "$2" = "start" ] && [ -n "$3" ]; then
                    branch_name="feature/$3"
                    start_feature "$branch_name"
                elif [ "$2" = "finish" ]; then
                    finish_feature
                else
                    error "Invalid feature command. Usage: feature start <name> or feature finish"
                fi
                ;;
            "release")
                if [ "$2" = "start" ]; then
                    start_release
                elif [ "$2" = "finish" ]; then
                    finish_release
                else
                    error "Invalid release command. Usage: release start or release finish"
                fi
                ;;
            "hotfix")
                if [ "$2" = "start" ] && [ -n "$3" ]; then
                    start_hotfix "$3"
                elif [ "$2" = "finish" ]; then
                    finish_hotfix
                else
                    error "Invalid hotfix command. Usage: hotfix start <version> or hotfix finish"
                fi
                ;;
            "commit")
                create_commit
                ;;
            "status")
                show_status
                ;;
            "config")
                # Handle config options
                echo "Config options: $2"
                ;;
            *)
                error "Unknown command: $1"
                ;;
        esac
    fi
}

# Execute main function with all arguments
main "$@" 