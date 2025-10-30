#!/bin/bash

# GitFlow Commit & Changelog Module
# Contains functions for managing commits and changelog

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
        echo "# 📝 Journal des modifications | Changelog | Registro de cambios

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

        # Add the entry under the appropriate section with emoji
        # Choose an appropriate emoji based on the section
        local emoji=""
        if [[ "$section" == "### Ajouté" ]]; then
            emoji="✨"
        elif [[ "$section" == "### Modifié" ]]; then
            emoji="🔄"
        elif [[ "$section" == "### Corrigé" ]]; then
            emoji="🐛"
        elif [[ "$section" == "### Supprimé" ]]; then
            emoji="🗑️"
        fi

        sed -i.bak "/^$section/a\\
- $emoji $entry" "$changelog_file"
        rm -f "$changelog_file.bak"

        git add "$changelog_file"
        info "Updated CHANGELOG.md with: $emoji $entry"
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
        local emoji="🚀"

        # Add new version section after the first line, with consistent format
        awk -v version="$version" -v date="$today" -v emoji="$emoji" '
        NR==1 {print; print "\n## [" version "] - " date " " emoji; print "### Ajouté\n### Modifié\n### Corrigé\n### Supprimé\n"}
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