#!/bin/bash

# Plugin Test Adapter
# Provides compatibility layer for tests to work with plugin architecture

# Get directories
TEST_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$TEST_DIR")"

# Set up environment for plugins
export MAC_POWER_TOOLS_HOME="$PROJECT_DIR"
export PLUGINS_DIR="$PROJECT_DIR/plugins"
export AVAILABLE_DIR="$PLUGINS_DIR/available"
export ENABLED_DIR="$PLUGINS_DIR/enabled"

# Source plugin API
source "$PROJECT_DIR/lib/plugin-api.sh"

# Function to load a plugin for testing
load_plugin_for_test() {
    local plugin_name=$1
    local plugin_dir="$AVAILABLE_DIR/$plugin_name"
    
    if [ ! -d "$plugin_dir" ]; then
        echo "Error: Plugin $plugin_name not found" >&2
        return 1
    fi
    
    # Source the plugin's main.sh
    if [ -f "$plugin_dir/main.sh" ]; then
        # Export plugin metadata
        export PLUGIN_NAME="$plugin_name"
        export PLUGIN_DIR="$plugin_dir"
        
        # Source the plugin
        source "$plugin_dir/main.sh"
        
        # Create wrapper functions for common patterns
        # This allows old tests to work with new plugin architecture
        
        # For plugins that use plugin_main as entry point
        if declare -f plugin_main &>/dev/null; then
            # Create a wrapper that calls plugin_main
            eval "${plugin_name}_main() { plugin_main \"\$@\"; }"
        fi
        
        return 0
    else
        echo "Error: Plugin $plugin_name main.sh not found" >&2
        return 1
    fi
}

# Compatibility wrappers for common test patterns
# These map old function names to new plugin functions

# For clean plugin
if [ "$1" = "clean" ]; then
    load_plugin_for_test "clean"
    
    # Map old functions to new ones if they exist
    if declare -f clean_xcode_derived_data &>/dev/null; then
        :  # Function exists, no mapping needed
    elif declare -f plugin_main &>/dev/null; then
        # Create compatibility wrapper
        clean_xcode_derived_data() {
            plugin_main xcode
        }
        clean_npm_cache() {
            plugin_main npm
        }
        clean_system_caches() {
            plugin_main caches
        }
    fi
fi

# For uninstall plugin
if [ "$1" = "uninstall" ]; then
    load_plugin_for_test "uninstall"
    
    # The uninstall plugin exports functions directly
    # No additional mapping needed
fi

# For duplicates plugin
if [ "$1" = "duplicates" ]; then
    load_plugin_for_test "duplicates"
    
    # The duplicates plugin exports functions directly
    # No additional mapping needed
fi

# For memory plugin
if [ "$1" = "memory" ]; then
    load_plugin_for_test "memory"
    
    # Map old functions if needed
    if declare -f plugin_main &>/dev/null; then
        show_memory_usage() {
            plugin_main status
        }
        optimize_memory() {
            plugin_main optimize
        }
    fi
fi

# For battery plugin
if [ "$1" = "battery" ]; then
    load_plugin_for_test "battery"
    
    # The battery plugin exports functions directly
    # No additional mapping needed
fi

# For shortcuts plugin
if [ "$1" = "shortcuts" ]; then
    load_plugin_for_test "shortcuts"
    
    # Map old functions if needed
    if declare -f plugin_main &>/dev/null; then
        show_shortcuts_help() {
            plugin_main help
        }
        shortcuts_screenshot() {
            plugin_main screenshot "$@"
        }
        shortcuts_lock() {
            plugin_main lock
        }
        shortcuts_volume() {
            plugin_main volume "$@"
        }
    fi
fi

# For migrate-apps plugin
if [ "$1" = "migrate-apps" ]; then
    load_plugin_for_test "migrate-apps"
    
    # The migrate-apps plugin exports functions directly
    # No additional mapping needed
fi