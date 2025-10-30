#!/bin/bash

# At the beginning of the file, add version
VERSION="1.1.2-alpha.2"

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

# Function to start a new feature
start_feature() {
    check_git_repo || return 1
    ensure_clean_work_tree || return 1
    check_remote_connection || return 1
    ensure_develop_branch || return 1
    
    local branch_name=$1
    validate_branch_name "$branch_name" "feature" || return 1
    
    info "Starting new feature branch: $branch_name"
    git checkout -b "$branch_name" || error "Failed to create new branch"
    success "Successfully created feature branch: $branch_name"
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

# Function to finish a feature
finish_feature() {
    local current_branch=$(git symbolic-ref --short HEAD)
    validate_branch_name "$current_branch" "feature"
    
    info "Finishing feature branch: $current_branch"
    
    # Variable to track if we used stash
    local used_stash=false
    local stash_name=""
    
    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD --; then
        error "Des changements non commités ont été détectés." "no_exit"
        echo -e "\n${YELLOW}Options disponibles :${NC}"
        echo -e "1) Commiter les changements"
        echo -e "2) Stash les changements"
        echo -e "3) Annuler l'opération"
        read -p "Choisissez une option [1-3]: " choice
        
        case $choice in
            1)
                # Create commit
                create_commit
                if [ $? -ne 0 ]; then
                    error "Échec de la création du commit"
                    return 1
                fi
                ;;
            2)
                # Stash changes
                info "Sauvegarde des changements..."
                stash_name="feature_finish_$(date +%s)"
                if ! git stash push -m "$stash_name"; then
                    error "Échec de la sauvegarde des changements"
                    return 1
                fi
                used_stash=true
                info "Changements sauvegardés avec le nom: $stash_name"
                ;;
            *)
                error "Opération annulée"
                return 1
                ;;
        esac
    fi
    
    # Function to restore stash if needed
    restore_stash() {
        if [ "$used_stash" = true ]; then
            info "Restauration des changements sauvegardés..."
            local stash_index=$(git stash list | grep "$stash_name" | cut -d: -f1)
            if [ ! -z "$stash_index" ]; then
                if ! git stash apply "$stash_index"; then
                    warning "Impossible de restaurer les changements stashés automatiquement."
                    echo -e "${YELLOW}Vos changements sont toujours dans le stash avec le nom: $stash_name${NC}"
                    echo -e "Utilisez '${GREEN}git stash list${NC}' pour voir tous les stash"
                    echo -e "Utilisez '${GREEN}git stash apply${NC}' pour les restaurer manuellement"
                else
                    git stash drop "$stash_index"
                fi
            fi
        fi
    }
    
    # Check if branch exists on remote
    local has_remote=false
    if git ls-remote --heads origin "$current_branch" | grep -q "$current_branch"; then
        has_remote=true
    fi
    
    # Update develop branch
    info "Mise à jour de la branche develop..."
    if ! safe_git_command "git checkout develop" "develop"; then
        restore_stash
        return 1
    fi
    
    if ! safe_git_command "git pull origin develop" "develop"; then
        restore_stash
        return 1
    fi
    
    # Merge feature branch
    info "Fusion de la branche feature..."
    if ! safe_git_command "git merge --no-ff '$current_branch'" "$current_branch"; then
        error "Conflit détecté lors de la fusion." "no_exit"
        echo -e "\n${YELLOW}Options disponibles :${NC}"
        echo -e "1) Résoudre les conflits manuellement"
        echo -e "2) Annuler la fusion"
        read -p "Choisissez une option [1-2]: " choice
        
        case $choice in
            1)
                info "Résolvez les conflits puis utilisez:"
                echo -e "git add <fichiers>"
                echo -e "git commit -m 'resolve conflicts'"
                restore_stash
                return 1
                ;;
            *)
                git merge --abort
                restore_stash
                error "Fusion annulée"
                return 1
                ;;
        esac
    fi
    
    # Push changes
    info "Push des changements..."
    if ! safe_git_command "git push origin develop" "develop"; then
        restore_stash
        return 1
    fi
    
    # Delete feature branch locally
    info "Suppression de la branche locale..."
    if ! safe_git_command "git branch -d '$current_branch'" "$current_branch"; then
        warning "Impossible de supprimer la branche locale"
    fi
    
    # Delete remote branch only if it exists
    if [ "$has_remote" = true ]; then
        info "Suppression de la branche distante..."
        if ! safe_git_command "git push origin --delete '$current_branch'" "$current_branch"; then
            warning "Impossible de supprimer la branche distante"
        fi
    fi
    
    success "Feature terminée avec succès: $current_branch"
    
    # Restore stashed changes at the end if everything went well
    restore_stash
}

# Function to validate version format
validate_version() {
    local version=$1
    local allow_prerelease=$2
    
    if [[ $allow_prerelease == "true" ]]; then
        # Validate version with optional pre-release tag
        if [[ ! $version =~ ^[0-9]+\.[0-9]+\.[0-9]+(-((alpha|beta|rc)\.[0-9]+))?$ ]]; then
            error "Version must follow semantic versioning: X.Y.Z[-prerelease]
Examples:
- 1.0.0 (Release finale)
- 1.0.0-alpha.1 (Alpha release)
- 1.0.0-beta.1 (Beta release)
- 1.0.0-rc.1 (Release Candidate)"
        fi
        
        # If it's a pre-release, show appropriate message
        if [[ $version =~ -alpha ]]; then
            info "Creating alpha release for internal testing"
        elif [[ $version =~ -beta ]]; then
            info "Creating beta release for external testing"
        elif [[ $version =~ -rc ]]; then
            info "Creating release candidate for final testing"
        fi
    else
        # For hotfix versions, only allow final versions
        if [[ ! $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            error "Version must follow semantic versioning: X.Y.Z"
        fi
    fi
}

# Function to start a release
start_release() {
    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD --; then
        error "Des changements non commités ont été détectés." "no_exit"
        echo -e "\n${CYAN}╭───────────────────────────────────────╮${NC}"
        echo -e "${CYAN}│${NC} ${BOLD}Options disponibles${NC}                      ${CYAN}│${NC}"
        echo -e "${CYAN}├───────────────────────────────────────┤${NC}"
        echo -e "${CYAN}│${NC} ${BLUE}[1]${NC} Commiter les changements            ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} ${BLUE}[2]${NC} Stash les changements              ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} ${BLUE}[3]${NC} Annuler l'opération                ${CYAN}│${NC}"
        echo -e "${CYAN}╰───────────────────────────────────────╯${NC}"
        
        read -p "Choisissez une option [1-3]: " choice
        
        case $choice in
            1)
                create_commit
                if [ $? -ne 0 ]; then
                    error "Échec de la création du commit"
                    return 1
                fi
                ;;
            2)
                info "Sauvegarde des changements..."
                local stash_name="release_start_$(date +%s)"
                if ! git stash push -m "$stash_name"; then
                    error "Échec de la sauvegarde des changements"
                    return 1
                fi
                info "Changements sauvegardés avec le nom: $stash_name"
                local used_stash=true
                ;;
            *)
                error "Opération annulée"
                return 1
                ;;
        esac
    fi
    
    check_remote_connection || return 1
    
    # Get current version from latest tag
    local current_version=$(get_current_version)
    local versions=($(git tag -l | grep '^v' | sed 's/^v//' | sort -t. -k1,1n -k2,2n -k3,3n))
    
    # Clear screen and show header
    clear
    echo -e "${BOLD}Démarrage d'une nouvelle Release${NC}"
    echo -e "${CYAN}═══════════════════════════════════${NC}"
    
    echo -e "\n${YELLOW}Version actuelle : ${GREEN}$current_version${NC}"
    echo -e "\n${YELLOW}Historique des versions :${NC}"
    for v in "${versions[@]}"; do
        if [[ $v == $current_version ]]; then
            echo -e "  ${GREEN}$v${NC} ${YELLOW}(actuelle)${NC}"
        else
            echo -e "  ${BLUE}$v${NC}"
        fi
    done
    
    # Parse current version for suggestions
    if [[ $current_version =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)(-((alpha|beta|rc)\.([0-9]+)))?$ ]]; then
        local major="${BASH_REMATCH[1]}"
        local minor="${BASH_REMATCH[2]}"
        local patch="${BASH_REMATCH[3]}"
        local prerelease="${BASH_REMATCH[5]}"
        local prerelease_num="${BASH_REMATCH[6]}"
        
        echo -e "\n${CYAN}╭───────────────────────────────────────╮${NC}"
        echo -e "${CYAN}│${NC} ${BOLD}Suggestions de versions${NC}                  ${CYAN}│${NC}"
        echo -e "${CYAN}├───────────────────────────────────────┤${NC}"
        
        if [[ $prerelease == "alpha" ]]; then
            echo -e "${CYAN}│${NC} ${BLUE}[1]${NC} ${GREEN}$major.$minor.$patch-alpha.$((prerelease_num+1))${NC}   ${CYAN}│${NC}"
            echo -e "${CYAN}│${NC}     Prochaine version alpha              ${CYAN}│${NC}"
            echo -e "${CYAN}│${NC} ${BLUE}[2]${NC} ${GREEN}$major.$minor.$patch-beta.1${NC}              ${CYAN}│${NC}"
            echo -e "${CYAN}│${NC}     Passer en beta                       ${CYAN}│${NC}"
            echo -e "${CYAN}│${NC} ${BLUE}[3]${NC} ${GREEN}$major.$minor.$patch${NC}                     ${CYAN}│${NC}"
            echo -e "${CYAN}│${NC}     Version finale                       ${CYAN}│${NC}"
        elif [[ $prerelease == "beta" ]]; then
            echo -e "${CYAN}│${NC} ${BLUE}[1]${NC} ${GREEN}$major.$minor.$patch-beta.$((prerelease_num+1))${NC}    ${CYAN}│${NC}"
            echo -e "${CYAN}│${NC}     Prochaine version beta               ${CYAN}│${NC}"
            echo -e "${CYAN}│${NC} ${BLUE}[2]${NC} ${GREEN}$major.$minor.$patch-rc.1${NC}               ${CYAN}│${NC}"
            echo -e "${CYAN}│${NC}     Passer en release candidate          ${CYAN}│${NC}"
            echo -e "${CYAN}│${NC} ${BLUE}[3]${NC} ${GREEN}$major.$minor.$patch${NC}                     ${CYAN}│${NC}"
            echo -e "${CYAN}│${NC}     Version finale                       ${CYAN}│${NC}"
        elif [[ $prerelease == "rc" ]]; then
            echo -e "${CYAN}│${NC} ${BLUE}[1]${NC} ${GREEN}$major.$minor.$patch-rc.$((prerelease_num+1))${NC}     ${CYAN}│${NC}"
            echo -e "${CYAN}│${NC}     Prochaine release candidate          ${CYAN}│${NC}"
            echo -e "${CYAN}│${NC} ${BLUE}[2]${NC} ${GREEN}$major.$minor.$patch${NC}                     ${CYAN}│${NC}"
            echo -e "${CYAN}│${NC}     Version finale                       ${CYAN}│${NC}"
        else
            # For stable versions
            echo -e "${CYAN}│${NC} ${BOLD}Versions stables${NC}                        ${CYAN}│${NC}"
            echo -e "${CYAN}│${NC} ${BLUE}[1]${NC} ${GREEN}$major.$minor.$((patch+1))${NC} (patch)          ${CYAN}│${NC}"
            echo -e "${CYAN}│${NC} ${BLUE}[2]${NC} ${GREEN}$major.$((minor+1)).0${NC} (minor)            ${CYAN}│${NC}"
            echo -e "${CYAN}│${NC} ${BLUE}[3]${NC} ${GREEN}$((major+1)).0.0${NC} (major)              ${CYAN}│${NC}"
        fi
        
        echo -e "${CYAN}├───────────────────────────────────────┤${NC}"
        echo -e "${CYAN}│${NC} ${BOLD}Pré-releases${NC}                           ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} ${BLUE}[4]${NC} ${GREEN}$major.$minor.$((patch+1))-alpha.1${NC} (alpha)${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} ${BLUE}[5]${NC} ${GREEN}$major.$minor.$((patch+1))-beta.1${NC} (beta) ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} ${BLUE}[6]${NC} ${GREEN}$major.$minor.$((patch+1))-rc.1${NC} (rc)    ${CYAN}│${NC}"
        echo -e "${CYAN}├───────────────────────────────────────┤${NC}"
        echo -e "${CYAN}│${NC} ${BLUE}[0]${NC} Version personnalisée                 ${CYAN}│${NC}"
        echo -e "${CYAN}╰───────────────────────────────────────╯${NC}"
        
        echo -e "\n${BLUE}Choisissez une option ou entrez une version :${NC}"
        read -p "> " choice
        
        # Process user choice and get version
        case "$choice" in
            [0-9]*)
                if [ "$choice" = "0" ]; then
                    echo -e "\nEntrez la version personnalisée (X.Y.Z[-prerelease.N]):"
                    read -p "> " version
                else
                    version=$(get_version_from_choice "$choice" "$major" "$minor" "$patch" "$prerelease" "$prerelease_num")
                fi
                ;;
            *)
                version="$choice"
                ;;
        esac
        
        # Validate version format
        validate_version "$version" "true" || return 1
        
        # Create release branch
        local branch_name="release/v$version"
        
        info "Creating release branch: $branch_name"
        if ! git checkout -b "$branch_name" develop; then
            error "Failed to create release branch"
            # Restore stashed changes if necessary
            if [ "$used_stash" = true ]; then
                info "Restauration des changements sauvegardés..."
                if ! git stash pop "stash@{0}"; then
                    warning "Impossible de restaurer les changements automatiquement."
                    echo -e "${YELLOW}Vos changements sont toujours dans le stash avec le nom: $stash_name${NC}"
                    echo -e "Utilisez '${GREEN}git stash list${NC}' pour voir tous les stash"
                    echo -e "Utilisez '${GREEN}git stash pop${NC}' pour les restaurer manuellement"
                fi
            fi
            return 1
        fi
        
        # If we used stash, try to restore changes
        if [ "$used_stash" = true ]; then
            info "Restauration des changements sauvegardés..."
            if ! git stash pop "stash@{0}"; then
                warning "Impossible de restaurer les changements automatiquement."
                echo -e "${YELLOW}Vos changements sont toujours dans le stash avec le nom: $stash_name${NC}"
                echo -e "Utilisez '${GREEN}git stash list${NC}' pour voir tous les stash"
                echo -e "Utilisez '${GREEN}git stash pop${NC}' pour les restaurer manuellement"
                return 1
            fi
        fi
        
        success "Successfully created release branch: $branch_name"
        return 0
    else
        error "Version actuelle invalide: $current_version"
        return 1
    fi
}

# Helper function to get version from choice
get_version_from_choice() {
    local choice=$1
    local major=$2
    local minor=$3
    local patch=$4
    local prerelease=$5
    local prerelease_num=$6
    
    if [[ $prerelease == "alpha" ]]; then
        case "$choice" in
            1) echo "$major.$minor.$patch-alpha.$((prerelease_num+1))";;
            2) echo "$major.$minor.$patch-beta.1";;
            3) echo "$major.$minor.$patch";;
        esac
    elif [[ $prerelease == "beta" ]]; then
        case "$choice" in
            1) echo "$major.$minor.$patch-beta.$((prerelease_num+1))";;
            2) echo "$major.$minor.$patch-rc.1";;
            3) echo "$major.$minor.$patch";;
        esac
    elif [[ $prerelease == "rc" ]]; then
        case "$choice" in
            1) echo "$major.$minor.$patch-rc.$((prerelease_num+1))";;
            2) echo "$major.$minor.$patch";;
        esac
    else
        case "$choice" in
            1) echo "$major.$minor.$((patch+1))";;
            2) echo "$major.$((minor+1)).0";;
            3) echo "$((major+1)).0.0";;
            4) echo "$major.$minor.$((patch+1))-alpha.1";;
            5) echo "$major.$minor.$((patch+1))-beta.1";;
            6) echo "$major.$minor.$((patch+1))-rc.1";;
        esac
    fi
}

# Function to finish a release
finish_release() {
    ensure_clean_work_tree || return 1
    
    # Vérifier si on est sur une branche release
    local current_branch
    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
    
    if [ -z "$current_branch" ]; then
        error "Not in a git repository or no branch exists"
        return 1
    fi
    
    if [[ ! $current_branch =~ ^release/v[0-9]+\.[0-9]+\.[0-9]+(-((alpha|beta|rc)\.[0-9]+))?$ ]]; then
        error "Must be on a release branch: release/vX.Y.Z[-prerelease]" "no_exit"
        echo -e "\n${YELLOW}Current branch: ${RED}$current_branch${NC}"
        echo -e "\n${BLUE}Available release branches:${NC}"
        
        # Afficher les branches release disponibles
        git branch -a | grep "release/" | sed 's/^[* ]//' | while read -r branch; do
            echo -e "  ${GREEN}$branch${NC}"
        done
        
        echo -e "\n${YELLOW}Please checkout a release branch first${NC}"
        return 1
    fi
    
    local version=${current_branch#release/v}
    
    info "Finishing release: $version"
    
    # Finalize changelog before merging
    finalize_changelog "$version"
    
    # Pour les versions pre-release, merger uniquement dans develop
    if [[ $version =~ -(.+)$ ]]; then
        info "Pre-release version detected, merging only to develop"
        
        if ! safe_git_command "git checkout develop" "develop"; then
            return 1
        fi
        
        if ! safe_git_command "git pull origin develop" "develop"; then
            return 1
        fi
        
        if ! safe_git_command "git merge --no-ff '$current_branch' -m 'chore: merge pre-release $version to develop'" "$current_branch"; then
            return 1
        fi
        
        if ! safe_git_command "git tag -a 'v$version' -m 'Pre-release version $version'" "tag"; then
            return 1
        fi
        
        # Push changes
        if ! safe_git_command "git push origin develop 'v$version'" "push"; then
            return 1
        fi
    else
        # Pour les versions stables, merger dans main et develop
        if ! safe_git_command "git checkout main" "main"; then
            return 1
        fi
        
        if ! safe_git_command "git pull origin main" "main"; then
            return 1
        fi
        
        if ! safe_git_command "git merge --no-ff '$current_branch' -m 'chore: release version $version'" "$current_branch"; then
            return 1
        fi
        
        if ! safe_git_command "git tag -a 'v$version' -m 'Release version $version'" "tag"; then
            return 1
        fi
        
        if ! safe_git_command "git checkout develop" "develop"; then
            return 1
        fi
        
        if ! safe_git_command "git pull origin develop" "develop"; then
            return 1
        fi
        
        if ! safe_git_command "git merge --no-ff '$current_branch' -m 'chore: merge release $version to develop'" "$current_branch"; then
            return 1
        fi
        
        # Push all changes
        if ! safe_git_command "git push origin main develop 'v$version'" "push"; then
            return 1
        fi
    fi
    
    # Delete release branch
    if ! safe_git_command "git branch -d '$current_branch'" "delete local"; then
        warning "Failed to delete local release branch"
    fi
    
    if ! safe_git_command "git push origin --delete '$current_branch'" "delete remote"; then
        warning "Failed to delete remote release branch"
    fi
    
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
        echo "# Journal des modifications

Toutes les modifications notables de ce projet seront documentées dans ce fichier.

## [Unreleased]
### Ajouté
### Modifié
### Corrigé
### Supprimé
" > "$changelog_file"
    fi
    
    # Determine the section based on commit type
    local section
    local entry
    
    if [[ "$commit_msg" =~ ^feat ]]; then
        section="### Ajouté"
        entry=$(echo "$commit_msg" | sed -E 's/^feat(\([^)]+\))?:\s*//')
    elif [[ "$commit_msg" =~ ^fix ]]; then
        section="### Corrigé"
        entry=$(echo "$commit_msg" | sed -E 's/^fix(\([^)]+\))?:\s*//')
    elif [[ "$commit_msg" =~ ^(refactor|style|perf) ]]; then
        section="### Modifié"
        entry=$(echo "$commit_msg" | sed -E 's/^(refactor|style|perf)(\([^)]+\))?:\s*//')
    elif [[ "$commit_msg" =~ ^revert ]]; then
        section="### Supprimé"
        entry=$(echo "$commit_msg" | sed -E 's/^revert(\([^)]+\))?:\s*//')
    fi
    
    # Add entry if section was determined
    if [ ! -z "$section" ] && [ ! -z "$entry" ]; then
        # Check if section exists in Unreleased, if not add it
        if ! grep -q "^$section" "$changelog_file"; then
            sed -i.bak "/## \[Unreleased\]/a\\
$section" "$changelog_file"
            rm -f "$changelog_file.bak"
        fi
        
        # Add the entry under the appropriate section
        sed -i.bak "/^$section/a\\
- $entry" "$changelog_file"
        rm -f "$changelog_file.bak"
        
        git add "$changelog_file"
        info "Updated CHANGELOG.md with: $entry"
    fi
}

# Function to finalize changelog for release
finalize_changelog() {
    local version=$1
    local changelog_file="CHANGELOG.md"
    local today=$(date +%Y-%m-%d)
    
    # Check if tag already exists
    if git rev-parse "v$version" >/dev/null 2>&1; then
        error "Le tag v$version existe déjà." "no_exit"
        echo -e "\n${CYAN}╭───────────────────────────────────────╮${NC}"
        echo -e "${CYAN}│${NC} ${BOLD}Options disponibles${NC}                      ${CYAN}│${NC}"
        echo -e "${CYAN}├───────────────────────────────────────┤${NC}"
        echo -e "${CYAN}│${NC} ${BLUE}[1]${NC} Supprimer et recréer le tag         ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} ${BLUE}[2]${NC} Incrémenter automatiquement         ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} ${BLUE}[3]${NC} Annuler l'opération                 ${CYAN}│${NC}"
        echo -e "${CYAN}╰───────────────────────────────────────╯${NC}"
        
        read -p "Choisissez une option [1-3]: " choice
        
        case $choice in
            1)
                info "Suppression du tag existant..."
                if ! git tag -d "v$version" >/dev/null 2>&1; then
                    error "Impossible de supprimer le tag local"
                    return 1
                fi
                if ! git push origin ":refs/tags/v$version" >/dev/null 2>&1; then
                    warning "Impossible de supprimer le tag distant"
                fi
                ;;
            2)
                # Incrémenter automatiquement la version
                if [[ $version =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)(-((alpha|beta|rc)\.([0-9]+)))?$ ]]; then
                    local major="${BASH_REMATCH[1]}"
                    local minor="${BASH_REMATCH[2]}"
                    local patch="${BASH_REMATCH[3]}"
                    local prerelease="${BASH_REMATCH[5]}"
                    local prerelease_num="${BASH_REMATCH[6]}"
                    
                    if [ ! -z "$prerelease" ]; then
                        # Incrémenter le numéro de pre-release
                        prerelease_num=$((prerelease_num + 1))
                        version="$major.$minor.$patch-$prerelease.$prerelease_num"
                    else
                        # Incrémenter le patch
                        patch=$((patch + 1))
                        version="$major.$minor.$patch"
                    fi
                    
                    info "Nouvelle version : $version"
                    read -p "Continuer avec cette version ? [Y/n] " response
                    if [[ "$response" =~ ^[Nn]$ ]]; then
                        error "Opération annulée"
                        return 1
                    fi
                else
                    error "Format de version invalide"
                    return 1
                fi
                ;;
            *)
                error "Opération annulée"
                return 1
                ;;
        esac
    fi
    
    # Update CHANGELOG.md
    info "Mise à jour du CHANGELOG.md..."
    
    # Add new version header if it doesn't exist
    if ! grep -q "## \[$version\]" "$changelog_file"; then
        # Create temporary file
        local temp_file=$(mktemp)
        
        # Add new version section after the first line
        awk -v version="$version" -v date="$today" '
        NR==1 {print; print "\n## [" version "] - " date; print "### Ajouté\n### Modifié\n### Corrigé\n### Supprimé\n"}
        NR!=1 {print}
        ' "$changelog_file" > "$temp_file"
        
        # Replace original file
        mv "$temp_file" "$changelog_file"
    fi
    
    # Create git tag with changelog content
    local tag_message=$(awk "/^## \[$version\]/,/^## /{print}" "$changelog_file" | sed '/^## \[/d;/^## /q' | sed '/^$/d')
    
    git add "$changelog_file"
    git commit -m "chore: mise à jour du changelog pour la version $version"
    
    # Create annotated tag with changelog content
    if ! git tag -a "v$version" -m "Version $version

$tag_message"; then
        error "Impossible de créer le tag v$version"
        return 1
    fi
    
    # Show the final version header with appropriate message
    echo -e "\n${GREEN}Version $version finalisée :${NC}"
    if [[ $version =~ -alpha ]]; then
        echo -e "${YELLOW}Version Alpha pour tests internes${NC}"
    elif [[ $version =~ -beta ]]; then
        echo -e "${YELLOW}Version Beta pour tests externes${NC}"
    elif [[ $version =~ -rc ]]; then
        echo -e "${YELLOW}Version Release Candidate pour tests finaux${NC}"
    else
        echo -e "${GREEN}Version Finale${NC}"
    fi
    echo -e "${BLUE}## [$version] - $today${NC}"
    echo -e "${YELLOW}Tag créé avec le contenu du changelog${NC}\n"
    
    return 0
}

# Function to show help
show_help() {
    echo -e "$WORKFLOW_HELP"
    read -p "Press Enter to continue..."
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

# Function to handle menu selection
handle_menu_selection() {
    case $1 in
        1)  # Start Feature
            get_feature_name
            start_feature "$branch_name"
            ;;
        2)  # Finish Feature
            finish_feature
            ;;
        3)  # Start Release
            start_release
            ;;
        4)  # Finish Release
            finish_release
            ;;
        5)  # Start Hotfix
            get_version
            start_hotfix "$version"
            ;;
        6)  # Finish Hotfix
            finish_hotfix
            ;;
        7)  # Create Commit
            create_commit
            ;;
        8)  # Show Status
            show_status
            ;;
        9)  # Exit
            echo
            echo -e "${GREEN}Thank you for using GitFlow Manager!${NC}"
            echo
            exit 0
            ;;
        *)
            error "Option invalide"
            ;;
    esac
}

# Function to show menu
show_menu() {
    clear
    local current_version=$(get_current_version)
    local current_branch=$(git branch --show-current 2>/dev/null || echo 'Not a git repository')
    local changes_count=$(git status --porcelain 2>/dev/null | wc -l)
    local latest_commit=$(git log -1 --pretty=format:'%h - %s' 2>/dev/null || echo 'No commits yet')
    
    # Header
    echo
    echo -e "${BOLD}             🌊 FlowMaster CLI ${NC}"
    echo -e "${CYAN}             Version ${current_version}${NC}"
    echo
    echo -e "${CYAN}╭───────────────────────────────────────╮${NC}"
    
    # Status Bar
    echo -e "${CYAN}│${NC} ${BOLD}Status${NC}                                 ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} Branch  : ${GREEN}$current_branch${NC}            ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} Changes : ${YELLOW}$changes_count file(s)${NC}               ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} Latest  : ${BLUE}$latest_commit${NC}     ${CYAN}│${NC}"
    echo -e "${CYAN}├───────────────────────────────────────┤${NC}"
    
    # Feature Management
    echo -e "${CYAN}│${NC} ${BOLD}Feature Management${NC}                     ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} ${BLUE}[1]${NC} Start Feature                      ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} ${BLUE}[2]${NC} Finish Feature                     ${CYAN}│${NC}"
    echo -e "${CYAN}├───────────────────────────────────────┤${NC}"
    
    # Release Management
    echo -e "${CYAN}│${NC} ${BOLD}Release Management${NC}                     ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} ${BLUE}[3]${NC} Start Release                      ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} ${BLUE}[4]${NC} Finish Release                     ${CYAN}│${NC}"
    echo -e "${CYAN}├───────────────────────────────────────┤${NC}"
    
    # Hotfix Management
    echo -e "${CYAN}│${NC} ${BOLD}Hotfix Management${NC}                      ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} ${BLUE}[5]${NC} Start Hotfix                       ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} ${BLUE}[6]${NC} Finish Hotfix                      ${CYAN}│${NC}"
    echo -e "${CYAN}├───────────────────────────────────────┤${NC}"
    
    # Other Actions
    echo -e "${CYAN}│${NC} ${BOLD}Other Actions${NC}                          ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} ${BLUE}[7]${NC} Create Commit                      ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} ${BLUE}[8]${NC} View Status                        ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} ${BLUE}[u]${NC} Check for Updates                  ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} ${BLUE}[h]${NC} Show Help                          ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} ${RED}[9]${NC} Exit                              ${CYAN}│${NC}"
    echo -e "${CYAN}╰───────────────────────────────────────╯${NC}"
    
    # Footer
    echo
    echo -e "       ${YELLOW}Type 'h' for workflow help${NC}"
    echo
    
    # Input
    echo -e "${BOLD}Select an action${NC} ${BLUE}[1-9,h]${NC}: \c"
    read choice
    
    # Remove the version prompt for release
    if [ "$choice" = "3" ]; then
        handle_menu_selection "$choice"
        return
    fi
    
    # Handle other menu options
    case $choice in
        1|2|4|5|6|7|8|9)
            handle_menu_selection "$choice"
            ;;
        h|H)
            show_help
            ;;
        u|U)
            check_for_updates
            ;;
        *)
            error "Option invalide"
            ;;
    esac
}

# Function to get feature name
get_feature_name() {
    echo
    echo -e "${BOLD}Start New Feature${NC}"
    echo -e "${CYAN}═══════════════════════════════════${NC}"
    echo

    # Get feature name
    while true; do
        echo -e "${YELLOW}Enter feature name:${NC}"
        read -r desc
        # Convert to kebab-case and clean up
        desc=$(echo "$desc" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')
        if [[ -n "$desc" ]]; then
            break
        else
            echo -e "${RED}Feature name cannot be empty${NC}"
        fi
    done

    # Construct branch name
    branch_name="feature/$desc"
    
    echo -e "\n${GREEN}Branch name will be: $branch_name${NC}"
    echo -e "${YELLOW}Continue? [Y/n]${NC}"
    read -r response
    if [[ "$response" =~ ^[Nn]$ ]]; then
        error "Branch creation cancelled"
        return 1
    fi
    
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

# Function to show current status with modern display
show_status() {
    clear
    echo
    echo -e "${BOLD}             Git Status Overview${NC}"
    echo
    echo -e "${CYAN}╭───────────────────────────────────────╮${NC}"
    
    # Branch Info
    echo -e "${CYAN}│${NC} ${BOLD}Current Branch${NC}                         ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} $(git branch --show-current)                    ${CYAN}│${NC}"
    echo -e "${CYAN}├───────────────────────────────────────┤${NC}"
    
    # Recent Commits
    echo -e "${CYAN}│${NC} ${BOLD}Recent Commits${NC}                         ${CYAN}│${NC}"
    git log --oneline -n 5 | while read -r line; do
        echo -e "${CYAN}│${NC} ${BLUE}$line${NC}                     ${CYAN}│${NC}"
    done
    echo -e "${CYAN}├───────────────────────────────────────┤${NC}"
    
    # Working Tree Status
    echo -e "${CYAN}│${NC} ${BOLD}Working Tree Status${NC}                    ${CYAN}│${NC}"
    git status -s | while read -r line; do
        echo -e "${CYAN}│${NC} ${YELLOW}$line${NC}                            ${CYAN}│${NC}"
    done
    
    echo -e "${CYAN}╰───────────────────────────────────────╯${NC}"
    echo
    read -p "Press Enter to continue..."
}

# Main menu loop
while true; do
    show_menu
done 