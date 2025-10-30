#!/bin/bash

# GitFlow Feature Module
# Contains functions for managing feature branches

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