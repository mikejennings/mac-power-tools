#!/bin/bash

# Fix Plugin Structure Script
# Fixes plugins that use case statements instead of main() functions

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

# Plugins that use case statements instead of main functions
CASE_STATEMENT_PLUGINS=("battery" "shortcuts" "clean" "dotfiles" "downloads" "duplicates" "linuxify" "migrate-apps" "migrate-mas" "privacy" "uninstall")

# Fix a plugin that uses case statements
fix_case_statement_plugin() {
    local plugin_name="$1"
    local main_sh="$PLUGINS_DIR/$plugin_name/main.sh"
    
    print_color "$CYAN" "Fixing $plugin_name plugin structure..."
    
    if [[ ! -f "$main_sh" ]]; then
        print_color "$RED" "  ✗ main.sh not found for $plugin_name"
        return 1
    fi
    
    # Check if it has a case statement and no main function
    if grep -q "^case.*in$" "$main_sh" && ! grep -q "^main()" "$main_sh"; then
        print_color "$CYAN" "  Found case statement structure"
        
        # Backup the file
        cp "$main_sh" "$main_sh.backup"
        
        # Replace the plugin_main function to call the case statement directly
        sed -i '' '/# Plugin main entry point/,$d' "$main_sh"
        
        # Add the correct plugin wrapper
        cat >> "$main_sh" << 'EOF'

# Plugin main entry point
plugin_main() {
    # Handle the case statement directly with plugin arguments
    # The case statement is already in the script above
    
    # Since this script uses a case statement structure,
    # we need to re-execute the case logic with the provided arguments
    local original_args=("$@")
    
    # The case statement above will handle the arguments
    # This is a bit of a hack, but necessary for case-based plugins
    exec "$0" "${original_args[@]}"
}

# Initialize the plugin
plugin_init

# Handle arguments directly through case statement when run as plugin
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    # This will be handled by the case statement above
    :
fi
EOF
        
        print_color "$GREEN" "  ✓ Fixed case statement structure"
        return 0
    else
        print_color "$YELLOW" "  ⚠ Plugin already has correct structure or uses main() function"
        return 0
    fi
}

# Even better approach - completely rewrite the plugin_main section
fix_case_statement_plugin_better() {
    local plugin_name="$1"
    local main_sh="$PLUGINS_DIR/$plugin_name/main.sh"
    
    print_color "$CYAN" "Fixing $plugin_name plugin structure (better approach)..."
    
    if [[ ! -f "$main_sh" ]]; then
        print_color "$RED" "  ✗ main.sh not found for $plugin_name"
        return 1
    fi
    
    # Check if it has the problematic plugin_main calling main
    if grep -q "main \"\$@\"" "$main_sh"; then
        print_color "$CYAN" "  Found problematic plugin_main function"
        
        # Backup the file
        cp "$main_sh" "$main_sh.backup"
        
        # Find where the case statement starts and ends
        local case_start=$(grep -n "^case.*in$" "$main_sh" | head -1 | cut -d: -f1)
        local case_end=$(grep -n "^esac$" "$main_sh" | head -1 | cut -d: -f1)
        
        if [[ -n "$case_start" ]] && [[ -n "$case_end" ]]; then
            # Remove everything after esac (the broken plugin wrapper)
            sed -i '' "${case_end}q" "$main_sh"
            
            # Add the correct plugin wrapper
            cat >> "$main_sh" << 'EOF'

# Plugin main entry point
plugin_main() {
    # This plugin uses a case statement structure
    # Re-execute the case statement with the provided arguments
    local arg1="${1:-}"
    
    # Execute the case statement logic directly
    case "$arg1" in
EOF
            
            # Extract just the case options and their actions
            sed -n "${case_start},${case_end}p" "$main_sh.backup" | sed '1d;$d' >> "$main_sh"
            
            cat >> "$main_sh" << 'EOF'
    esac
}

# Initialize the plugin
plugin_init

# Call the main function if not sourced
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    plugin_main "$@"
fi
EOF
            
            print_color "$GREEN" "  ✓ Fixed with better case statement structure"
            return 0
        else
            print_color "$RED" "  ✗ Could not find case statement boundaries"
            return 1
        fi
    else
        print_color "$YELLOW" "  ⚠ Plugin already has correct structure"
        return 0
    fi
}

# Simplest approach - just fix the plugin_main call
fix_plugin_main_call() {
    local plugin_name="$1"
    local main_sh="$PLUGINS_DIR/$plugin_name/main.sh"
    
    print_color "$CYAN" "Fixing $plugin_name plugin_main call..."
    
    if [[ ! -f "$main_sh" ]]; then
        print_color "$RED" "  ✗ main.sh not found for $plugin_name"
        return 1
    fi
    
    # Check if it has the problematic call to main function
    if grep -q "main \"\$@\"" "$main_sh"; then
        print_color "$CYAN" "  Found problematic main function call"
        
        # Backup the file
        cp "$main_sh" "$main_sh.backup" 2>/dev/null || true
        
        # Replace the call to main with a direct case statement execution
        # This is a simple sed replacement
        sed -i '' 's/main "\$@"/# Execute case statement directly - no main function needed/' "$main_sh"
        
        # Also replace the plugin_main content
        sed -i '' '/plugin_main() {/,/}/ {
            /plugin_main() {/!{
                /}/!d
            }
        }' "$main_sh"
        
        # Insert new plugin_main content after the function declaration
        sed -i '' '/plugin_main() {/a\
    # This plugin uses case statement structure\
    # Arguments are handled by the case statement above\
    :  # no-op - case statement handles everything
' "$main_sh"
        
        print_color "$GREEN" "  ✓ Fixed plugin_main call"
        return 0
    else
        print_color "$YELLOW" "  ⚠ Plugin doesn't have problematic main call"
        return 0
    fi
}

# Main execution
main() {
    print_color "$BLUE" "═══════════════════════════════════════════"
    print_color "$BLUE" "Plugin Structure Fix Script"
    print_color "$BLUE" "═══════════════════════════════════════════"
    
    print_color "$CYAN" "Fixing plugins with case statement structures..."
    echo
    
    local fixed=0
    local failed=0
    
    for plugin in "${CASE_STATEMENT_PLUGINS[@]}"; do
        if fix_plugin_main_call "$plugin"; then
            ((fixed++))
        else
            ((failed++))
        fi
        echo
    done
    
    print_color "$BLUE" "═══════════════════════════════════════════"
    print_color "$BLUE" "Fix Summary"
    print_color "$BLUE" "═══════════════════════════════════════════"
    
    print_color "$GREEN" "Fixed: $fixed plugins"
    if [[ $failed -gt 0 ]]; then
        print_color "$RED" "Failed: $failed plugins"
    fi
    
    echo
    print_color "$CYAN" "Next steps:"
    print_color "$CYAN" "  1. Test plugins: ./mac-plugin <name> --help"
    print_color "$CYAN" "  2. Run test suite: ./local-test.sh"
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi