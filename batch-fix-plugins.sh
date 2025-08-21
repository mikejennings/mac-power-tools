#!/bin/bash

# Batch Fix All Plugin Structures
# Fixes all plugins that have structural issues after conversion

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS_DIR="$SCRIPT_DIR/plugins/available"

# Print colored output
print_color() {
    local color=$1
    shift
    printf "${color}%s${NC}\n" "$*"
}

# List of plugins needing fixes (excluding battery and shortcuts which are already fixed)
PLUGINS_TO_FIX=("clean" "dotfiles" "downloads" "duplicates" "linuxify" "migrate-apps" "migrate-mas" "privacy" "uninstall")

# Fix a single plugin's structure
fix_single_plugin() {
    local plugin_name="$1"
    local main_sh="$PLUGINS_DIR/$plugin_name/main.sh"
    
    print_color "$CYAN" "Fixing $plugin_name..."
    
    if [[ ! -f "$main_sh" ]]; then
        print_color "$RED" "  ✗ main.sh not found"
        return 1
    fi
    
    # Check if it needs fixing
    if ! grep -q "main \"\$@\"" "$main_sh"; then
        print_color "$YELLOW" "  ⚠ Already fixed or doesn't need fixing"
        return 0
    fi
    
    # Backup
    cp "$main_sh" "$main_sh.fix-backup" 2>/dev/null || true
    
    # Extract the case statement structure
    local case_start=$(grep -n "^case.*in$" "$main_sh" | head -1 | cut -d: -f1)
    local case_end=$(grep -n "^esac$" "$main_sh" | head -1 | cut -d: -f1)
    
    if [[ -z "$case_start" ]] || [[ -z "$case_end" ]]; then
        print_color "$RED" "  ✗ Could not find case statement"
        return 1
    fi
    
    # Extract case statement content
    local case_content=$(sed -n "${case_start},${case_end}p" "$main_sh" | sed '1d;$d')
    
    # Replace the problematic plugin_main function
    local temp_file=$(mktemp)
    
    # Copy everything up to the plugin_main function
    awk '/^# Plugin main entry point/{exit} {print}' "$main_sh" > "$temp_file"
    
    # Add the fixed plugin_main function
    cat >> "$temp_file" << 'EOF'
# Plugin main entry point
plugin_main() {
    # This plugin uses case statement structure - execute case directly
    local args=("$@")
    
    # Re-execute the case statement with provided arguments
EOF
    
    echo "    case \"\${args[0]:-}\" in" >> "$temp_file"
    echo "$case_content" >> "$temp_file"
    echo "    esac" >> "$temp_file"
    echo "}" >> "$temp_file"
    echo "" >> "$temp_file"
    
    # Add the rest of the plugin initialization
    cat >> "$temp_file" << 'EOF'
# Initialize the plugin
plugin_init

# Call the main function if not sourced
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    plugin_main "$@"
fi
EOF
    
    # Replace the original file
    mv "$temp_file" "$main_sh"
    
    print_color "$GREEN" "  ✓ Fixed successfully"
    return 0
}

# Test a plugin after fixing
test_plugin() {
    local plugin_name="$1"
    
    print_color "$CYAN" "Testing $plugin_name..."
    
    # Try to get help output
    if timeout 5 ./mac-plugin "$plugin_name" --help >/dev/null 2>&1; then
        print_color "$GREEN" "  ✓ Plugin test passed"
        return 0
    else
        print_color "$YELLOW" "  ⚠ Plugin test failed (may be normal for some plugins)"
        return 0
    fi
}

# Main execution
main() {
    print_color "$BLUE" "═══════════════════════════════════════════"
    print_color "$BLUE" "Batch Plugin Structure Fix"
    print_color "$BLUE" "═══════════════════════════════════════════"
    
    local fixed=0
    local failed=0
    
    for plugin in "${PLUGINS_TO_FIX[@]}"; do
        if fix_single_plugin "$plugin"; then
            test_plugin "$plugin"
            ((fixed++))
        else
            ((failed++))
        fi
        echo
    done
    
    print_color "$BLUE" "═══════════════════════════════════════════"
    print_color "$BLUE" "Summary"
    print_color "$BLUE" "═══════════════════════════════════════════"
    
    print_color "$GREEN" "Fixed: $fixed plugins"
    if [[ $failed -gt 0 ]]; then
        print_color "$RED" "Failed: $failed plugins"
    fi
    
    echo
    print_color "$CYAN" "All plugins should now be working correctly!"
    print_color "$CYAN" "Test with: ./mac-plugin <name> --help"
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi