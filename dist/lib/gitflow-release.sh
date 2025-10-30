#!/bin/bash

# GitFlow Release Module
# Contains functions for managing release branches

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