#!/bin/bash

# Plugin Loader - Discovers and loads plugins dynamically

# Get the base directory
PLUGIN_BASE_DIR="${MAC_POWER_TOOLS_HOME:-$(dirname "$(dirname "${BASH_SOURCE[0]}")")}"
PLUGINS_DIR="${PLUGIN_BASE_DIR}/plugins"
ENABLED_DIR="${PLUGINS_DIR}/enabled"
AVAILABLE_DIR="${PLUGINS_DIR}/available"
CORE_DIR="${PLUGINS_DIR}/core"
CONFIG_FILE="${PLUGIN_BASE_DIR}/config/plugins.conf"

# Source the plugin API, security, and cache
source "${PLUGIN_BASE_DIR}/lib/plugin-api.sh"
[ -f "${PLUGIN_BASE_DIR}/lib/plugin-security.sh" ] && source "${PLUGIN_BASE_DIR}/lib/plugin-security.sh"
[ -f "${PLUGIN_BASE_DIR}/lib/plugin-cache.sh" ] && source "${PLUGIN_BASE_DIR}/lib/plugin-cache.sh"

# Initialize plugin directories
init_plugin_dirs() {
    mkdir -p "$ENABLED_DIR" "$AVAILABLE_DIR" "$CORE_DIR" "$(dirname "$CONFIG_FILE")"
    
    # Create default config if not exists
    if [ ! -f "$CONFIG_FILE" ]; then
        cat > "$CONFIG_FILE" <<EOF
# Mac Power Tools Plugin Configuration
# Format: plugin_name=enabled|disabled

# Core plugins (always enabled)
help=enabled
version=enabled

# Optional plugins
battery=enabled
network=enabled
disk=enabled
memory=enabled
update=enabled
info=enabled
maintenance=enabled
EOF
    fi
}

# Get plugin metadata
get_plugin_metadata() {
    local plugin_path=$1
    local plugin_name=$(basename "$plugin_path")
    
    # Try cache first if available
    if declare -f get_cached_plugin_metadata &>/dev/null; then
        local cached=$(get_cached_plugin_metadata "$plugin_name")
        if [ "$cached" != "null" ] && [ -n "$cached" ]; then
            echo "$cached"
            return 0
        fi
    fi
    
    # Fall back to reading file
    local metadata_file="${plugin_path}/plugin.json"
    
    if [ -f "$metadata_file" ]; then
        cat "$metadata_file"
    else
        # Fallback for plugins without metadata
        echo "{\"name\": \"$(basename "$plugin_path")\", \"version\": \"1.0.0\"}"
    fi
}

# Check if plugin is enabled
is_plugin_enabled() {
    local plugin_name=$1
    
    # Core plugins are always enabled
    if [ -d "${CORE_DIR}/${plugin_name}" ]; then
        return 0
    fi
    
    # Check if symlink exists in enabled directory
    if [ -L "${ENABLED_DIR}/${plugin_name}" ]; then
        return 0
    fi
    
    # Check config file
    if [ -f "$CONFIG_FILE" ]; then
        local status=$(grep "^${plugin_name}=" "$CONFIG_FILE" | cut -d= -f2)
        [ "$status" = "enabled" ] && return 0
    fi
    
    return 1
}

# Load a single plugin
load_plugin() {
    local plugin_path=$1
    local plugin_name=$(basename "$plugin_path")
    
    # Skip if disabled
    if ! is_plugin_enabled "$plugin_name"; then
        return 1
    fi
    
    # Validate plugin before loading (if security is enabled)
    if declare -f validate_plugin &>/dev/null; then
        if ! validate_plugin "$plugin_path"; then
            print_error "Plugin failed security validation: $plugin_name"
            return 1
        fi
    fi
    
    # Set plugin environment
    export MAC_PLUGIN_DIR="$plugin_path"
    export MAC_PLUGIN_NAME="$plugin_name"
    
    # Get metadata
    local metadata=$(get_plugin_metadata "$plugin_path")
    export MAC_PLUGIN_VERSION=$(echo "$metadata" | grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
    
    # Source the main plugin file with error handling
    local main_file="${plugin_path}/main.sh"
    if [ -f "$main_file" ]; then
        # Load plugin in a subshell to catch errors
        (
            set -e
            source "$main_file"
        ) 2>/dev/null
        
        if [ $? -eq 0 ]; then
            # Load succeeded, source in main shell
            source "$main_file"
            return 0
        else
            print_error "Failed to load plugin: $plugin_name"
            return 1
        fi
    fi
    
    return 1
}

# Discover all available plugins
discover_plugins() {
    local plugins=()
    
    # Find core plugins
    if [ -d "$CORE_DIR" ]; then
        for plugin in "$CORE_DIR"/*; do
            [ -d "$plugin" ] && plugins+=("$plugin")
        done
    fi
    
    # Find available plugins
    if [ -d "$AVAILABLE_DIR" ]; then
        for plugin in "$AVAILABLE_DIR"/*; do
            [ -d "$plugin" ] && plugins+=("$plugin")
        done
    fi
    
    # Find enabled plugins (symlinks)
    if [ -d "$ENABLED_DIR" ]; then
        for plugin in "$ENABLED_DIR"/*; do
            if [ -L "$plugin" ]; then
                local target=$(readlink "$plugin")
                [ -d "$target" ] && plugins+=("$target")
            fi
        done
    fi
    
    # Remove duplicates
    printf '%s\n' "${plugins[@]}" | sort -u
}

# Load all enabled plugins
load_all_plugins() {
    init_plugin_dirs
    
    local plugins=($(discover_plugins))
    local loaded=0
    local failed=0
    
    for plugin in "${plugins[@]}"; do
        if load_plugin "$plugin"; then
            ((loaded++))
        else
            ((failed++))
        fi
    done
    
    # Return number of loaded plugins
    echo "$loaded"
}

# Get list of available commands from plugins
get_plugin_commands() {
    local commands=()
    
    for plugin_dir in $(discover_plugins); do
        local plugin_name=$(basename "$plugin_dir")
        if is_plugin_enabled "$plugin_name"; then
            local metadata_file="${plugin_dir}/plugin.json"
            if [ -f "$metadata_file" ]; then
                # Extract commands from metadata
                local plugin_commands=$(grep -o '"commands"[[:space:]]*:[[:space:]]*\[[^]]*\]' "$metadata_file" | \
                    sed 's/.*\[//;s/\].*//;s/"//g;s/,/ /g')
                commands+=($plugin_commands)
            else
                # Fallback: use plugin name as command
                commands+=("$plugin_name")
            fi
        fi
    done
    
    printf '%s\n' "${commands[@]}" | sort -u
}

# Execute plugin command
execute_plugin_command() {
    local command=$1
    shift
    
    # Try cache first for O(1) lookup
    local plugin_name=""
    if declare -f get_plugin_for_command &>/dev/null; then
        plugin_name=$(get_plugin_for_command "$command")
    fi
    
    if [ "$plugin_name" != "null" ] && [ -n "$plugin_name" ]; then
        # Found in cache, execute directly
        local plugin_dir=""
        for dir in "$CORE_DIR" "$AVAILABLE_DIR"; do
            if [ -d "$dir/$plugin_name" ]; then
                plugin_dir="$dir/$plugin_name"
                break
            fi
        done
        
        if [ -n "$plugin_dir" ] && is_plugin_enabled "$plugin_name"; then
            # Set up plugin environment
            export MAC_PLUGIN_DIR="$plugin_dir"
            export MAC_PLUGIN_NAME="$plugin_name"
            
            # Execute plugin with error boundaries
            local main_file="${plugin_dir}/main.sh"
            if [ -f "$main_file" ]; then
                # Wrap execution in error handling
                (
                    set -e
                    source "$main_file"
                    
                    # Call plugin's main function if it exists
                    if declare -f "plugin_main" > /dev/null; then
                        plugin_main "$@"
                    elif declare -f "${command}_main" > /dev/null; then
                        "${command}_main" "$@"
                    fi
                )
                return $?
            fi
        fi
    fi
    
    # Fallback to linear search if not in cache
    for plugin_dir in $(discover_plugins); do
        local plugin_name=$(basename "$plugin_dir")
        if is_plugin_enabled "$plugin_name"; then
            local metadata_file="${plugin_dir}/plugin.json"
            local handles_command=false
            
            if [ -f "$metadata_file" ]; then
                # Check if plugin handles this command
                if grep -q "\"commands\".*\"$command\"" "$metadata_file"; then
                    handles_command=true
                fi
            elif [ "$plugin_name" = "$command" ]; then
                handles_command=true
            fi
            
            if $handles_command; then
                # Set up plugin environment
                export MAC_PLUGIN_DIR="$plugin_dir"
                export MAC_PLUGIN_NAME="$plugin_name"
                
                # Execute plugin with error boundaries
                local main_file="${plugin_dir}/main.sh"
                if [ -f "$main_file" ]; then
                    (
                        set -e
                        source "$main_file"
                        
                        # Call plugin's main function if it exists
                        if declare -f "plugin_main" > /dev/null; then
                            plugin_main "$@"
                        elif declare -f "${command}_main" > /dev/null; then
                            "${command}_main" "$@"
                        fi
                    )
                    return $?
                fi
            fi
        fi
    done
    
    return 1
}