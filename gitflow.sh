#!/bin/bash

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Commit types
COMMIT_TYPES=(
    "feat:     ✨ A new feature"
    "fix:      🐛 A bug fix"
    "docs:     📚 Documentation only changes"
    "style:    💎 Changes that do not affect the meaning of the code"
    "refactor: ♻️  A code change that neither fixes a bug nor adds a feature"
    "perf:     ⚡️ A code change that improves performance"
    "test:     🚨 Adding missing tests or correcting existing tests"
    "build:    📦 Changes that affect the build system or external dependencies"
    "ci:       👷 Changes to our CI configuration files and scripts"
    "chore:    🔧 Other changes that don't modify src or test files"
    "revert:   ⏪️ Reverts a previous commit"
)

# Help message for workflow steps
WORKFLOW_HELP="
${BOLD}🔄 GitFlow Workflow Steps${NC}

${BLUE}Step 1: Feature Development${NC}
• Start feature branch from develop
• Make changes and commit
• Finish feature by merging back to develop

${BLUE}Step 2: Release Process${NC}
• Start release from develop with version (e.g. 1.0.0-alpha.1)
• Test and fix bugs
• Progress through pre-release stages:
  ${CYAN}α) alpha${NC} - Internal testing
  ${CYAN}β) beta${NC}  - External testing
  ${CYAN}γ) rc${NC}    - Release candidate
• Finish release:
  - Pre-releases merge to develop only
  - Final release merges to both main and develop

${BLUE}Step 3: Hotfix Process${NC}
• Start hotfix from main for urgent fixes
• Fix critical bugs
• Finish hotfix by merging to both main and develop

${YELLOW}Version Format:${NC} MAJOR.MINOR.PATCH[-prerelease]
Example: 1.0.0-alpha.1 → 1.0.0-beta.1 → 1.0.0-rc.1 → 1.0.0
"

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
    
    # Check if branch name follows convention: type/JIRA-123/description
    if [[ ! $branch =~ ^$prefix/(feat|fix|chore|docs|style|refactor|perf|test)/(JIRA|PROJECT)-[0-9]+/[a-z0-9-]+$ ]]; then
        error "Branch name must follow pattern: $prefix/type/JIRA-123/description"
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

# Function to start a new feature
start_feature() {
    check_git_repo || return 1
    ensure_clean_work_tree || return 1
    check_remote_connection || return 1
    
    local branch_name=$1
    validate_branch_name "$branch_name" "feature" || return 1
    
    info "Starting new feature branch: $branch_name"
    git checkout develop || {
        error "Develop branch doesn't exist. Would you like to create it? [y/N]" "no_exit"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            git checkout -b develop
            git push -u origin develop
        else
            return 1
        fi
    }
    git pull origin develop || error "Failed to pull latest develop changes"
    git checkout -b "$branch_name" || error "Failed to create new branch"
    success "Successfully created feature branch: $branch_name"
}

# Function to finish a feature
finish_feature() {
    ensure_clean_work_tree || return 1
    check_remote_connection || return 1
    
    local current_branch=$(git symbolic-ref --short HEAD)
    validate_branch_name "$current_branch" "feature"
    
    info "Finishing feature branch: $current_branch"
    
    # Update develop branch
    git checkout develop || error "Failed to checkout develop branch"
    git pull origin develop || error "Failed to pull latest develop changes"
    
    # Merge feature branch
    git merge --no-ff "$current_branch" || error "Failed to merge feature branch"
    
    # Push changes
    git push origin develop || error "Failed to push changes to develop"
    
    # Delete feature branch
    git branch -d "$current_branch" || warning "Failed to delete local feature branch"
    git push origin --delete "$current_branch" || warning "Failed to delete remote feature branch"
    
    success "Successfully finished feature: $current_branch"
}

# Function to validate version format
validate_version() {
    local version=$1
    local allow_prerelease=$2
    
    if [[ $allow_prerelease == "true" ]]; then
        if [[ ! $version =~ ^[0-9]+\.[0-9]+\.[0-9]+(-((alpha|beta|rc)\.[0-9]+))?$ ]]; then
            error "Version must follow semantic versioning: X.Y.Z[-prerelease]\nExamples: 1.0.0, 1.1.0-alpha.1, 2.0.0-beta.2, 1.2.0-rc.1"
        fi
    else
        if [[ ! $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            error "Version must follow semantic versioning: X.Y.Z"
        fi
    fi
}

# Function to start a release
start_release() {
    ensure_clean_work_tree || return 1
    check_repository_config || return 1
    check_remote_connection || return 1
    
    local version=$1
    validate_version "$version" "true"
    
    local branch_name="release/v$version"
    
    info "Starting release: $version"
    git checkout develop || error "Failed to checkout develop branch"
    
    # Try to pull with more detailed error handling
    if ! git pull origin develop; then
        error "Failed to pull from develop branch. Please check your:"
        echo -e "1. Internet connection"
        echo -e "2. Remote repository configuration"
        echo -e "3. Branch permissions"
        echo -e "\nRemote configuration:"
        git remote -v
        return 1
    fi
    
    git checkout -b "$branch_name" || error "Failed to create release branch"
    
    # Update version in package.json without git tag
    if [[ $version =~ -(.+)$ ]]; then
        # For pre-release versions, use the full version string
        npm version "$version" --no-git-tag-version || error "Failed to update version in package.json"
    else
        # For stable versions, just update the version
        npm version "$version" --no-git-tag-version || error "Failed to update version in package.json"
    fi
    
    git add package.json package-lock.json
    git commit -m "chore: bump version to $version"
    git push origin "$branch_name"
    
    success "Successfully created release branch: $branch_name"
}

# Function to finish a release
finish_release() {
    ensure_clean_work_tree
    
    local current_branch=$(git symbolic-ref --short HEAD)
    if [[ ! $current_branch =~ ^release/v[0-9]+\.[0-9]+\.[0-9]+(-((alpha|beta|rc)\.[0-9]+))?$ ]]; then
        error "Must be on a release branch: release/vX.Y.Z[-prerelease]"
    fi
    
    local version=${current_branch#release/v}
    
    info "Finishing release: $version"
    
    # For pre-release versions, only merge to develop
    if [[ $version =~ -(.+)$ ]]; then
        info "Pre-release version detected, merging only to develop"
        
        git checkout develop || error "Failed to checkout develop branch"
        git pull origin develop || error "Failed to pull latest develop changes"
        git merge --no-ff "$current_branch" -m "chore: merge pre-release $version to develop" || error "Failed to merge to develop"
        git tag -a "v$version" -m "Pre-release version $version" || error "Failed to create tag"
        
        # Push changes
        git push origin develop "v$version" || error "Failed to push changes"
    else
        # For stable versions, merge to both main and develop
        git checkout main || error "Failed to checkout main branch"
        git pull origin main || error "Failed to pull latest main changes"
        git merge --no-ff "$current_branch" -m "chore: release version $version" || error "Failed to merge to main"
        git tag -a "v$version" -m "Release version $version" || error "Failed to create tag"
        
        git checkout develop || error "Failed to checkout develop branch"
        git pull origin develop || error "Failed to pull latest develop changes"
        git merge --no-ff "$current_branch" -m "chore: merge release $version to develop" || error "Failed to merge to develop"
        
        # Push changes
        git push origin main develop "v$version" || error "Failed to push changes"
    fi
    
    # Delete release branch
    git branch -d "$current_branch" || warning "Failed to delete local release branch"
    git push origin --delete "$current_branch" || warning "Failed to delete remote release branch"
    
    success "Successfully finished release $version"
}

# Function to create a hotfix
start_hotfix() {
    ensure_clean_work_tree
    
    local version=$1
    if [[ ! $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        error "Version must follow semantic versioning: X.Y.Z"
    fi
    
    local branch_name="hotfix/v$version"
    
    info "Starting hotfix: $version"
    git checkout main || error "Failed to checkout main branch"
    git pull origin main || error "Failed to pull latest main changes"
    git checkout -b "$branch_name" || error "Failed to create hotfix branch"
    
    success "Successfully created hotfix branch: $branch_name"
}

# Function to finish a hotfix
finish_hotfix() {
    ensure_clean_work_tree
    
    local current_branch=$(git symbolic-ref --short HEAD)
    if [[ ! $current_branch =~ ^hotfix/v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        error "Must be on a hotfix branch: hotfix/vX.Y.Z"
    fi
    
    local version=${current_branch#hotfix/v}
    
    info "Finishing hotfix: $version"
    
    # Merge to main
    git checkout main || error "Failed to checkout main branch"
    git pull origin main || error "Failed to pull latest main changes"
    git merge --no-ff "$current_branch" -m "fix: release hotfix $version" || error "Failed to merge to main"
    git tag -a "v$version" -m "Hotfix version $version" || error "Failed to create tag"
    
    # Merge back to develop
    git checkout develop || error "Failed to checkout develop branch"
    git pull origin develop || error "Failed to pull latest develop changes"
    git merge --no-ff "$current_branch" -m "fix: merge hotfix $version to develop" || error "Failed to merge to develop"
    
    # Push changes
    git push origin main develop "v$version" || error "Failed to push changes"
    
    # Delete hotfix branch
    git branch -d "$current_branch" || warning "Failed to delete local hotfix branch"
    git push origin --delete "$current_branch" || warning "Failed to delete remote hotfix branch"
    
    success "Successfully finished hotfix $version"
}

# Function to create a commit
create_commit() {
    echo
    echo -e "${BOLD}Create Commit${NC}"
    echo -e "${CYAN}═══════════════════════════════════${NC}"
    
    # Check if there are any changes
    if [ -z "$(git status --porcelain)" ]; then
        echo -e "${RED}No changes to commit!${NC}"
        return 1
    fi

    # Show current changes
    echo
    echo -e "${YELLOW}Current changes:${NC}"
    git status -s
    
    # Ask if user wants to add files
    echo
    echo -e "${YELLOW}Select files to add:${NC}"
    echo -e "  ${BLUE}1)${NC} Add all files"
    echo -e "  ${BLUE}2)${NC} Add specific files"
    echo -e "  ${BLUE}3)${NC} Files already added (skip)"
    echo
    read -p "Enter your choice [1-3]: " add_choice
    
    case $add_choice in
        1)
            git add .
            ;;
        2)
            echo
            echo -e "${YELLOW}Enter file patterns to add (space-separated):${NC}"
            echo -e "${BLUE}Example:${NC} src/*.js test/*.js"
            echo
            read -p "Files to add: " files_to_add
            git add $files_to_add
            ;;
        3)
            # Check if there are staged changes
            if [ -z "$(git diff --cached --name-only)" ]; then
                echo -e "${RED}No staged changes found. Please add files first.${NC}"
                return 1
            fi
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            return 1
            ;;
    esac
    
    # Show staged changes
    echo
    echo -e "${YELLOW}Files to be committed:${NC}"
    git diff --cached --name-status
    
    # Continue with commit type selection
    echo
    echo -e "${YELLOW}Select commit type:${NC}"
    echo
    
    # Display commit types
    for i in "${!COMMIT_TYPES[@]}"; do
        echo -e "  ${BLUE}$((i+1)))${NC} ${COMMIT_TYPES[$i]}"
    done
    echo
    
    # Get commit type
    while true; do
        read -p "Enter commit type number [1-${#COMMIT_TYPES[@]}]: " type_num
        if [[ $type_num =~ ^[0-9]+$ ]] && [ $type_num -ge 1 ] && [ $type_num -le ${#COMMIT_TYPES[@]} ]; then
            break
        fi
        echo -e "${RED}Invalid selection. Please try again.${NC}"
    done
    
    # Extract commit type prefix
    commit_type=$(echo "${COMMIT_TYPES[$((type_num-1))]}" | cut -d: -f1)
    
    # Get scope (optional)
    echo
    echo -e "${YELLOW}Scope (optional, press enter to skip):${NC}"
    read -p "Enter scope: " scope
    
    # Get commit message
    echo
    echo -e "${YELLOW}Commit message:${NC}"
    read -p "Enter message: " message
    
    # Get breaking change info (optional)
    echo
    echo -e "${YELLOW}Breaking changes (optional, press enter to skip):${NC}"
    read -p "Enter breaking changes: " breaking
    
    # Construct commit message
    full_message="$commit_type"
    if [ ! -z "$scope" ]; then
        full_message="$full_message($scope)"
    fi
    full_message="$full_message: $message"
    
    # Add breaking change footer if provided
    if [ ! -z "$breaking" ]; then
        full_message="$full_message

BREAKING CHANGE: $breaking"
    fi
    
    # Create commit
    git commit -m "$full_message"
    
    # Update changelog if this is a feat, fix, or breaking change
    if [[ "$commit_type" == "feat" ]] || [[ "$commit_type" == "fix" ]] || [ ! -z "$breaking" ]; then
        update_changelog "$full_message"
    fi
}

# Function to update changelog
update_changelog() {
    local commit_msg=$1
    local changelog_file="CHANGELOG.md"
    local today=$(date +%Y-%m-%d)
    
    # Create changelog if it doesn't exist
    if [ ! -f "$changelog_file" ]; then
        echo "# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
" > "$changelog_file"
    fi
    
    # Check if we have an Unreleased section
    if ! grep -q "## \[Unreleased\]" "$changelog_file"; then
        sed -i.bak "1a\\
\\
## [Unreleased]\\
" "$changelog_file"
        rm -f "$changelog_file.bak"
    fi
    
    # Determine the section based on commit type
    local section
    if [[ "$commit_msg" == *"BREAKING CHANGE"* ]]; then
        section="### ⚠ BREAKING CHANGES"
    elif [[ "$commit_msg" == feat* ]]; then
        section="### ✨ Features"
    elif [[ "$commit_msg" == fix* ]]; then
        section="### 🐛 Bug Fixes"
    fi
    
    # Add section if it doesn't exist
    if ! grep -q "^$section" "$changelog_file"; then
        sed -i.bak "/## \[Unreleased\]/a\\
\\
$section\\
" "$changelog_file"
        rm -f "$changelog_file.bak"
    fi
    
    # Add commit message to appropriate section
    local entry="- ${commit_msg%%$'\n'*}"
    sed -i.bak "/^$section/a\\
$entry" "$changelog_file"
    rm -f "$changelog_file.bak"
    
    git add "$changelog_file"
}

# Function to finalize changelog for release
finalize_changelog() {
    local version=$1
    local changelog_file="CHANGELOG.md"
    local today=$(date +%Y-%m-%d)
    
    # Replace [Unreleased] with new version
    sed -i.bak "s/## \[Unreleased\]/## [${version}] - ${today}/" "$changelog_file"
    rm -f "$changelog_file.bak"
    
    # Add new Unreleased section
    sed -i.bak "1a\\
\\
## [Unreleased]\\
" "$changelog_file"
    rm -f "$changelog_file.bak"
    
    git add "$changelog_file"
    git commit -m "chore: update changelog for version $version"
}

# Function to show help
show_help() {
    echo -e "$WORKFLOW_HELP"
    read -p "Press Enter to continue..."
}

# Function to display menu
show_menu() {
    clear
    echo -e "${BOLD}🌊 FlowMaster CLI${NC}"
    echo -e "${CYAN}═══════════════════════════════════${NC}"
    echo -e "${YELLOW}Type 'h' for workflow help${NC}"
    echo
    echo -e "${BOLD}Select an action:${NC}"
    echo
    echo -e "${CYAN}Feature Management${NC}"
    echo -e "  ${BLUE}1)${NC} Start new feature"
    echo -e "  ${BLUE}2)${NC} Finish feature"
    echo
    echo -e "${CYAN}Release Management${NC}"
    echo -e "  ${BLUE}3)${NC} Start release"
    echo -e "  ${BLUE}4)${NC} Finish release"
    echo
    echo -e "${CYAN}Hotfix Management${NC}"
    echo -e "  ${BLUE}5)${NC} Start hotfix"
    echo -e "  ${BLUE}6)${NC} Finish hotfix"
    echo
    echo -e "${CYAN}Other Actions${NC}"
    echo -e "  ${BLUE}7)${NC} Create commit"
    echo -e "  ${BLUE}8)${NC} View current status"
    echo -e "  ${BLUE}h)${NC} Show workflow help"
    echo -e "  ${RED}9)${NC} Exit"
    echo
    echo -e "${CYAN}Current Status${NC}"
    echo -e "  Branch: $(git branch --show-current 2>/dev/null || echo 'Not a git repository')"
    if git rev-parse --git-dir > /dev/null 2>&1; then
        echo -e "  Changes: $(git status --porcelain | wc -l) file(s) modified"
        echo -e "  Latest: $(git log -1 --pretty=format:'%h - %s' 2>/dev/null || echo 'No commits yet')"
    fi
    echo
    echo -e "${CYAN}═══════════════════════════════════${NC}"
    echo
    read -p "Enter your choice [1-9,h]: " choice
}

# Function to get feature name
get_feature_name() {
    echo
    echo -e "${BOLD}Start New Feature${NC}"
    echo -e "${CYAN}═══════════════════════════════════${NC}"
    echo
    echo -e "${YELLOW}Branch naming convention:${NC} feature/type/JIRA-123/description"
    echo -e "${YELLOW}Types:${NC} feat, fix, chore, docs, style, refactor, perf, test"
    echo
    read -p "Enter feature branch name: " branch_name
    echo
}

# Function to get version number
get_version() {
    echo
    echo -e "${BOLD}Enter Version Number${NC}"
    echo -e "${CYAN}═══════════════════════════════════${NC}"
    echo
    echo -e "${YELLOW}Version format:${NC} X.Y.Z[-prerelease] (Semantic Versioning)"
    echo -e "  ${BLUE}X${NC} = Major version (breaking changes)"
    echo -e "  ${BLUE}Y${NC} = Minor version (new features)"
    echo -e "  ${BLUE}Z${NC} = Patch version (bug fixes)"
    echo -e "  ${BLUE}-prerelease${NC} = Optional pre-release identifier (alpha.N, beta.N, rc.N)"
    echo
    echo -e "${YELLOW}Examples:${NC}"
    echo -e "  1.0.0        (Stable release)"
    echo -e "  1.1.0-alpha.1 (Alpha release)"
    echo -e "  2.0.0-beta.2  (Beta release)"
    echo -e "  1.2.0-rc.1    (Release candidate)"
    echo
    read -p "Enter version number: " version
    echo
}

# Function to show current status
show_status() {
    echo
    echo -e "${BOLD}Current Git Status${NC}"
    echo -e "${CYAN}═══════════════════════════════════${NC}"
    echo
    echo -e "${BOLD}Current branch:${NC}"
    git branch --show-current
    echo
    echo -e "${BOLD}Recent commits:${NC}"
    git log --oneline -n 5
    echo
    echo -e "${BOLD}Working tree status:${NC}"
    git status -s
    echo
    read -p "Press Enter to continue..."
}

# Main menu loop
while true; do
    show_menu
    case $choice in
        1)
            get_feature_name
            start_feature "$branch_name"
            read -p "Press Enter to continue..."
            ;;
        2)
            finish_feature
            read -p "Press Enter to continue..."
            ;;
        3)
            get_version
            start_release "$version"
            read -p "Press Enter to continue..."
            ;;
        4)
            finish_release
            read -p "Press Enter to continue..."
            ;;
        5)
            get_version
            start_hotfix "$version"
            read -p "Press Enter to continue..."
            ;;
        6)
            finish_hotfix
            read -p "Press Enter to continue..."
            ;;
        7)
            create_commit
            read -p "Press Enter to continue..."
            ;;
        8)
            show_status
            ;;
        h|H)
            show_help
            ;;
        9)
            echo
            echo -e "${GREEN}Thank you for using GitFlow Manager!${NC}"
            echo
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please try again.${NC}"
            read -p "Press Enter to continue..."
            ;;
    esac
done 