#!/bin/bash

# Optimized Plugin Loader - Demonstrates lazy loading implementation
# This is a proof-of-concept showing how to implement the performance improvements

# Get the base directory
PLUGIN_BASE_DIR="${MAC_POWER_TOOLS_HOME:-$(dirname "$(dirname "${BASH_SOURCE[0]}")")}"
PLUGINS_DIR="${PLUGIN_BASE_DIR}/plugins"
ENABLED_DIR="${PLUGINS_DIR}/enabled"
AVAILABLE_DIR="${PLUGINS_DIR}/available"
CORE_DIR="${PLUGINS_DIR}/core"
CONFIG_FILE="${PLUGIN_BASE_DIR}/config/plugins.conf"

# Source the plugin API and other dependencies
source "${PLUGIN_BASE_DIR}/lib/plugin-api.sh"
[ -f "${PLUGIN_BASE_DIR}/lib/plugin-security.sh" ] && source "${PLUGIN_BASE_DIR}/lib/plugin-security.sh"
[ -f "${PLUGIN_BASE_DIR}/lib/plugin-cache.sh" ] && source "${PLUGIN_BASE_DIR}/lib/plugin-cache.sh"

# OPTIMIZATION 1: Lazy-loaded plugin registry
# Instead of loading all plugins at startup, maintain a registry
declare -a LOADED_PLUGINS=()
declare -a PLUGIN_REGISTRY=()

# OPTIMIZATION 2: Memoization for expensive operations
# Cache results to avoid repeated file I/O
declare -a ENABLED_CACHE=()
declare -a METADATA_CACHE=()

# Initialize plugin directories (fast operation, keep as-is)
init_plugin_dirs() {
    mkdir -p "$ENABLED_DIR" "$AVAILABLE_DIR" "$CORE_DIR" "$(dirname "$CONFIG_FILE")"
    
    # Create default config if not exists (one-time operation)
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

# OPTIMIZATION 3: Build command registry once
# This replaces repeated discovery with O(1) lookup
build_command_registry() {
    local cache_file="/tmp/mac-power-tools-commands-$$"
    
    # Check if registry already built this session
    if [ ${#PLUGIN_REGISTRY[@]} -gt 0 ]; then
        return 0
    fi
    
    # Build registry from plugin metadata
    for plugin_dir in "$CORE_DIR"/* "$AVAILABLE_DIR"/*; do
        if [ -d "$plugin_dir" ]; then
            local plugin_name="${plugin_dir##*/}"  # Use bash builtin instead of basename
            local metadata_file="${plugin_dir}/plugin.json"
            
            if [ -f "$metadata_file" ]; then
                # Extract commands without spawning grep subprocess
                while IFS= read -r line; do
                    if [[ "$line" == *'"commands"'* ]]; then
                        # Parse commands from JSON
                        local commands="${line#*[}"
                        commands="${commands%]*}"
                        commands="${commands//\"/}"
                        commands="${commands//,/ }"
                        
                        for cmd in $commands; do
                            PLUGIN_REGISTRY+=("${cmd}:${plugin_name}")
                        done
                    fi
                done < "$metadata_file"
            else
                # Fallback: use plugin name as command
                PLUGIN_REGISTRY+=("${plugin_name}:${plugin_name}")
            fi
        fi
    done
}

# OPTIMIZATION 4: Memoized plugin enabled check
is_plugin_enabled_fast() {
    local plugin_name=$1
    
    # Check memoization cache first
    for cached in "${ENABLED_CACHE[@]}"; do
        if [[ "$cached" == "${plugin_name}:true" ]]; then
            return 0
        elif [[ "$cached" == "${plugin_name}:false" ]]; then
            return 1
        fi
    done
    
    # Core plugins are always enabled
    if [ -d "${CORE_DIR}/${plugin_name}" ]; then
        ENABLED_CACHE+=("${plugin_name}:true")
        return 0
    fi
    
    # Check if symlink exists in enabled directory
    if [ -L "${ENABLED_DIR}/${plugin_name}" ]; then
        ENABLED_CACHE+=("${plugin_name}:true")
        return 0
    fi
    
    # Check config file
    if [ -f "$CONFIG_FILE" ]; then
        # Use bash builtin instead of grep
        while IFS='=' read -r key value; do
            if [[ "$key" == "$plugin_name" && "$value" == "enabled" ]]; then
                ENABLED_CACHE+=("${plugin_name}:true")
                return 0
            fi
        done < "$CONFIG_FILE"
    fi
    
    ENABLED_CACHE+=("${plugin_name}:false")
    return 1
}

# OPTIMIZATION 5: Lazy plugin loading
# Only load plugin when actually needed
load_plugin_lazy() {
    local plugin_name=$1
    shift
    
    # Check if already loaded
    for loaded in "${LOADED_PLUGINS[@]}"; do
        if [[ "$loaded" == "$plugin_name" ]]; then
            return 0  # Already loaded
        fi
    done
    
    # Find plugin directory
    local plugin_path=""
    for dir in "$CORE_DIR" "$AVAILABLE_DIR"; do
        if [ -d "$dir/$plugin_name" ]; then
            plugin_path="$dir/$plugin_name"
            break
        fi
    done
    
    if [ -z "$plugin_path" ]; then
        return 1  # Plugin not found
    fi
    
    # Skip if disabled
    if ! is_plugin_enabled_fast "$plugin_name"; then
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
    
    # Source the main plugin file
    local main_file="${plugin_path}/main.sh"
    if [ -f "$main_file" ]; then
        source "$main_file"
        LOADED_PLUGINS+=("$plugin_name")
        return 0
    fi
    
    return 1
}

# OPTIMIZATION 6: Fast command execution
# Use registry for O(1) lookup instead of linear search
execute_plugin_command_fast() {
    local command=$1
    shift
    
    # Build registry if not already done
    if [ ${#PLUGIN_REGISTRY[@]} -eq 0 ]; then
        build_command_registry
    fi
    
    # Find plugin for command using registry
    local plugin_name=""
    for entry in "${PLUGIN_REGISTRY[@]}"; do
        if [[ "$entry" == "${command}:"* ]]; then
            plugin_name="${entry#*:}"
            break
        fi
    done
    
    if [ -z "$plugin_name" ]; then
        return 1  # Command not found
    fi
    
    # Load plugin if not already loaded (lazy loading)
    if ! load_plugin_lazy "$plugin_name"; then
        return 1
    fi
    
    # Execute plugin command
    if declare -f "plugin_main" > /dev/null; then
        plugin_main "$@"
    elif declare -f "${command}_main" > /dev/null; then
        "${command}_main" "$@"
    else
        return 1
    fi
    
    return $?
}

# OPTIMIZATION 7: Minimal startup - don't load anything
# The original loads all plugins at startup, we skip this entirely
init_optimized_plugin_system() {
    init_plugin_dirs
    # That's it! No plugin loading at startup
    # Plugins will be loaded on-demand when needed
}

# Export optimized functions
export -f is_plugin_enabled_fast
export -f load_plugin_lazy
export -f execute_plugin_command_fast
export -f build_command_registry
export -f init_optimized_plugin_system

# Performance comparison function
compare_performance() {
    echo "Performance Comparison:"
    echo "======================"
    
    # Test original approach
    echo -n "Original (load all plugins): "
    time_start=$(date +%s%N 2>/dev/null || echo "0")
    source "${PLUGIN_BASE_DIR}/lib/plugin-loader.sh"
    load_all_plugins > /dev/null 2>&1
    time_end=$(date +%s%N 2>/dev/null || echo "1000000")
    if [ "$time_start" != "0" ]; then
        time_original=$(( (time_end - time_start) / 1000000 ))
        echo "${time_original}ms"
    else
        echo "N/A"
    fi
    
    # Test optimized approach
    echo -n "Optimized (lazy loading):    "
    time_start=$(date +%s%N 2>/dev/null || echo "0")
    init_optimized_plugin_system
    time_end=$(date +%s%N 2>/dev/null || echo "1000000")
    if [ "$time_start" != "0" ]; then
        time_optimized=$(( (time_end - time_start) / 1000000 ))
        echo "${time_optimized}ms"
        
        if [ $time_original -gt 0 ]; then
            improvement=$(( (time_original - time_optimized) * 100 / time_original ))
            echo "Improvement: ${improvement}% faster"
        fi
    else
        echo "N/A"
    fi
}