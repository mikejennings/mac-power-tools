#!/bin/bash

# Mac Power Tools - Application Uninstaller
# Completely removes applications and their associated files

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Dry run mode (default: false)
DRY_RUN=false

# Verbose mode
VERBOSE=false

# Function to print colored output
print_color() {
    local color=$1
    shift
    printf "${color}%s${NC}\n" "$*"
}

# Function to find app bundle
find_app_bundle() {
    local app_name="$1"
    local app_path=""
    
    # Check common locations
    if [[ -d "/Applications/${app_name}.app" ]]; then
        app_path="/Applications/${app_name}.app"
    elif [[ -d "/Applications/${app_name}" ]]; then
        app_path="/Applications/${app_name}"
    elif [[ -d "$HOME/Applications/${app_name}.app" ]]; then
        app_path="$HOME/Applications/${app_name}.app"
    elif [[ -d "$HOME/Applications/${app_name}" ]]; then
        app_path="$HOME/Applications/${app_name}"
    else
        # Try to find with mdfind
        app_path=$(mdfind "kMDItemKind == 'Application' && kMDItemDisplayName == '${app_name}'" 2>/dev/null | head -1)
    fi
    
    echo "$app_path"
}

# Function to get app bundle identifier
get_bundle_id() {
    local app_path="$1"
    local bundle_id=""
    
    if [[ -f "${app_path}/Contents/Info.plist" ]]; then
        bundle_id=$(defaults read "${app_path}/Contents/Info.plist" CFBundleIdentifier 2>/dev/null)
    fi
    
    echo "$bundle_id"
}

# Function to find related files
find_related_files() {
    local app_name="$1"
    local bundle_id="$2"
    local files=()
    
    # Clean app name for searching (remove .app extension if present)
    local clean_name="${app_name%.app}"
    
    # Escape special characters for safe searching
    local safe_name=$(echo "$clean_name" | sed 's/[^a-zA-Z0-9]//g')
    
    # User Library locations
    local user_dirs=(
        "$HOME/Library/Application Support"
        "$HOME/Library/Application Scripts"
        "$HOME/Library/Caches"
        "$HOME/Library/Containers"
        "$HOME/Library/Cookies"
        "$HOME/Library/Group Containers"
        "$HOME/Library/Internet Plug-Ins"
        "$HOME/Library/LaunchAgents"
        "$HOME/Library/Logs"
        "$HOME/Library/Preferences"
        "$HOME/Library/PreferencePanes"
        "$HOME/Library/Saved Application State"
        "$HOME/Library/WebKit"
    )
    
    # System Library locations (require sudo)
    local system_dirs=(
        "/Library/Application Support"
        "/Library/Caches"
        "/Library/Extensions"
        "/Library/Internet Plug-Ins"
        "/Library/LaunchAgents"
        "/Library/LaunchDaemons"
        "/Library/Logs"
        "/Library/PreferencePanes"
        "/Library/Preferences"
        "/Library/PrivilegedHelperTools"
        "/Library/StartupItems"
    )
    
    # Search by app name
    for dir in "${user_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            find "$dir" -maxdepth 2 -iname "*${safe_name}*" 2>/dev/null | while read -r file; do
                files+=("$file")
                echo "$file"
            done
        fi
    done
    
    # Search by bundle ID if available
    if [[ -n "$bundle_id" ]]; then
        for dir in "${user_dirs[@]}"; do
            if [[ -d "$dir" ]]; then
                find "$dir" -maxdepth 2 -iname "*${bundle_id}*" 2>/dev/null | while read -r file; do
                    files+=("$file")
                    echo "$file"
                done
            fi
        done
        
        # Search preference files
        find "$HOME/Library/Preferences" -name "${bundle_id}.plist*" 2>/dev/null | while read -r file; do
            files+=("$file")
            echo "$file"
        done
    fi
    
    # Check system directories (will need sudo for removal)
    for dir in "${system_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            find "$dir" -maxdepth 2 -iname "*${safe_name}*" 2>/dev/null | while read -r file; do
                files+=("$file")
                echo "$file"
            done
            
            if [[ -n "$bundle_id" ]]; then
                find "$dir" -maxdepth 2 -iname "*${bundle_id}*" 2>/dev/null | while read -r file; do
                    files+=("$file")
                    echo "$file"
                done
            fi
        fi
    done
}

# Function to calculate total size
calculate_size() {
    local total_size=0
    local file
    
    while read -r file; do
        if [[ -e "$file" ]]; then
            local size=$(du -sk "$file" 2>/dev/null | cut -f1)
            total_size=$((total_size + size))
        fi
    done
    
    # Convert to human readable
    if [[ $total_size -gt 1048576 ]]; then
        echo "$((total_size / 1024 / 1024)) GB"
    elif [[ $total_size -gt 1024 ]]; then
        echo "$((total_size / 1024)) MB"
    else
        echo "${total_size} KB"
    fi
}

# Function to check if app is running
is_app_running() {
    local app_name="$1"
    local clean_name="${app_name%.app}"
    
    pgrep -fi "$clean_name" > /dev/null 2>&1
}

# Function to quit application
quit_application() {
    local app_name="$1"
    local clean_name="${app_name%.app}"
    
    print_color "$YELLOW" "Quitting ${clean_name}..."
    
    # Try graceful quit first
    osascript -e "tell application \"${clean_name}\" to quit" 2>/dev/null
    
    sleep 2
    
    # Force quit if still running
    if is_app_running "$app_name"; then
        print_color "$YELLOW" "Force quitting ${clean_name}..."
        pkill -9 -fi "$clean_name" 2>/dev/null
    fi
}

# Function to remove files
remove_files() {
    local file="$1"
    
    if [[ "$DRY_RUN" == true ]]; then
        print_color "$CYAN" "[DRY RUN] Would remove: $file"
        return 0
    fi
    
    if [[ -e "$file" ]]; then
        # Check if we need sudo
        if [[ -w "$file" ]]; then
            rm -rf "$file" 2>/dev/null
        else
            sudo rm -rf "$file" 2>/dev/null
        fi
        
        if [[ ! -e "$file" ]]; then
            [[ "$VERBOSE" == true ]] && print_color "$GREEN" "Removed: $file"
            return 0
        else
            print_color "$RED" "Failed to remove: $file"
            return 1
        fi
    fi
}

# Function to uninstall application
uninstall_app() {
    local app_input="$1"
    local app_path=""
    local app_name=""
    
    # Determine if input is a path or name
    if [[ -d "$app_input" ]]; then
        app_path="$app_input"
        app_name=$(basename "$app_path" .app)
    else
        app_name="$app_input"
        app_path=$(find_app_bundle "$app_name")
    fi
    
    if [[ -z "$app_path" ]] || [[ ! -d "$app_path" ]]; then
        print_color "$RED" "Application not found: $app_input"
        return 1
    fi
    
    print_color "$BLUE" "═══════════════════════════════════════════"
    print_color "$BLUE" "Uninstalling: $app_name"
    print_color "$BLUE" "Location: $app_path"
    
    # Get bundle ID
    local bundle_id=$(get_bundle_id "$app_path")
    [[ -n "$bundle_id" ]] && print_color "$BLUE" "Bundle ID: $bundle_id"
    
    # Check if app is running
    if is_app_running "$app_name"; then
        quit_application "$app_name"
    fi
    
    # Find all related files
    print_color "$CYAN" "\nSearching for related files..."
    local related_files=$(find_related_files "$app_name" "$bundle_id" | sort -u)
    
    # Add the main app to the list
    local all_files=$(echo -e "${app_path}\n${related_files}" | grep -v '^$' | sort -u)
    
    # Calculate total size
    local total_size=$(echo "$all_files" | calculate_size)
    
    # Display files to be removed
    local file_count=$(echo "$all_files" | grep -c '^')
    print_color "$YELLOW" "\nFound $file_count items to remove (Total size: $total_size):"
    
    echo "$all_files" | while read -r file; do
        if [[ -e "$file" ]]; then
            if [[ "$file" == "$app_path" ]]; then
                print_color "$CYAN" "  • [APP] $file"
            elif [[ "$file" == /Library/* ]] || [[ "$file" == /System/* ]]; then
                print_color "$YELLOW" "  • [SYSTEM] $file"
            else
                echo "  • $file"
            fi
        fi
    done
    
    # Confirm removal
    if [[ "$DRY_RUN" != true ]]; then
        echo ""
        read -p "Do you want to remove all these files? (y/N): " -n 1 -r
        echo ""
        
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_color "$YELLOW" "Uninstall cancelled"
            return 1
        fi
    fi
    
    # Remove files
    print_color "$CYAN" "\nRemoving files..."
    local removed_count=0
    local failed_count=0
    
    echo "$all_files" | while read -r file; do
        if [[ -e "$file" ]]; then
            if remove_files "$file"; then
                ((removed_count++))
            else
                ((failed_count++))
            fi
        fi
    done
    
    # Clear Spotlight index for the app
    if [[ "$DRY_RUN" != true ]]; then
        mdutil -E "$HOME/Library" 2>/dev/null
    fi
    
    # Summary
    print_color "$GREEN" "\n✓ Uninstall complete!"
    [[ "$DRY_RUN" == true ]] && print_color "$CYAN" "This was a dry run - no files were actually removed"
    
    return 0
}

# Function to list installed applications
list_applications() {
    print_color "$BLUE" "Installed Applications:"
    print_color "$BLUE" "═══════════════════════════════════════════"
    
    # List from /Applications
    if [[ -d "/Applications" ]]; then
        print_color "$CYAN" "\nSystem Applications (/Applications):"
        ls -1 "/Applications" | grep -E '\.app$' | sed 's/\.app$//' | sort
    fi
    
    # List from ~/Applications
    if [[ -d "$HOME/Applications" ]]; then
        print_color "$CYAN" "\nUser Applications ($HOME/Applications):"
        ls -1 "$HOME/Applications" | grep -E '\.app$' | sed 's/\.app$//' | sort
    fi
}

# Show help
show_help() {
    cat << EOF
Mac Power Tools - Application Uninstaller

USAGE:
    mac uninstall [OPTIONS] <app_name>
    mac uninstall --list

OPTIONS:
    -h, --help      Show this help message
    -l, --list      List all installed applications
    -d, --dry-run   Show what would be removed without removing
    -v, --verbose   Show detailed output
    -f, --force     Skip confirmation prompt

ARGUMENTS:
    app_name        Name of the application to uninstall
                   Can be the app name or full path to .app bundle

EXAMPLES:
    mac uninstall "Google Chrome"
    mac uninstall /Applications/Slack.app
    mac uninstall --dry-run Firefox
    mac uninstall --list

NOTES:
    • Removes app and all associated files (caches, preferences, support files)
    • Automatically quits the app if it's running
    • Calculates total space to be freed
    • Some system files may require administrator password

EOF
}

# Main function
main() {
    local app_to_uninstall=""
    local force_mode=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -l|--list)
                list_applications
                exit 0
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -f|--force)
                force_mode=true
                shift
                ;;
            *)
                app_to_uninstall="$1"
                shift
                ;;
        esac
    done
    
    # Check if app name was provided
    if [[ -z "$app_to_uninstall" ]]; then
        print_color "$RED" "Error: No application specified"
        echo "Use 'mac uninstall --help' for usage information"
        exit 1
    fi
    
    # Uninstall the application
    uninstall_app "$app_to_uninstall"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi