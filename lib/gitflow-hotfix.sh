#!/bin/bash

# GitFlow Hotfix Module
# Contains functions for managing hotfix branches

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