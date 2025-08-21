#!/bin/bash

# Native plugin implementation
# Migrated from legacy script to use plugin API

# Source the plugin API
source "${MAC_POWER_TOOLS_HOME}/lib/plugin-api.sh"




# Dry run mode (default: true for safety)
DRY_RUN=true
INTERACTIVE=true
VERBOSE=false

# Function to print colored output
print_color() {
    local color=$1
    shift
    printf "${color}%s${NC}\n" "$*"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check dependencies
check_dependencies() {
    local missing=()
    
    if ! command_exists mas; then
        missing+=("mas")
    fi
    
    if ! command_exists brew; then
        missing+=("brew")
    fi
    
    if [ ${#missing[@]} -gt 0 ]; then
        print_error "Missing required dependencies: ${missing[*]}"
        echo
        print_warning "Install them with:"
        for dep in "${missing[@]}"; do
            if [ "$dep" = "mas" ]; then
                echo "  brew install mas"
            elif [ "$dep" = "brew" ]; then
                echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            fi
        done
        return 1
    fi
    return 0
}

# Known MAS to Homebrew Cask mappings
# Using a function instead of associative array for compatibility
get_cask_for_mas_id() {
    local mas_id=$1
    case "$mas_id" in
        # Productivity
        "1333542190") echo "1password-7" ;;           # 1Password 7
        "1569813296") echo "1password" ;;              # 1Password 8
        "824183456") echo "affinity-photo" ;;          # Affinity Photo
        "824171161") echo "affinity-designer" ;;       # Affinity Designer
        "881418622") echo "affinity-publisher" ;;      # Affinity Publisher
        "937984704") echo "amphetamine" ;;             # Amphetamine
        "1091189122") echo "bear" ;;                   # Bear
        "1352778147") echo "bitwarden" ;;              # Bitwarden
        "424389933") echo "final-cut-pro" ;;           # Final Cut Pro
        "682658836") echo "garageband" ;;              # GarageBand
        "408981434") echo "imovie" ;;                  # iMovie
        "409183694") echo "keynote" ;;                 # Keynote
        "405399194") echo "kindle" ;;                  # Kindle
        "634148309") echo "logic-pro" ;;               # Logic Pro
        "634159523") echo "mainstage" ;;               # MainStage
        "405843582") echo "alfred" ;;                  # Alfred
        "409201541") echo "pages" ;;                   # Pages
        "409203825") echo "numbers" ;;                 # Numbers
        "803453959") echo "slack" ;;                   # Slack
        "747648890") echo "telegram" ;;                # Telegram
        "1482454543") echo "twitter" ;;                # Twitter
        "310633997") echo "whatsapp" ;;                # WhatsApp
        "497799835") echo "xcode" ;;                   # Xcode
        
        # Development
        "1450874784") echo "transmit" ;;               # Transmit 5
        "1496833156") echo "swift-playgrounds" ;;      # Swift Playgrounds
        "640199958") echo "apple-developer" ;;         # Apple Developer
        "1483172210") echo "apple-configurator" ;;     # Apple Configurator 2
        
        # Media
        "461369673") echo "vox" ;;                     # VOX
        "1289583905") echo "pixelmator-pro" ;;         # Pixelmator Pro
        "407963104") echo "pixelmator" ;;              # Pixelmator
        "434290957") echo "motion" ;;                  # Motion
        "424390742") echo "compressor" ;;              # Compressor
        
        # Utilities
        "425424353") echo "the-unarchiver" ;;          # The Unarchiver
        "1176895641") echo "spark" ;;                  # Spark Email
        "441258766") echo "magnet" ;;                  # Magnet
        "533696630") echo "webcam-settings" ;;         # Webcam Settings
        "1147396723") echo "whatsapp-desktop" ;;       # WhatsApp Desktop
        "413857545") echo "divvy" ;;                   # Divvy
        "603117688") echo "ccleaner" ;;                # CCleaner
        "715768417") echo "microsoft-remote-desktop" ;; # Microsoft Remote Desktop
        
        # Browsers
        "1518425043") echo "boxy-suite" ;;             # Boxy for Gmail
        
        # Notes & Writing
        "1455029918") echo "agenda" ;;                 # Agenda
        "1528890965") echo "textsniper" ;;             # TextSniper
        "732710998") echo "enpass" ;;                  # Enpass
        "557168941") echo "tweetbot" ;;                # Tweetbot
        "1487937127") echo "craft" ;;                  # Craft
        "585829637") echo "todoist" ;;                 # Todoist
        "918858936") echo "airmail" ;;                 # Airmail
        "1435957248") echo "drafts" ;;                 # Drafts
        
        *) echo "" ;;  # Return empty for unknown IDs
    esac
}

# Function to get installed MAS apps
get_mas_apps() {
    if ! command_exists mas; then
        echo "[]"
        return
    fi
    
    # mas list format: "ID AppName (Version)"
    mas list 2>/dev/null | while read -r line; do
        if [ -n "$line" ]; then
            local id=$(echo "$line" | awk '{print $1}')
            local name=$(echo "$line" | sed 's/^[0-9]* \(.*\) (.*)/\1/')
            echo "${id}|${name}"
        fi
    done
}

# Function to check if cask is installed
is_cask_installed() {
    local cask=$1
    brew list --cask 2>/dev/null | grep -q "^${cask}$"
}

# Function to find cask for app
find_cask_for_app() {
    local app_name=$1
    local search_name=$(echo "$app_name" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')
    
    # Try exact search first
    local result=$(brew search --cask "^${search_name}$" 2>/dev/null | grep -v "==>" | head -1)
    
    # If no exact match, try partial search
    if [ -z "$result" ]; then
        result=$(brew search --cask "${search_name}" 2>/dev/null | grep -v "==>" | head -1)
    fi
    
    echo "$result"
}

# Function to migrate single app
migrate_app() {
    local mas_id=$1
    local app_name=$2
    local cask_name=$3
    
    if [ "$DRY_RUN" = true ]; then
        print_info "[DRY RUN] Would migrate: $app_name"
        print_info "  - Uninstall MAS version (ID: $mas_id)"
        print_info "  - Install Homebrew cask: $cask_name"
        return 0
    fi
    
    # Install cask version first
    print_warning "Installing $app_name via Homebrew..."
    if brew install --cask "$cask_name"; then
        print_success "✓ Installed $cask_name"
        
        # Uninstall MAS version
        print_warning "Removing Mac App Store version..."
        if mas uninstall "$mas_id" 2>/dev/null; then
            print_success "✓ Removed MAS version"
        else
            print_warning "Note: Could not remove MAS version automatically"
            print_info "You may need to manually delete it from /Applications"
        fi
        
        return 0
    else
        print_error "Failed to install $cask_name"
        return 1
    fi
}

# Function to analyze migration opportunities
analyze_migration() {
    print_info "Analyzing Mac App Store apps for migration opportunities..."
    echo
    
    local migratable=()
    local unknown=()
    local already_migrated=()
    
    while IFS='|' read -r id name; do
        if [ -n "$id" ] && [ -n "$name" ]; then
            # Check custom mappings first, then known mappings
            local cask=$(get_custom_mapping "$id")
            if [ -z "$cask" ]; then
                cask=$(get_cask_for_mas_id "$id")
            fi
            
            if [ -n "$cask" ]; then
                
                # Check if cask is already installed
                if is_cask_installed "$cask"; then
                    already_migrated+=("$name (→ $cask)")
                else
                    migratable+=("${id}|${name}|${cask}")
                fi
            else
                # Try to find a cask
                local possible_cask=$(find_cask_for_app "$name")
                if [ -n "$possible_cask" ]; then
                    migratable+=("${id}|${name}|${possible_cask}|suggested")
                else
                    unknown+=("$name (ID: $id)")
                fi
            fi
        fi
    done < <(get_mas_apps)
    
    # Display results
    if [ ${#migratable[@]} -gt 0 ]; then
        print_success "Apps that can be migrated to Homebrew:"
        for item in "${migratable[@]}"; do
            IFS='|' read -r id name cask suggested <<< "$item"
            if [ "$suggested" = "suggested" ]; then
                echo "  • $name → $cask (suggested)"
            else
                echo "  • $name → $cask"
            fi
        done
        echo
    fi
    
    if [ ${#already_migrated[@]} -gt 0 ]; then
        print_info "Apps already available via Homebrew:"
        for app in "${already_migrated[@]}"; do
            echo "  • $app"
        done
        echo
    fi
    
    if [ ${#unknown[@]} -gt 0 ]; then
        print_warning "Apps without known Homebrew equivalents:"
        for app in "${unknown[@]}"; do
            echo "  • $app"
        done
        echo
    fi
    
    # Return migratable apps for processing
    printf '%s\n' "${migratable[@]}"
}

# Function to perform migration
perform_migration() {
    local apps=("$@")
    local migrated=0
    local failed=0
    
    for item in "${apps[@]}"; do
        IFS='|' read -r id name cask suggested <<< "$item"
        
        if [ "$INTERACTIVE" = true ]; then
            echo
            if [ "$suggested" = "suggested" ]; then
                print_warning "Suggested migration: $name → $cask"
                print_info "This is an automatic suggestion and may not be exact"
            else
                print_info "Migrate: $name → $cask"
            fi
            
            read -p "Proceed? (y/n/s=skip): " -n 1 -r
            echo
            
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_warning "Skipped $name"
                continue
            fi
        fi
        
        if migrate_app "$id" "$name" "$cask"; then
            ((migrated++))
        else
            ((failed++))
        fi
    done
    
    # Summary
    echo
    print_info "═══════════════════════════════════════════"
    print_info "Migration Summary"
    print_info "═══════════════════════════════════════════"
    print_success "Successfully migrated: $migrated"
    [ $failed -gt 0 ] && print_error "Failed: $failed"
    
    if [ "$DRY_RUN" = true ]; then
        echo
        print_warning "This was a dry run - no changes were made"
        print_info "Run with --execute to perform actual migration"
    fi
}

# Custom mappings storage (for current session)
CUSTOM_MAPPINGS=""

# Function to add custom mapping
add_custom_mapping() {
    local mas_id=$1
    local cask_name=$2
    
    print_info "Adding custom mapping: $mas_id → $cask_name"
    
    # Add to custom mappings for current session
    CUSTOM_MAPPINGS="${CUSTOM_MAPPINGS}${mas_id}:${cask_name};"
}

# Function to get custom mapping
get_custom_mapping() {
    local mas_id=$1
    if [ -n "$CUSTOM_MAPPINGS" ]; then
        echo "$CUSTOM_MAPPINGS" | tr ';' '\n' | grep "^${mas_id}:" | cut -d':' -f2
    fi
}

# Function to list all known mappings
list_mappings() {
    print_info "Known Mac App Store to Homebrew Cask mappings:"
    print_info "═══════════════════════════════════════════"
    
    # List all known mappings from the function
    cat << 'EOF'
  1333542190 → 1password-7
  1569813296 → 1password
  824183456 → affinity-photo
  824171161 → affinity-designer
  881418622 → affinity-publisher
  937984704 → amphetamine
  1091189122 → bear
  1352778147 → bitwarden
  424389933 → final-cut-pro
  682658836 → garageband
  408981434 → imovie
  409183694 → keynote
  405399194 → kindle
  634148309 → logic-pro
  634159523 → mainstage
  405843582 → alfred
  409201541 → pages
  409203825 → numbers
  803453959 → slack
  747648890 → telegram
  1482454543 → twitter
  310633997 → whatsapp
  497799835 → xcode
  1450874784 → transmit
  1496833156 → swift-playgrounds
  640199958 → apple-developer
  1483172210 → apple-configurator
  461369673 → vox
  1289583905 → pixelmator-pro
  407963104 → pixelmator
  434290957 → motion
  424390742 → compressor
  425424353 → the-unarchiver
  1176895641 → spark
  441258766 → magnet
  533696630 → webcam-settings
  1147396723 → whatsapp-desktop
  413857545 → divvy
  603117688 → ccleaner
  715768417 → microsoft-remote-desktop
  1518425043 → boxy-suite
  1455029918 → agenda
  1528890965 → textsniper
  732710998 → enpass
  557168941 → tweetbot
  1487937127 → craft
  585829637 → todoist
  918858936 → airmail
  1435957248 → drafts
EOF
    
    # Show custom mappings if any
    if [ -n "$CUSTOM_MAPPINGS" ]; then
        echo
        print_info "Custom mappings (current session):"
        echo "$CUSTOM_MAPPINGS" | tr ';' '\n' | grep -v '^$' | while IFS=':' read -r id cask; do
            echo "  $id → $cask"
        done
    fi
}

# Show help
show_help() {
    cat << EOF
Mac Power Tools - MAS to Homebrew Migration

Helps migrate apps from Mac App Store to Homebrew Cask versions for better
management, updates, and automation.

USAGE:
    mac migrate-mas [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    -a, --analyze       Analyze apps and show migration opportunities
    -e, --execute       Execute migration (default is dry-run)
    -y, --yes           Non-interactive mode (migrate all)
    -l, --list          List known MAS to Cask mappings
    -m, --map ID CASK   Add custom MAS ID to Cask mapping
    -v, --verbose       Show detailed output

EXAMPLES:
    # Analyze what can be migrated (safe, read-only)
    mac migrate-mas --analyze
    
    # Perform dry-run migration (default)
    mac migrate-mas
    
    # Execute actual migration interactively
    mac migrate-mas --execute
    
    # Migrate all without prompting
    mac migrate-mas --execute --yes
    
    # Add custom mapping and migrate
    mac migrate-mas --map 123456789 my-app --execute

BENEFITS OF MIGRATION:
    • Homebrew casks update faster than Mac App Store
    • No Apple ID required for app management
    • Better automation and scripting support
    • Unified package management with brew
    • Easier backup and restore of apps

NOTES:
    • Some apps may lose Mac App Store specific features
    • Purchases may not transfer (check app licensing)
    • Always backup before migrating critical apps
    • Some apps are Mac App Store exclusive

EOF
}

# Main function
main() {
    local analyze_only=false
    local execute=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -a|--analyze)
                analyze_only=true
                shift
                ;;
            -e|--execute)
                DRY_RUN=false
                shift
                ;;
            -y|--yes)
                INTERACTIVE=false
                shift
                ;;
            -l|--list)
                list_mappings
                exit 0
                ;;
            -m|--map)
                if [ -n "$2" ] && [ -n "$3" ]; then
                    add_custom_mapping "$2" "$3"
                    shift 3
                else
                    print_error "Error: --map requires MAS_ID and CASK_NAME"
                    exit 1
                fi
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Use 'mac migrate-mas --help' for usage"
                exit 1
                ;;
        esac
    done
    
    # Check dependencies
    if ! check_dependencies; then
        exit 1
    fi
    
    print_info "═══════════════════════════════════════════"
    print_info "Mac App Store to Homebrew Migration Tool"
    print_info "═══════════════════════════════════════════"
    echo
    
    # Get migratable apps
    migratable_apps=()
    while IFS= read -r line; do
        [[ -n "$line" ]] && migratable_apps+=("$line")
    done < <(analyze_migration)
    
    if [ ${#migratable_apps[@]} -eq 0 ] || [ -z "${migratable_apps[0]}" ]; then
        print_warning "No apps found to migrate"
        print_info "All your Mac App Store apps are either:"
        echo "  • Already available via Homebrew"
        echo "  • Mac App Store exclusive"
        exit 0
    fi
    
    # If analyze only, we're done
    if [ "$analyze_only" = true ]; then
        exit 0
    fi
    
    # Confirm migration
    if [ "$DRY_RUN" = true ]; then
        print_warning "Running in DRY RUN mode - no changes will be made"
    else
        print_warning "⚠️  This will modify your installed applications"
    fi
    
    if [ "$INTERACTIVE" = true ] && [ "$DRY_RUN" = false ]; then
        echo
        read -p "Continue with migration? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_warning "Migration cancelled"
            exit 0
        fi
    fi
    
    # Perform migration
    perform_migration "${migratable_apps[@]}"
}

# Run main function if script is executed directly

# Plugin main entry point
plugin_main() {
    # Call the main function with all arguments
    main "$@"
}

# Initialize the plugin
plugin_init

# Call the main function if not sourced
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    plugin_main "$@"
fi
