#!/bin/bash

# GitFlow UI Module
# Contains functions for the interactive user interface

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

# Function to show help
show_help() {
    echo -e "$WORKFLOW_HELP"
    read -p "Press Enter to continue..."
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

# Function to run the interactive menu
run_interactive_menu() {
    while true; do
        show_menu
        # Exit if user selected option 9
        if [ "$choice" = "9" ]; then
            break
        fi
    done
}