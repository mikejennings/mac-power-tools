#!/bin/bash

# Plugin API - Shared functions for all plugins
# Provides common utilities and standardized interfaces

# Load security utilities if available
PLUGIN_API_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${PLUGIN_API_DIR}/security-utils.sh" ]; then
    source "${PLUGIN_API_DIR}/security-utils.sh"
    init_security_logging 2>/dev/null
fi

# Colors for output (available to all plugins)
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export CYAN='\033[0;36m'
export MAGENTA='\033[0;35m'
export NC='\033[0m' # No Color

# Get plugin directory
plugin_dir() {
    echo "${MAC_PLUGIN_DIR:-}"
}

# Get plugin name
plugin_name() {
    echo "${MAC_PLUGIN_NAME:-}"
}

# Get plugin version
plugin_version() {
    echo "${MAC_PLUGIN_VERSION:-}"
}

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Print colored output
print_info() {
    printf "${BLUE}ℹ${NC} %s\n" "$1"
}

print_success() {
    printf "${GREEN}✓${NC} %s\n" "$1"
}

print_warning() {
    printf "${YELLOW}⚠${NC} %s\n" "$1"
}

print_error() {
    printf "${RED}✗${NC} %s\n" "$1"
}

# Check for required dependencies
check_dependencies() {
    local deps=("$@")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command_exists "$dep"; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        print_error "Missing dependencies: ${missing[*]}"
        return 1
    fi
    
    return 0
}

# Get user confirmation
confirm() {
    local prompt="${1:-Continue?}"
    local response
    
    printf "%s [y/N]: " "$prompt"
    read -r response
    
    case "$response" in
        [yY][eE][sS]|[yY]) 
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Progress bar
show_progress() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local filled=$((percentage * width / 100))
    
    printf "\r["
    printf "%${filled}s" | tr ' ' '='
    printf "%$((width - filled))s" | tr ' ' '-'
    printf "] %3d%%" "$percentage"
    
    if [ "$current" -eq "$total" ]; then
        printf "\n"
    fi
}

# Load plugin configuration
load_plugin_config() {
    local config_file="${plugin_dir}/config.json"
    if [ -f "$config_file" ]; then
        # Simple JSON parsing for bash
        grep -E '^\s*"[^"]+"\s*:\s*' "$config_file" | while IFS=: read -r key value; do
            key=$(echo "$key" | tr -d ' "')
            value=$(echo "$value" | tr -d ' ",')
            export "PLUGIN_CONFIG_${key^^}=$value"
        done
    fi
}

# Save plugin configuration
save_plugin_config() {
    local key=$1
    local value=$2
    local config_file="${plugin_dir}/config.json"
    
    # This is a simplified version - in production, use jq
    if command_exists jq; then
        if [ -f "$config_file" ]; then
            jq ".${key} = \"${value}\"" "$config_file" > "${config_file}.tmp" && mv "${config_file}.tmp" "$config_file"
        else
            echo "{\"${key}\": \"${value}\"}" | jq '.' > "$config_file"
        fi
    fi
}

# Register plugin command
register_command() {
    local command=$1
    local description=$2
    
    # This will be used by the help system
    export "MAC_COMMAND_${command^^}_DESC=$description"
}

# Plugin initialization hook
plugin_init() {
    # Load plugin configuration
    load_plugin_config
    
    # Set up plugin environment
    export MAC_PLUGIN_INITIALIZED=1
}

# Plugin cleanup hook
plugin_cleanup() {
    # Clean up any temporary files or processes
    export MAC_PLUGIN_INITIALIZED=0
}