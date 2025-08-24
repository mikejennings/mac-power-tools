#!/bin/bash

# Plugin Manager - Install, remove, enable, disable plugins

# Source required libraries
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "${SCRIPT_DIR}/plugin-api.sh"
source "${SCRIPT_DIR}/plugin-loader.sh"

# Plugin manager main function
plugin_manager_main() {
    local action=$1
    shift
    
    case "$action" in
        list)
            list_plugins "$@"
            ;;
        install)
            install_plugin "$@"
            ;;
        remove|uninstall)
            remove_plugin "$@"
            ;;
        enable)
            enable_plugin "$@"
            ;;
        disable)
            disable_plugin "$@"
            ;;
        info)
            plugin_info "$@"
            ;;
        search)
            search_plugins "$@"
            ;;
        update)
            update_plugins "$@"
            ;;
        check-updates)
            check_plugin_updates "$@"
            ;;
        *)
            show_plugin_manager_help
            ;;
    esac
}

# Show help for plugin manager
show_plugin_manager_help() {
    printf "${BLUE}Mac Power Tools Plugin Manager${NC}\n\n"
    printf "${YELLOW}USAGE:${NC}\n"
    printf "    mac plugin <command> [options]\n\n"
    printf "${YELLOW}COMMANDS:${NC}\n"
    printf "    list              List all plugins (installed and available)\n"
    printf "    install <name>    Install a plugin\n"
    printf "    remove <name>     Remove a plugin\n"
    printf "    enable <name>     Enable a plugin\n"
    printf "    disable <name>    Disable a plugin\n"
    printf "    info <name>       Show plugin information\n"
    printf "    search <term>     Search for plugins\n"
    printf "    update [name]     Update plugin(s) from GitHub\n"
    printf "    check-updates     Check for available updates\n"
}

# List all plugins
list_plugins() {
    local filter=${1:-all}
    
    printf "${BLUE}=== Core Plugins (Always Enabled) ===${NC}\n"
    if [ -d "$CORE_DIR" ]; then
        for plugin in "$CORE_DIR"/*; do
            [ -d "$plugin" ] && display_plugin_status "$plugin" "core"
        done
    fi
    
    printf "\n${BLUE}=== Available Plugins ===${NC}\n"
    if [ -d "$AVAILABLE_DIR" ]; then
        for plugin in "$AVAILABLE_DIR"/*; do
            if [ -d "$plugin" ]; then
                local plugin_name=$(basename "$plugin")
                if is_plugin_enabled "$plugin_name"; then
                    display_plugin_status "$plugin" "enabled"
                else
                    [ "$filter" != "enabled" ] && display_plugin_status "$plugin" "disabled"
                fi
            fi
        done
    fi
}

# Display plugin status
display_plugin_status() {
    local plugin_path=$1
    local status=$2
    local plugin_name=$(basename "$plugin_path")
    local metadata=$(get_plugin_metadata "$plugin_path")
    
    local version=$(echo "$metadata" | grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
    local description=$(echo "$metadata" | grep -o '"description"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
    
    case "$status" in
        core)
            printf "  ${CYAN}●${NC} %-20s v%-8s %s\n" "$plugin_name" "$version" "$description"
            ;;
        enabled)
            printf "  ${GREEN}●${NC} %-20s v%-8s %s\n" "$plugin_name" "$version" "$description"
            ;;
        disabled)
            printf "  ${YELLOW}○${NC} %-20s v%-8s %s\n" "$plugin_name" "$version" "$description"
            ;;
    esac
}

# Install a plugin
install_plugin() {
    local plugin_source=$1
    
    if [ -z "$plugin_source" ]; then
        print_error "Please specify a plugin to install"
        return 1
    fi
    
    # Check if it's a URL (GitHub repo)
    if [[ "$plugin_source" =~ ^https?:// ]]; then
        install_from_url "$plugin_source"
    # Check if it's a local directory
    elif [ -d "$plugin_source" ]; then
        install_from_directory "$plugin_source"
    # Check if it's a plugin name from registry
    else
        install_from_registry "$plugin_source"
    fi
}

# Install plugin from URL (GitHub)
install_from_url() {
    local url=$1
    local temp_dir=$(mktemp -d)
    local plugin_name
    
    print_info "Downloading plugin from $url..."
    
    # Validate URL to prevent command injection
    # Check if security utilities are available
    if type -t validate_url >/dev/null 2>&1; then
        if ! validate_url "$url"; then
            print_error "Invalid or unsafe URL provided"
            rm -rf "$temp_dir"
            return 1
        fi
    else
        # Fallback validation if security-utils.sh not loaded
        # Only allow HTTPS URLs from GitHub, GitLab, or Bitbucket
        if ! [[ "$url" =~ ^https://((github|gitlab|bitbucket)\.(com|org)|[a-zA-Z0-9.-]+\.(github|gitlab)\.io)/[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+(\.git)?$ ]]; then
            print_error "URL must be a valid HTTPS repository URL from GitHub, GitLab, or Bitbucket"
            rm -rf "$temp_dir"
            return 1
        fi
        
        # Check for command injection characters
        if [[ "$url" =~ [';|&$`<>(){}[]'] ]]; then
            print_error "URL contains invalid characters"
            rm -rf "$temp_dir"
            return 1
        fi
    fi
    
    # Clone or download the plugin
    if command_exists git; then
        git clone "$url" "$temp_dir/plugin" 2>/dev/null || {
            print_error "Failed to download plugin"
            rm -rf "$temp_dir"
            return 1
        }
    else
        print_error "Git is required to install plugins from URLs"
        return 1
    fi
    
    # Get plugin name from metadata
    if [ -f "$temp_dir/plugin/plugin.json" ]; then
        plugin_name=$(grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' "$temp_dir/plugin/plugin.json" | cut -d'"' -f4)
    else
        plugin_name=$(basename "$url" .git)
    fi
    
    # Install to available directory
    local target_dir="${AVAILABLE_DIR}/${plugin_name}"
    if [ -d "$target_dir" ]; then
        if ! confirm "Plugin '$plugin_name' already exists. Overwrite?"; then
            rm -rf "$temp_dir"
            return 1
        fi
        rm -rf "$target_dir"
    fi
    
    mv "$temp_dir/plugin" "$target_dir"
    rm -rf "$temp_dir"
    
    print_success "Plugin '$plugin_name' installed successfully"
    
    # Ask to enable
    if confirm "Enable plugin now?"; then
        enable_plugin "$plugin_name"
    fi
}

# Install plugin from local directory
install_from_directory() {
    local source_dir=$1
    local plugin_name
    
    # Get plugin name from metadata
    if [ -f "$source_dir/plugin.json" ]; then
        plugin_name=$(grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' "$source_dir/plugin.json" | cut -d'"' -f4)
    else
        plugin_name=$(basename "$source_dir")
    fi
    
    local target_dir="${AVAILABLE_DIR}/${plugin_name}"
    
    print_info "Installing plugin '$plugin_name' from local directory..."
    
    if [ -d "$target_dir" ]; then
        if ! confirm "Plugin '$plugin_name' already exists. Overwrite?"; then
            return 1
        fi
        rm -rf "$target_dir"
    fi
    
    cp -r "$source_dir" "$target_dir"
    print_success "Plugin '$plugin_name' installed successfully"
    
    # Ask to enable
    if confirm "Enable plugin now?"; then
        enable_plugin "$plugin_name"
    fi
}

# Install from plugin registry
install_from_registry() {
    local plugin_name=$1
    local registry_url="https://raw.githubusercontent.com/mac-power-tools/plugin-registry/main/plugins.json"
    
    print_info "Searching for '$plugin_name' in plugin registry..."
    
    # TODO(human): Implement fetching from plugin registry
    # The registry should contain a JSON file with plugin metadata:
    # {
    #   "plugins": [
    #     {
    #       "name": "network-monitor",
    #       "url": "https://github.com/user/mac-network-monitor",
    #       "description": "Real-time network monitoring",
    #       "author": "community"
    #     }
    #   ]
    # }
    
    print_warning "Plugin registry not yet available. Please use a direct URL or local path."
    return 1
}

# Remove a plugin
remove_plugin() {
    local plugin_name=$1
    
    if [ -z "$plugin_name" ]; then
        print_error "Please specify a plugin to remove"
        return 1
    fi
    
    # Can't remove core plugins
    if [ -d "${CORE_DIR}/${plugin_name}" ]; then
        print_error "Cannot remove core plugin '$plugin_name'"
        return 1
    fi
    
    local plugin_dir="${AVAILABLE_DIR}/${plugin_name}"
    
    if [ ! -d "$plugin_dir" ]; then
        print_error "Plugin '$plugin_name' not found"
        return 1
    fi
    
    if confirm "Remove plugin '$plugin_name'?"; then
        # First disable it
        disable_plugin "$plugin_name" 2>/dev/null
        
        # Then remove it
        rm -rf "$plugin_dir"
        print_success "Plugin '$plugin_name' removed"
    fi
}

# Enable a plugin
enable_plugin() {
    local plugin_name=$1
    
    if [ -z "$plugin_name" ]; then
        print_error "Please specify a plugin to enable"
        return 1
    fi
    
    # Core plugins are always enabled
    if [ -d "${CORE_DIR}/${plugin_name}" ]; then
        print_info "Core plugin '$plugin_name' is always enabled"
        return 0
    fi
    
    local plugin_dir="${AVAILABLE_DIR}/${plugin_name}"
    
    if [ ! -d "$plugin_dir" ]; then
        print_error "Plugin '$plugin_name' not found"
        return 1
    fi
    
    # Create symlink in enabled directory
    ln -sf "$plugin_dir" "${ENABLED_DIR}/${plugin_name}"
    
    # Update config file
    if grep -q "^${plugin_name}=" "$CONFIG_FILE"; then
        sed -i.bak "s/^${plugin_name}=.*/${plugin_name}=enabled/" "$CONFIG_FILE"
    else
        echo "${plugin_name}=enabled" >> "$CONFIG_FILE"
    fi
    
    print_success "Plugin '$plugin_name' enabled"
}

# Disable a plugin
disable_plugin() {
    local plugin_name=$1
    
    if [ -z "$plugin_name" ]; then
        print_error "Please specify a plugin to disable"
        return 1
    fi
    
    # Can't disable core plugins
    if [ -d "${CORE_DIR}/${plugin_name}" ]; then
        print_error "Cannot disable core plugin '$plugin_name'"
        return 1
    fi
    
    # Remove symlink from enabled directory
    rm -f "${ENABLED_DIR}/${plugin_name}"
    
    # Update config file
    if grep -q "^${plugin_name}=" "$CONFIG_FILE"; then
        sed -i.bak "s/^${plugin_name}=.*/${plugin_name}=disabled/" "$CONFIG_FILE"
    else
        echo "${plugin_name}=disabled" >> "$CONFIG_FILE"
    fi
    
    print_success "Plugin '$plugin_name' disabled"
}

# Show plugin information
plugin_info() {
    local plugin_name=$1
    
    if [ -z "$plugin_name" ]; then
        print_error "Please specify a plugin"
        return 1
    fi
    
    local plugin_dir
    if [ -d "${CORE_DIR}/${plugin_name}" ]; then
        plugin_dir="${CORE_DIR}/${plugin_name}"
    elif [ -d "${AVAILABLE_DIR}/${plugin_name}" ]; then
        plugin_dir="${AVAILABLE_DIR}/${plugin_name}"
    else
        print_error "Plugin '$plugin_name' not found"
        return 1
    fi
    
    local metadata=$(get_plugin_metadata "$plugin_dir")
    
    printf "${BLUE}Plugin: ${plugin_name}${NC}\n"
    printf "Location: %s\n" "$plugin_dir"
    
    # Parse and display metadata
    echo "$metadata" | python3 -m json.tool 2>/dev/null || echo "$metadata"
    
    # Show if enabled
    if is_plugin_enabled "$plugin_name"; then
        printf "\n${GREEN}Status: Enabled${NC}\n"
    else
        printf "\n${YELLOW}Status: Disabled${NC}\n"
    fi
}

# Search for plugins
search_plugins() {
    local search_term=$1
    
    if [ -z "$search_term" ]; then
        list_plugins
        return
    fi
    
    print_info "Searching for plugins matching '$search_term'..."
    
    # Search in installed plugins
    for plugin_dir in "$CORE_DIR"/* "$AVAILABLE_DIR"/*; do
        if [ -d "$plugin_dir" ]; then
            local plugin_name=$(basename "$plugin_dir")
            local metadata=$(get_plugin_metadata "$plugin_dir")
            
            # Search in name and description
            if echo "$plugin_name $metadata" | grep -qi "$search_term"; then
                local status="disabled"
                [ -d "${CORE_DIR}/${plugin_name}" ] && status="core"
                is_plugin_enabled "$plugin_name" && status="enabled"
                display_plugin_status "$plugin_dir" "$status"
            fi
        fi
    done
    
    # TODO: Search in online registry
}

# Check for plugin updates
check_plugin_updates() {
    local plugin_name=$1
    local has_updates=false
    
    print_info "Checking for plugin updates..."
    
    if [ -n "$plugin_name" ]; then
        # Check specific plugin
        check_single_plugin_update "$plugin_name"
    else
        # Check all plugins from GitHub
        for plugin_dir in "$AVAILABLE_DIR"/*; do
            if [ -d "$plugin_dir" ]; then
                local name=$(basename "$plugin_dir")
                if check_single_plugin_update "$name"; then
                    has_updates=true
                fi
            fi
        done
        
        if ! $has_updates; then
            print_success "All plugins are up to date"
        fi
    fi
}

# Check single plugin for updates
check_single_plugin_update() {
    local plugin_name=$1
    local plugin_dir="${AVAILABLE_DIR}/${plugin_name}"
    
    if [ ! -d "$plugin_dir" ]; then
        return 1
    fi
    
    # Check if plugin has .git directory (installed from GitHub)
    if [ ! -d "$plugin_dir/.git" ]; then
        return 1
    fi
    
    # Get current version
    local current_version=$(get_plugin_version "$plugin_dir")
    
    # Fetch latest from remote
    (
        cd "$plugin_dir"
        git fetch origin main 2>/dev/null || git fetch origin master 2>/dev/null
    )
    
    # Check if there are updates
    local behind=$(cd "$plugin_dir" && git rev-list HEAD..origin/main --count 2>/dev/null || \
                   git rev-list HEAD..origin/master --count 2>/dev/null)
    
    if [ "$behind" -gt 0 ]; then
        print_warning "Update available for $plugin_name (current: $current_version)"
        
        # Try to get remote version
        local remote_version=$(cd "$plugin_dir" && \
            git show origin/main:plugin.json 2>/dev/null | grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4 || \
            git show origin/master:plugin.json 2>/dev/null | grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
        
        if [ -n "$remote_version" ]; then
            printf "  New version: %s\n" "$remote_version"
        fi
        
        return 0
    fi
    
    return 1
}

# Update plugins
update_plugins() {
    local plugin_name=$1
    
    if [ -n "$plugin_name" ]; then
        # Update specific plugin
        update_single_plugin "$plugin_name"
    else
        # Update all plugins
        print_info "Updating all plugins from GitHub..."
        
        local updated=0
        local failed=0
        
        for plugin_dir in "$AVAILABLE_DIR"/*; do
            if [ -d "$plugin_dir" ] && [ -d "$plugin_dir/.git" ]; then
                local name=$(basename "$plugin_dir")
                if update_single_plugin "$name"; then
                    ((updated++))
                else
                    ((failed++))
                fi
            fi
        done
        
        print_info "Update complete: $updated updated, $failed failed"
    fi
}

# Update single plugin
update_single_plugin() {
    local plugin_name=$1
    local plugin_dir="${AVAILABLE_DIR}/${plugin_name}"
    
    if [ ! -d "$plugin_dir" ]; then
        print_error "Plugin not found: $plugin_name"
        return 1
    fi
    
    if [ ! -d "$plugin_dir/.git" ]; then
        print_warning "$plugin_name was not installed from GitHub, cannot update"
        return 1
    fi
    
    print_info "Updating $plugin_name..."
    
    # Store current version
    local current_version=$(get_plugin_version "$plugin_dir")
    
    # Create backup
    local backup_dir="${plugin_dir}.backup.$(date +%Y%m%d%H%M%S)"
    cp -r "$plugin_dir" "$backup_dir"
    
    # Attempt update
    local update_success=false
    (
        cd "$plugin_dir"
        
        # Stash any local changes
        git stash push -m "Auto-stash before plugin update" 2>/dev/null
        
        # Pull latest changes
        if git pull origin main 2>/dev/null || git pull origin master 2>/dev/null; then
            update_success=true
        fi
        
        # Restore stashed changes if any
        git stash pop 2>/dev/null || true
    )
    
    if [ "$?" -eq 0 ]; then
        # Validate updated plugin
        source "${SCRIPT_DIR}/plugin-security.sh"
        if validate_plugin "$plugin_dir"; then
            local new_version=$(get_plugin_version "$plugin_dir")
            
            if [ "$current_version" != "$new_version" ]; then
                print_success "$plugin_name updated from $current_version to $new_version"
                
                # Remove backup
                rm -rf "$backup_dir"
                
                # Re-sign plugin if it was signed
                if [ -f "$plugin_dir/.checksum" ]; then
                    sign_plugin "$plugin_dir"
                fi
                
                return 0
            else
                print_info "$plugin_name is already up to date ($current_version)"
                rm -rf "$backup_dir"
                return 0
            fi
        else
            # Validation failed, restore backup
            print_error "Updated plugin failed validation, restoring backup..."
            rm -rf "$plugin_dir"
            mv "$backup_dir" "$plugin_dir"
            return 1
        fi
    else
        # Update failed, restore backup
        print_error "Failed to update $plugin_name, restoring backup..."
        rm -rf "$plugin_dir"
        mv "$backup_dir" "$plugin_dir"
        return 1
    fi
}

# Get plugin version
get_plugin_version() {
    local plugin_dir=$1
    local metadata_file="$plugin_dir/plugin.json"
    
    if [ -f "$metadata_file" ]; then
        if command -v jq &> /dev/null; then
            jq -r '.version // "unknown"' "$metadata_file"
        else
            grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$metadata_file" | cut -d'"' -f4 || echo "unknown"
        fi
    else
        echo "unknown"
    fi
}

# Compare versions (simple semantic versioning)
compare_versions() {
    local version1=$1
    local version2=$2
    
    # Remove 'v' prefix if present
    version1=${version1#v}
    version2=${version2#v}
    
    # Split versions into components
    IFS='.' read -r -a v1_parts <<< "$version1"
    IFS='.' read -r -a v2_parts <<< "$version2"
    
    # Compare major.minor.patch
    for i in 0 1 2; do
        local v1_part=${v1_parts[$i]:-0}
        local v2_part=${v2_parts[$i]:-0}
        
        if [ "$v1_part" -gt "$v2_part" ]; then
            echo "1"  # version1 is newer
            return
        elif [ "$v1_part" -lt "$v2_part" ]; then
            echo "-1"  # version2 is newer
            return
        fi
    done
    
    echo "0"  # versions are equal
}