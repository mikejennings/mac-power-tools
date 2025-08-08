#!/bin/bash

# Mac Power Tools - Migrate manually downloaded apps to Homebrew
# Helps users migrate apps from /Applications to Homebrew Cask versions

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

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
    
    if ! command_exists brew; then
        missing+=("brew")
    fi
    
    if [ ${#missing[@]} -gt 0 ]; then
        print_color "$RED" "Missing required dependencies: ${missing[*]}"
        echo
        print_color "$YELLOW" "Install them with:"
        for dep in "${missing[@]}"; do
            if [ "$dep" = "brew" ]; then
                echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            fi
        done
        return 1
    fi
    return 0
}

# Known app name to Homebrew Cask mappings
# Using a function instead of associative array for compatibility
get_cask_for_app_name() {
    local app_name=$1
    case "$app_name" in
        # Productivity
        "1Password 7 - Password Manager") echo "1password-7" ;;
        "1Password 8 - Password Manager") echo "1password" ;;
        "Affinity Photo") echo "affinity-photo" ;;
        "Affinity Photo 2") echo "affinity-photo" ;;
        "Affinity Designer") echo "affinity-designer" ;;
        "Affinity Designer 2") echo "affinity-designer" ;;
        "Affinity Publisher") echo "affinity-publisher" ;;
        "Affinity Publisher 2") echo "affinity-publisher" ;;
        "Alfred") echo "alfred" ;;
        "Bear") echo "bear" ;;
        "Bitwarden") echo "bitwarden" ;;
        "CleanMyMac X") echo "cleanmymac" ;;
        "Discord") echo "discord" ;;
        "Dropbox") echo "dropbox" ;;
        "Figma") echo "figma" ;;
        "Google Chrome") echo "google-chrome" ;;
        "Google Drive") echo "google-drive" ;;
        "Kindle") echo "kindle" ;;
        "Microsoft Excel") echo "microsoft-excel" ;;
        "Microsoft PowerPoint") echo "microsoft-powerpoint" ;;
        "Microsoft Word") echo "microsoft-word" ;;
        "Microsoft OneNote") echo "microsoft-onenote" ;;
        "Microsoft Outlook") echo "microsoft-outlook" ;;
        "Microsoft Teams") echo "microsoft-teams" ;;
        "Notion") echo "notion" ;;
        "Obsidian") echo "obsidian" ;;
        "Rectangle") echo "rectangle" ;;
        "Slack") echo "slack" ;;
        "Spotify") echo "spotify" ;;
        "Telegram") echo "telegram" ;;
        "Twitter") echo "twitter" ;;
        "WhatsApp") echo "whatsapp" ;;
        "Zoom") echo "zoom" ;;
        
        # Development
        "Android Studio") echo "android-studio" ;;
        "Docker Desktop") echo "docker" ;;
        "GitHub Desktop") echo "github" ;;
        "GitKraken") echo "gitkraken" ;;
        "IntelliJ IDEA CE") echo "intellij-idea-ce" ;;
        "IntelliJ IDEA") echo "intellij-idea" ;;
        "JetBrains Toolbox") echo "jetbrains-toolbox" ;;
        "Postman") echo "postman" ;;
        "PyCharm CE") echo "pycharm-ce" ;;
        "PyCharm") echo "pycharm" ;;
        "Sublime Text") echo "sublime-text" ;;
        "TablePlus") echo "tableplus" ;;
        "Transmit 5") echo "transmit" ;;
        "Visual Studio Code") echo "visual-studio-code" ;;
        "WebStorm") echo "webstorm" ;;
        "Xcode") echo "xcode" ;;
        
        # Media
        "Adobe Photoshop 2024") echo "adobe-photoshop" ;;
        "Adobe Illustrator 2024") echo "adobe-illustrator" ;;
        "Adobe Premiere Pro 2024") echo "adobe-premiere-pro" ;;
        "Adobe After Effects 2024") echo "adobe-after-effects" ;;
        "Adobe Creative Cloud") echo "adobe-creative-cloud" ;;
        "Audacity") echo "audacity" ;;
        "Blender") echo "blender" ;;
        "DaVinci Resolve") echo "davinci-resolve" ;;
        "Final Cut Pro") echo "final-cut-pro" ;;
        "Handbrake") echo "handbrake" ;;
        "IINA") echo "iina" ;;
        "Logic Pro") echo "logic-pro" ;;
        "OBS Studio") echo "obs" ;;
        "Pixelmator Pro") echo "pixelmator-pro" ;;
        "Sketch") echo "sketch" ;;
        "VLC media player") echo "vlc" ;;
        
        # Utilities
        "1Blocker- Ad Blocker & Privacy") echo "1blocker" ;;
        "AppCleaner") echo "appcleaner" ;;
        "BetterTouchTool") echo "bettertouchtool" ;;
        "CleanMaster- Remove Junk Files") echo "cleanmaster" ;;
        "Finder") echo "" ;;  # System app, no cask
        "Hammerspoon") echo "hammerspoon" ;;
        "Karabiner-Elements") echo "karabiner-elements" ;;
        "Magnet") echo "magnet" ;;
        "Raycast") echo "raycast" ;;
        "The Unarchiver") echo "the-unarchiver" ;;
        "TopNotch") echo "topnotch" ;;
        
        # Browsers
        "Arc") echo "arc" ;;
        "Brave Browser") echo "brave-browser" ;;
        "Firefox") echo "firefox" ;;
        "Microsoft Edge") echo "microsoft-edge" ;;
        "Opera") echo "opera" ;;
        "Safari") echo "" ;;  # System app, no cask
        
        # Communication
        "FaceTime") echo "" ;;  # System app, no cask
        "Mail") echo "" ;;  # System app, no cask
        "Messages") echo "" ;;  # System app, no cask
        "Skype") echo "skype" ;;
        
        *) echo "" ;;  # Return empty for unknown apps
    esac
}

# Function to get installed apps from /Applications
get_installed_apps() {
    find /Applications -maxdepth 1 -name "*.app" -type d 2>/dev/null | while read -r app_path; do
        local app_name=$(basename "$app_path" .app)
        echo "$app_name"
    done | sort
}

# Function to check if cask is installed
is_cask_installed() {
    local cask=$1
    brew list --cask 2>/dev/null | grep -q "^${cask}$"
}

# Function to find cask for app
find_cask_for_app() {
    local app_name=$1
    local search_name=$(echo "$app_name" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g' | sed 's/[^a-z0-9-]//g')
    
    # Skip brew search for now to speed up testing - just return empty
    # This can be re-enabled later for production use
    echo ""
}

# Function to migrate single app (DRY RUN ONLY - NO DELETION)
migrate_app() {
    local app_name=$1
    local cask_name=$2
    
    if [ "$DRY_RUN" = true ]; then
        print_color "$CYAN" "[DRY RUN] Would migrate: $app_name"
        print_color "$CYAN" "  - Install Homebrew cask: $cask_name"
        print_color "$CYAN" "  - Manual cleanup: Move /Applications/$app_name.app to Trash"
        return 0
    fi
    
    # Install cask version
    print_color "$YELLOW" "Installing $app_name via Homebrew..."
    if brew install --cask "$cask_name"; then
        print_color "$GREEN" "✓ Installed $cask_name"
        
        # IMPORTANT: We do NOT automatically delete the manual app
        # User must manually clean up to avoid data loss
        print_color "$YELLOW" "⚠️  Manual cleanup required:"
        print_color "$CYAN" "  1. Quit $app_name if running"
        print_color "$CYAN" "  2. Move /Applications/$app_name.app to Trash"
        print_color "$CYAN" "  3. The Homebrew version is now available"
        
        return 0
    else
        print_color "$RED" "Failed to install $cask_name"
        return 1
    fi
}

# Function to analyze migration opportunities
analyze_migration() {
    print_color "$BLUE" "Analyzing /Applications for migration opportunities..."
    echo
    
    local migratable=()
    local unknown=()
    local already_migrated=()
    local system_apps=()
    
    # Get a limited set of apps for testing
    local app_list=$(get_installed_apps | head -20)
    
    while IFS= read -r app_name; do
        if [ -n "$app_name" ]; then
            [ "$VERBOSE" = true ] && echo "Processing: $app_name" >&2
            # Check custom mappings first, then known mappings
            local cask=$(get_custom_mapping "$app_name")
            if [ -z "$cask" ]; then
                cask=$(get_cask_for_app_name "$app_name")
            fi
            
            if [ -n "$cask" ]; then
                # Check if cask is already installed
                if is_cask_installed "$cask"; then
                    already_migrated+=("$app_name (→ $cask)")
                else
                    migratable+=("${app_name}|${cask}")
                fi
            elif [ "$cask" = "" ] && [[ "$app_name" =~ ^(Finder|Safari|Mail|Messages|FaceTime|Calendar|Contacts|Maps|Photos|Music|TV|Podcasts|News|Stocks|Weather|Clock|Calculator|Chess|Dictionary|DVD Player|Font Book|Grapher|Image Capture|Keychain Access|Migration Assistant|Photo Theater|Preview|QuickTime Player|Stickies|System Preferences|TextEdit|Time Machine|VoiceOver Utility)$ ]]; then
                system_apps+=("$app_name")
            else
                # Skip brew search for now - just add to unknown
                unknown+=("$app_name")
            fi
        fi
    done <<< "$app_list"
    
    # Display results
    if [ ${#migratable[@]} -gt 0 ]; then
        print_color "$GREEN" "Apps that can be migrated to Homebrew:"
        for item in "${migratable[@]}"; do
            IFS='|' read -r name cask suggested <<< "$item"
            if [ "$suggested" = "suggested" ]; then
                echo "  • $name → $cask (suggested)"
            else
                echo "  • $name → $cask"
            fi
        done
        echo
    fi
    
    if [ ${#already_migrated[@]} -gt 0 ]; then
        print_color "$CYAN" "Apps already available via Homebrew:"
        for app in "${already_migrated[@]}"; do
            echo "  • $app"
        done
        echo
    fi
    
    if [ ${#system_apps[@]} -gt 0 ]; then
        print_color "$MAGENTA" "System apps (cannot be migrated):"
        for app in "${system_apps[@]}"; do
            echo "  • $app"
        done
        echo
    fi
    
    if [ ${#unknown[@]} -gt 0 ]; then
        print_color "$YELLOW" "Apps without known Homebrew equivalents:"
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
        IFS='|' read -r name cask suggested <<< "$item"
        
        if [ "$INTERACTIVE" = true ]; then
            echo
            if [ "$suggested" = "suggested" ]; then
                print_color "$YELLOW" "Suggested migration: $name → $cask"
                print_color "$CYAN" "This is an automatic suggestion and may not be exact"
            else
                print_color "$CYAN" "Migrate: $name → $cask"
            fi
            
            read -p "Proceed? (y/n/s=skip): " -n 1 -r
            echo
            
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_color "$YELLOW" "Skipped $name"
                continue
            fi
        fi
        
        if migrate_app "$name" "$cask"; then
            ((migrated++))
        else
            ((failed++))
        fi
    done
    
    # Summary
    echo
    print_color "$BLUE" "═══════════════════════════════════════════"
    print_color "$BLUE" "Migration Summary"
    print_color "$BLUE" "═══════════════════════════════════════════"
    print_color "$GREEN" "Successfully migrated: $migrated"
    [ $failed -gt 0 ] && print_color "$RED" "Failed: $failed"
    
    if [ "$DRY_RUN" = true ]; then
        echo
        print_color "$YELLOW" "This was a dry run - no changes were made"
        print_color "$CYAN" "Run with --execute to perform actual migration"
    else
        echo
        print_color "$YELLOW" "⚠️  Important: Manual cleanup required"
        print_color "$CYAN" "You must manually remove the old apps from /Applications"
        print_color "$CYAN" "The Homebrew versions are now installed and ready to use"
    fi
}

# Custom mappings storage (for current session)
CUSTOM_MAPPINGS=""

# Function to add custom mapping
add_custom_mapping() {
    local app_name=$1
    local cask_name=$2
    
    print_color "$CYAN" "Adding custom mapping: $app_name → $cask_name"
    
    # Add to custom mappings for current session
    CUSTOM_MAPPINGS="${CUSTOM_MAPPINGS}${app_name}:${cask_name};"
}

# Function to get custom mapping
get_custom_mapping() {
    local app_name=$1
    if [ -n "$CUSTOM_MAPPINGS" ]; then
        echo "$CUSTOM_MAPPINGS" | tr ';' '\n' | grep "^${app_name}:" | cut -d':' -f2
    fi
}

# Function to list all known mappings
list_mappings() {
    print_color "$BLUE" "Known Application to Homebrew Cask mappings:"
    print_color "$BLUE" "═══════════════════════════════════════════"
    
    # List all known mappings from the function
    cat << 'EOF'
Productivity:
  1Password 7 - Password Manager → 1password-7
  1Password 8 - Password Manager → 1password
  Affinity Photo → affinity-photo
  Affinity Designer → affinity-designer
  Affinity Publisher → affinity-publisher
  Alfred → alfred
  Bear → bear
  Bitwarden → bitwarden
  CleanMyMac X → cleanmymac
  Discord → discord
  Dropbox → dropbox
  Figma → figma
  Google Chrome → google-chrome
  Google Drive → google-drive
  Kindle → kindle
  Microsoft Excel → microsoft-excel
  Microsoft PowerPoint → microsoft-powerpoint
  Microsoft Word → microsoft-word
  Microsoft OneNote → microsoft-onenote
  Microsoft Outlook → microsoft-outlook
  Microsoft Teams → microsoft-teams
  Notion → notion
  Obsidian → obsidian
  Rectangle → rectangle
  Slack → slack
  Spotify → spotify
  Telegram → telegram
  Twitter → twitter
  WhatsApp → whatsapp
  Zoom → zoom

Development:
  Android Studio → android-studio
  Docker Desktop → docker
  GitHub Desktop → github
  GitKraken → gitkraken
  IntelliJ IDEA CE → intellij-idea-ce
  IntelliJ IDEA → intellij-idea
  JetBrains Toolbox → jetbrains-toolbox
  Postman → postman
  PyCharm CE → pycharm-ce
  PyCharm → pycharm
  Sublime Text → sublime-text
  TablePlus → tableplus
  Transmit 5 → transmit
  Visual Studio Code → visual-studio-code
  WebStorm → webstorm
  Xcode → xcode

Media:
  Adobe Photoshop 2024 → adobe-photoshop
  Adobe Illustrator 2024 → adobe-illustrator
  Adobe Premiere Pro 2024 → adobe-premiere-pro
  Adobe After Effects 2024 → adobe-after-effects
  Adobe Creative Cloud → adobe-creative-cloud
  Audacity → audacity
  Blender → blender
  DaVinci Resolve → davinci-resolve
  Final Cut Pro → final-cut-pro
  Handbrake → handbrake
  IINA → iina
  Logic Pro → logic-pro
  OBS Studio → obs
  Pixelmator Pro → pixelmator-pro
  Sketch → sketch
  VLC media player → vlc

Utilities:
  1Blocker- Ad Blocker & Privacy → 1blocker
  AppCleaner → appcleaner
  BetterTouchTool → bettertouchtool
  CleanMaster- Remove Junk Files → cleanmaster
  Hammerspoon → hammerspoon
  Karabiner-Elements → karabiner-elements
  Magnet → magnet
  Raycast → raycast
  The Unarchiver → the-unarchiver
  TopNotch → topnotch

Browsers:
  Arc → arc
  Brave Browser → brave-browser
  Firefox → firefox
  Microsoft Edge → microsoft-edge
  Opera → opera
EOF
    
    # Show custom mappings if any
    if [ -n "$CUSTOM_MAPPINGS" ]; then
        echo
        print_color "$CYAN" "Custom mappings (current session):"
        echo "$CUSTOM_MAPPINGS" | tr ';' '\n' | grep -v '^$' | while IFS=':' read -r app cask; do
            echo "  $app → $cask"
        done
    fi
}

# Show help
show_help() {
    cat << EOF
Mac Power Tools - Manual Apps to Homebrew Migration

Helps migrate manually downloaded apps from /Applications to Homebrew Cask 
versions for better management, updates, and automation.

USAGE:
    mac migrate-apps [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    -a, --analyze       Analyze apps and show migration opportunities
    -e, --execute       Execute migration (default is dry-run)
    -y, --yes           Non-interactive mode (migrate all)
    -l, --list          List known App to Cask mappings
    -m, --map APP CASK  Add custom App name to Cask mapping
    -v, --verbose       Show detailed output

EXAMPLES:
    # Analyze what can be migrated (safe, read-only)
    mac migrate-apps --analyze
    
    # Perform dry-run migration (default)
    mac migrate-apps
    
    # Execute actual migration interactively
    mac migrate-apps --execute
    
    # Migrate all without prompting
    mac migrate-apps --execute --yes
    
    # Add custom mapping and migrate
    mac migrate-apps --map "My App" my-app --execute

BENEFITS OF MIGRATION:
    • Homebrew casks update automatically with 'brew upgrade'
    • Unified package management with brew
    • Better automation and scripting support
    • Easier backup and restore of apps
    • Version pinning and rollback capabilities
    • No manual downloads or updates needed

SAFETY FEATURES:
    • Dry-run mode by default (no changes made)
    • Manual cleanup required (no automatic app deletion)
    • Interactive confirmation for each app
    • System apps are automatically excluded
    • Preserves app data and settings

NOTES:
    • This tool does NOT delete apps automatically
    • You must manually remove old apps after migration
    • App settings and data are typically preserved
    • Some apps may require re-authentication
    • Always test migrated apps before removing originals

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
                    print_color "$RED" "Error: --map requires APP_NAME and CASK_NAME"
                    exit 1
                fi
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            *)
                print_color "$RED" "Unknown option: $1"
                echo "Use 'mac migrate-apps --help' for usage"
                exit 1
                ;;
        esac
    done
    
    # Check dependencies
    if ! check_dependencies; then
        exit 1
    fi
    
    print_color "$BLUE" "═══════════════════════════════════════════"
    print_color "$BLUE" "Manual Apps to Homebrew Migration Tool"
    print_color "$BLUE" "═══════════════════════════════════════════"
    echo
    
    # Get migratable apps
    migratable_apps=()
    local migration_output=$(analyze_migration)
    while IFS= read -r line; do
        [[ -n "$line" ]] && migratable_apps+=("$line")
    done <<< "$migration_output"
    
    if [ ${#migratable_apps[@]} -eq 0 ] || [ -z "${migratable_apps[0]}" ]; then
        print_color "$YELLOW" "No apps found to migrate"
        print_color "$CYAN" "All your manually installed apps are either:"
        echo "  • Already available via Homebrew"
        echo "  • System apps that cannot be migrated"
        echo "  • Apps without known Homebrew equivalents"
        exit 0
    fi
    
    # If analyze only, we're done
    if [ "$analyze_only" = true ]; then
        exit 0
    fi
    
    # Confirm migration
    if [ "$DRY_RUN" = true ]; then
        print_color "$YELLOW" "Running in DRY RUN mode - no changes will be made"
    else
        print_color "$YELLOW" "⚠️  This will install Homebrew versions of your apps"
        print_color "$CYAN" "You will need to manually remove the old versions"
    fi
    
    if [ "$INTERACTIVE" = true ] && [ "$DRY_RUN" = false ]; then
        echo
        read -p "Continue with migration? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_color "$YELLOW" "Migration cancelled"
            exit 0
        fi
    fi
    
    # Perform migration
    perform_migration "${migratable_apps[@]}"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi