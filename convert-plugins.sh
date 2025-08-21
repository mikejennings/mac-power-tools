#!/bin/bash

# Batch Plugin Conversion Script
# Converts all remaining wrapper plugins to native implementations
# This will preserve all functionality while using the plugin API

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS_DIR="$SCRIPT_DIR/plugins/available"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"

# Counters
CONVERTED=0
FAILED=0
SKIPPED=0

# Print colored output
print_color() {
    local color=$1
    shift
    printf "${color}%s${NC}\n" "$*"
}

# Print section header
print_section() {
    echo
    print_color "$BLUE" "═══════════════════════════════════════════"
    print_color "$BLUE" "$1"
    print_color "$BLUE" "═══════════════════════════════════════════"
}

# Check if a plugin has legacy_script field
has_legacy_script() {
    local plugin_json="$1"
    grep -q '"legacy_script"' "$plugin_json"
}

# Get legacy script path from plugin.json
get_legacy_script() {
    local plugin_json="$1"
    grep -o '"legacy_script"[[:space:]]*:[[:space:]]*"[^"]*"' "$plugin_json" | cut -d'"' -f4
}

# Extract script content preserving all functions
extract_script_content() {
    local script_file="$1"
    
    # Read the script and extract everything except shebang and final execution
    awk '
    BEGIN { 
        skip_initial_comments = 1
        in_final_block = 0
    }
    
    # Skip shebang
    /^#!/ { next }
    
    # Skip initial comment block (first 20 lines)
    /^#/ && NR <= 20 && skip_initial_comments { next }
    
    # Once we hit non-comment, stop skipping
    !/^#/ && !/^$/ { skip_initial_comments = 0 }
    
    # Skip color definitions - will be replaced by plugin API
    /^(RED|GREEN|YELLOW|BLUE|CYAN|MAGENTA|NC)=/ { next }
    
    # Skip final execution blocks
    /^if.*BASH_SOURCE.*0.*then/ { in_final_block = 1 }
    /^main.*\$@/ && in_final_block { next }
    in_final_block { next }
    
    # Print everything else
    !in_final_block { print }
    ' "$script_file"
}

# Convert color variables to plugin API calls
convert_colors_to_api() {
    local content="$1"
    
    # Replace color variable usage with plugin API calls
    echo "$content" | sed \
        -e 's/print_color "\$GREEN"/print_success/g' \
        -e 's/print_color "\$RED"/print_error/g' \
        -e 's/print_color "\$YELLOW"/print_warning/g' \
        -e 's/print_color "\$BLUE"/print_info/g' \
        -e 's/print_color "\$CYAN"/print_info/g' \
        -e 's/print_color "\$MAGENTA"/print_info/g' \
        -e 's/printf "${GREEN}✓${NC}"/print_success/g' \
        -e 's/printf "${RED}✗${NC}"/print_error/g' \
        -e 's/printf "${YELLOW}⚠${NC}"/print_warning/g' \
        -e 's/printf "${BLUE}ℹ${NC}"/print_info/g' \
        -e 's/echo -e "${GREEN}/print_success "/g' \
        -e 's/echo -e "${RED}/print_error "/g' \
        -e 's/echo -e "${YELLOW}/print_warning "/g' \
        -e 's/echo -e "${BLUE}/print_info "/g' \
        -e 's/echo -e "${CYAN}/print_info "/g' \
        -e 's/${NC}"$/"/g'
}

# Create native plugin implementation
create_native_plugin() {
    local plugin_name="$1"
    local plugin_dir="$PLUGINS_DIR/$plugin_name"
    local legacy_script_path="$2"
    local plugin_json="$plugin_dir/plugin.json"
    local main_sh="$plugin_dir/main.sh"
    
    print_color "$CYAN" "  Converting $plugin_name..."
    
    # Backup existing main.sh
    if [[ -f "$main_sh" ]]; then
        cp "$main_sh" "$main_sh.backup"
    fi
    
    # Extract functionality from legacy script
    local legacy_content
    local full_script_path="$SCRIPT_DIR/$legacy_script_path"
    if [[ -f "$full_script_path" ]]; then
        legacy_content=$(extract_script_content "$full_script_path")
    else
        print_color "$RED" "    ✗ Legacy script not found: $full_script_path"
        return 1
    fi
    
    # Convert colors to plugin API calls
    legacy_content=$(convert_colors_to_api "$legacy_content")
    
    # Create the new native main.sh
    cat > "$main_sh" << 'EOF'
#!/bin/bash

# Native plugin implementation
# Migrated from legacy script to use plugin API

# Source the plugin API
source "${MAC_POWER_TOOLS_HOME}/lib/plugin-api.sh"

EOF
    
    # Add the extracted content
    echo "$legacy_content" >> "$main_sh"
    
    # Add the plugin wrapper
    cat >> "$main_sh" << 'EOF'

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
EOF
    
    # Make executable
    chmod +x "$main_sh"
    
    # Remove legacy_script field from plugin.json
    if command -v jq >/dev/null 2>&1; then
        # Use jq if available
        jq 'del(.legacy_script)' "$plugin_json" > "$plugin_json.tmp" && mv "$plugin_json.tmp" "$plugin_json"
    else
        # Fallback to sed
        sed '/legacy_script/d' "$plugin_json" > "$plugin_json.tmp" && mv "$plugin_json.tmp" "$plugin_json"
    fi
    
    print_color "$GREEN" "    ✓ Converted successfully"
    return 0
}

# Validate converted plugin
validate_plugin() {
    local plugin_name="$1"
    local plugin_dir="$PLUGINS_DIR/$plugin_name"
    local main_sh="$plugin_dir/main.sh"
    local plugin_json="$plugin_dir/plugin.json"
    
    print_color "$CYAN" "  Validating $plugin_name..."
    
    # Check syntax
    if ! bash -n "$main_sh" >/dev/null 2>&1; then
        print_color "$RED" "    ✗ Syntax error in main.sh"
        return 1
    fi
    
    # Check that legacy_script is removed
    if has_legacy_script "$plugin_json"; then
        print_color "$RED" "    ✗ legacy_script field still present"
        return 1
    fi
    
    # Check that main.sh sources plugin API
    if ! grep -q "source.*plugin-api.sh" "$main_sh"; then
        print_color "$RED" "    ✗ Plugin API not sourced"
        return 1
    fi
    
    # Check that plugin_main function exists
    if ! grep -q "plugin_main()" "$main_sh"; then
        print_color "$RED" "    ✗ plugin_main function missing"
        return 1
    fi
    
    print_color "$GREEN" "    ✓ Validation passed"
    return 0
}

# Test converted plugin
test_plugin() {
    local plugin_name="$1"
    
    print_color "$CYAN" "  Testing $plugin_name..."
    
    # Test help option if available
    if ./mac-plugin "$plugin_name" --help >/dev/null 2>&1; then
        print_color "$GREEN" "    ✓ Help command works"
    else
        print_color "$YELLOW" "    ⚠ Help command test failed (may be normal)"
    fi
    
    return 0
}

# Main conversion process
convert_all_plugins() {
    print_section "Starting Batch Plugin Conversion"
    
    print_color "$CYAN" "Scanning for wrapper plugins..."
    
    # Find all plugins with legacy_script
    local wrapper_plugins=()
    for plugin_json in "$PLUGINS_DIR"/*/plugin.json; do
        if [[ -f "$plugin_json" ]] && has_legacy_script "$plugin_json"; then
            local plugin_name=$(basename "$(dirname "$plugin_json")")
            wrapper_plugins+=("$plugin_name")
        fi
    done
    
    print_color "$GREEN" "Found ${#wrapper_plugins[@]} wrapper plugins to convert:"
    for plugin in "${wrapper_plugins[@]}"; do
        print_color "$CYAN" "  - $plugin"
    done
    
    echo
    
    # Convert each plugin
    for plugin_name in "${wrapper_plugins[@]}"; do
        print_section "Converting Plugin: $plugin_name"
        
        local plugin_json="$PLUGINS_DIR/$plugin_name/plugin.json"
        local legacy_script=$(get_legacy_script "$plugin_json")
        
        print_color "$CYAN" "Legacy script: $legacy_script"
        
        # Attempt conversion
        if create_native_plugin "$plugin_name" "$legacy_script"; then
            if validate_plugin "$plugin_name"; then
                test_plugin "$plugin_name"
                ((CONVERTED++))
                print_color "$GREEN" "✓ $plugin_name converted successfully"
            else
                print_color "$RED" "✗ $plugin_name validation failed"
                ((FAILED++))
            fi
        else
            print_color "$RED" "✗ $plugin_name conversion failed"
            ((FAILED++))
        fi
        
        echo
    done
}

# Show summary
show_summary() {
    print_section "Conversion Summary"
    
    print_color "$GREEN" "Successfully converted: $CONVERTED plugins"
    if [[ $FAILED -gt 0 ]]; then
        print_color "$RED" "Failed conversions: $FAILED plugins"
    fi
    if [[ $SKIPPED -gt 0 ]]; then
        print_color "$YELLOW" "Skipped: $SKIPPED plugins"
    fi
    
    local total=$((CONVERTED + FAILED + SKIPPED))
    print_color "$BLUE" "Total processed: $total plugins"
    
    if [[ $FAILED -eq 0 ]]; then
        echo
        print_color "$GREEN" "🎉 All plugins converted successfully!"
        print_color "$CYAN" "Next steps:"
        print_color "$CYAN" "  1. Run tests: ./local-test.sh"
        print_color "$CYAN" "  2. Test individual plugins: ./mac-plugin <name> --help"
        print_color "$CYAN" "  3. Enable converted plugins: mac plugin enable <name>"
    else
        echo
        print_color "$YELLOW" "⚠ Some conversions failed. Check the output above for details."
        print_color "$CYAN" "Failed plugins may need manual conversion."
    fi
}

# Cleanup function
cleanup() {
    print_color "$YELLOW" "Cleaning up temporary files..."
    find "$PLUGINS_DIR" -name "*.tmp" -delete 2>/dev/null || true
}

# Error handler
handle_error() {
    print_color "$RED" "Error occurred during conversion!"
    cleanup
    exit 1
}

# Main execution
main() {
    trap handle_error ERR
    trap cleanup EXIT
    
    print_section "Mac Power Tools - Batch Plugin Converter"
    print_color "$CYAN" "This script will convert all wrapper plugins to native implementations"
    print_color "$CYAN" "All functionality will be preserved while using the plugin API"
    
    echo
    printf "Continue with batch conversion? [y/N]: "
    read -r response
    
    case "$response" in
        [yY][eE][sS]|[yY]) 
            echo
            ;;
        *)
            print_color "$YELLOW" "Conversion cancelled"
            exit 0
            ;;
    esac
    
    # Check prerequisites
    print_color "$CYAN" "Checking prerequisites..."
    
    if [[ ! -d "$PLUGINS_DIR" ]]; then
        print_color "$RED" "Plugins directory not found: $PLUGINS_DIR"
        exit 1
    fi
    
    if [[ ! -d "$SCRIPTS_DIR" ]]; then
        print_color "$RED" "Scripts directory not found: $SCRIPTS_DIR"
        exit 1
    fi
    
    if [[ ! -f "$SCRIPT_DIR/lib/plugin-api.sh" ]]; then
        print_color "$RED" "Plugin API not found: $SCRIPT_DIR/lib/plugin-api.sh"
        exit 1
    fi
    
    print_color "$GREEN" "✓ Prerequisites check passed"
    
    # Start conversion
    convert_all_plugins
    
    # Show summary
    show_summary
}

# Execute main function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi