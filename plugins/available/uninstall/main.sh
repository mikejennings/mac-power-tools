#!/bin/bash

# Native plugin implementation
# Migrated from legacy script to use plugin API

# Source the plugin API
source "${MAC_POWER_TOOLS_HOME}/lib/plugin-api.sh"




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
    
    print_warning "Quitting ${clean_name}..."
    
    # Try graceful quit first
    osascript -e "tell application \"${clean_name}\" to quit" 2>/dev/null
    
    sleep 2
    
    # Force quit if still running
    if is_app_running "$app_name"; then
        print_warning "Force quitting ${clean_name}..."
        pkill -9 -fi "$clean_name" 2>/dev/null
    fi
}

# Function to remove files
remove_files() {
    local file="$1"
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Would remove: $file"
        return 0
    fi
    
    # Validate path to prevent traversal attacks
    # Check if security utilities are available
    if type -t validate_path >/dev/null 2>&1; then
        if ! validate_path "$file"; then
            print_error "Invalid or unsafe path: $file"
            return 1
        fi
    else
        # Basic path validation fallback
        # Prevent path traversal with ..
        if [[ "$file" =~ \.\. ]]; then
            print_error "Path traversal detected in: $file"
            return 1
        fi
        # Ensure path is within safe directories
        if [[ ! "$file" =~ ^(/Applications|/Library|/Users|$HOME) ]]; then
            print_error "Path outside safe directories: $file"
            return 1
        fi
    fi
    
    if [[ -e "$file" ]]; then
        # Check if we need sudo
        if [[ -w "$file" ]]; then
            rm -rf "$file" 2>/dev/null
        else
            sudo rm -rf "$file" 2>/dev/null
        fi
        
        if [[ ! -e "$file" ]]; then
            [[ "$VERBOSE" == true ]] && print_success "Removed: $file"
            return 0
        else
            print_error "Failed to remove: $file"
            return 1
        fi
    fi
}

# Function to uninstall application
uninstall_app() {
    local app_input="$1"
    local app_path=""
    local app_name=""
    
    # Sanitize input to prevent injection
    # Check if security utilities are available
    if type -t sanitize_input >/dev/null 2>&1; then
        app_input=$(sanitize_input "$app_input")
    else
        # Basic sanitization fallback
        # Remove dangerous characters
        app_input="${app_input//[;|&\$\`<>(){}[]]/}"
        # Limit length
        if [[ ${#app_input} -gt 255 ]]; then
            print_error "App name too long"
            return 1
        fi
    fi
    
    # Determine if input is a path or name
    if [[ -d "$app_input" ]]; then
        app_path="$app_input"
        app_name=$(basename "$app_path" .app)
    else
        app_name="$app_input"
        app_path=$(find_app_bundle "$app_name")
    fi
    
    if [[ -z "$app_path" ]] || [[ ! -d "$app_path" ]]; then
        print_error "Application not found: $app_input"
        return 1
    fi
    
    print_info "═══════════════════════════════════════════"
    print_info "Uninstalling: $app_name"
    print_info "Location: $app_path"
    
    # Get bundle ID
    local bundle_id=$(get_bundle_id "$app_path")
    [[ -n "$bundle_id" ]] && print_info "Bundle ID: $bundle_id"
    
    # Check if app is running
    if is_app_running "$app_name"; then
        quit_application "$app_name"
    fi
    
    # Find all related files
    echo
    print_info "Searching for related files..."
    local related_files=$(find_related_files "$app_name" "$bundle_id" | sort -u)
    
    # Add the main app to the list
    local all_files=$(echo -e "${app_path}\n${related_files}" | grep -v '^$' | sort -u)
    
    # Calculate total size
    local total_size=$(echo "$all_files" | calculate_size)
    
    # Display files to be removed
    local file_count=$(echo "$all_files" | grep -c '^')
    echo
    print_warning "Found $file_count items to remove (Total size: $total_size):"
    
    echo "$all_files" | while read -r file; do
        if [[ -e "$file" ]]; then
            if [[ "$file" == "$app_path" ]]; then
                print_info "  • [APP] $file"
            elif [[ "$file" == /Library/* ]] || [[ "$file" == /System/* ]]; then
                print_warning "  • [SYSTEM] $file"
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
            print_warning "Uninstall cancelled"
            return 1
        fi
    fi
    
    # Remove files
    echo
    print_info "Removing files..."
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
    echo
    print_success "✓ Uninstall complete!"
    [[ "$DRY_RUN" == true ]] && print_info "This was a dry run - no files were actually removed"
    
    return 0
}

# Function to list installed applications
list_applications() {
    print_info "Installed Applications:"
    print_info "═══════════════════════════════════════════"
    
    # List from /Applications
    if [[ -d "/Applications" ]]; then
        echo
        print_info "System Applications (/Applications):"
        ls -1 "/Applications" | grep -E '\.app$' | sed 's/\.app$//' | sort
    fi
    
    # List from ~/Applications
    if [[ -d "$HOME/Applications" ]]; then
        echo
        print_info "User Applications ($HOME/Applications):"
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
        print_error "Error: No application specified"
        echo "Use 'mac uninstall --help' for usage information"
        exit 1
    fi
    
    # Uninstall the application
    uninstall_app "$app_to_uninstall"
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
