# FlowMaster Bash API Documentation

This document provides comprehensive documentation for all Bash API functions in the FlowMaster GitFlow CLI tool.

## Overview

FlowMaster is organized into modular Bash scripts, each handling specific aspects of GitFlow operations:

- `gitflow-utils.sh` - Common utility functions
- `gitflow-feature.sh` - Feature branch management
- `gitflow-release.sh` - Release branch management
- `gitflow-hotfix.sh` - Hotfix branch management
- `gitflow-commit.sh` - Commit and changelog management
- `gitflow-ui.sh` - Interactive user interface

## API Reference

### gitflow-utils.sh

#### error(message)
Displays an error message and exits the script.

**Parameters:**
- `message` (string): Error message to display

**Example:**
```bash
error "Git repository not found"
```

#### success(message)
Displays a success message.

**Parameters:**
- `message` (string): Success message to display

**Example:**
```bash
success "Feature branch created successfully"
```

#### info(message)
Displays an informational message.

**Parameters:**
- `message` (string): Information message to display

**Example:**
```bash
info "Checking repository status..."
```

#### warning(message)
Displays a warning message.

**Parameters:**
- `message` (string): Warning message to display

**Example:**
```bash
warning "Uncommitted changes detected"
```

#### validate_branch_name(name)
Validates that a branch name follows GitFlow naming conventions.

**Parameters:**
- `name` (string): Branch name to validate

**Returns:**
- 0 if valid, 1 if invalid

**Example:**
```bash
if ! validate_branch_name "$branch_name"; then
    error "Invalid branch name format"
fi
```

#### ensure_clean_work_tree()
Ensures the working tree is clean (no uncommitted changes).

**Returns:**
- 0 if clean, exits with error if dirty

**Example:**
```bash
ensure_clean_work_tree
```

#### get_current_branch()
Gets the name of the current Git branch.

**Returns:**
- Current branch name

**Example:**
```bash
current=$(get_current_branch)
echo "Current branch: $current"
```

#### branch_exists(branch_name)
Checks if a Git branch exists.

**Parameters:**
- `branch_name` (string): Branch name to check

**Returns:**
- 0 if exists, 1 if not

**Example:**
```bash
if branch_exists "feature/my-feature"; then
    echo "Branch exists"
fi
```

#### validate_version(version)
Validates semantic version format.

**Parameters:**
- `version` (string): Version string to validate

**Returns:**
- 0 if valid, 1 if invalid

**Example:**
```bash
if ! validate_version "1.2.3"; then
    error "Invalid version format"
fi
```

### gitflow-feature.sh

#### start_feature(feature_name)
Creates and switches to a new feature branch.

**Parameters:**
- `feature_name` (string): Name of the feature

**Example:**
```bash
start_feature "user-authentication"
```

#### finish_feature(feature_name)
Merges a feature branch back to develop and deletes it.

**Parameters:**
- `feature_name` (string): Name of the feature to finish

**Example:**
```bash
finish_feature "user-authentication"
```

### gitflow-release.sh

#### start_release(version)
Creates a release branch from develop.

**Parameters:**
- `version` (string): Release version (e.g., "1.2.0")

**Example:**
```bash
start_release "1.2.0"
```

#### finish_release(version)
Merges release branch to main and develop, creates tags.

**Parameters:**
- `version` (string): Release version to finish

**Example:**
```bash
finish_release "1.2.0"
```

#### validate_version_format(version)
Validates release version format.

**Parameters:**
- `version` (string): Version to validate

**Returns:**
- 0 if valid, 1 if invalid

**Example:**
```bash
if ! validate_version_format "1.2.0"; then
    error "Invalid release version"
fi
```

### gitflow-hotfix.sh

#### start_hotfix(version)
Creates a hotfix branch from main.

**Parameters:**
- `version` (string): Hotfix version (e.g., "1.2.1")

**Example:**
```bash
start_hotfix "1.2.1"
```

#### finish_hotfix(version)
Merges hotfix branch to main and develop, creates tags.

**Parameters:**
- `version` (string): Hotfix version to finish

**Example:**
```bash
finish_hotfix "1.2.1"
```

### gitflow-commit.sh

#### create_commit(type, scope, description)
Creates a conventional commit.

**Parameters:**
- `type` (string): Commit type (feat, fix, docs, etc.)
- `scope` (string): Optional scope
- `description` (string): Commit description

**Example:**
```bash
create_commit "feat" "auth" "add user login functionality"
```

#### update_changelog(version, type)
Updates CHANGELOG.md with new version entry.

**Parameters:**
- `version` (string): Version number
- `type` (string): Release type (major, minor, patch)

**Example:**
```bash
update_changelog "1.2.0" "minor"
```

#### finalize_changelog()
Finalizes changelog formatting and emojis.

**Example:**
```bash
finalize_changelog
```

### gitflow-ui.sh

#### show_menu()
Displays the main interactive menu.

**Example:**
```bash
show_menu
```

#### handle_menu_selection(choice)
Processes menu selection.

**Parameters:**
- `choice` (string): Menu choice number

**Example:**
```bash
handle_menu_selection "1"
```

#### run_interactive_menu()
Runs the complete interactive menu system.

**Example:**
```bash
run_interactive_menu
```

#### show_help()
Displays help information.

**Example:**
```bash
show_help
```

## Usage Examples

### Complete Feature Workflow
```bash
#!/bin/bash
source "lib/gitflow-utils.sh"
source "lib/gitflow-feature.sh"

# Validate environment
ensure_clean_work_tree

# Start feature
start_feature "new-dashboard"

# ... development work ...

# Finish feature
finish_feature "new-dashboard"
```

### Release Process
```bash
#!/bin/bash
source "lib/gitflow-utils.sh"
source "lib/gitflow-release.sh"

# Validate version
if ! validate_version_format "1.2.0"; then
    error "Invalid version format"
fi

# Start release
start_release "1.2.0"

# ... testing and final changes ...

# Finish release
finish_release "1.2.0"
```

### Hotfix Process
```bash
#!/bin/bash
source "lib/gitflow-utils.sh"
source "lib/gitflow-hotfix.sh"

# Start hotfix
start_hotfix "1.1.1"

# ... fix critical bug ...

# Finish hotfix
finish_hotfix "1.1.1"
```

## Error Handling

All functions follow consistent error handling patterns:

- Functions that can fail return appropriate exit codes
- Error messages are displayed using the `error()` function
- Critical errors cause script termination
- Warnings use the `warning()` function for non-critical issues

## Dependencies

The API functions depend on:

- Git (for all Git operations)
- Standard Unix tools (sed, awk, grep, etc.)
- Bash 4.0+ for associative arrays and modern features

## Integration with Node.js CLI

The Bash API is called from the TypeScript CLI (`bin/flowmaster.ts`) using:

```typescript
execSync(`bash "${gitflowScript}" ${commandArgs}`, {
  stdio: 'inherit',
  env: { ...process.env, FORCE_COLOR: '1' }
});
```

This ensures proper integration between the Node.js frontend and Bash backend.