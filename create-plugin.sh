#!/bin/bash

# Plugin Development Kit - Create new plugins for Mac Power Tools

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PLUGINS_DIR="${SCRIPT_DIR}/plugins/available"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Show help
show_help() {
    printf "${BLUE}Mac Power Tools - Plugin Creator${NC}\n\n"
    printf "${YELLOW}Usage:${NC} ./create-plugin.sh [plugin-name]\n\n"
    printf "This will create a new plugin with:\n"
    printf "  • Plugin metadata (plugin.json)\n"
    printf "  • Main script (main.sh)\n"
    printf "  • Test directory\n"
    printf "  • README.md\n\n"
    printf "${YELLOW}Example:${NC}\n"
    printf "  ./create-plugin.sh network-monitor\n"
}

# Get plugin details interactively
get_plugin_details() {
    local plugin_name=$1
    
    printf "${BLUE}Creating plugin: ${plugin_name}${NC}\n\n"
    
    # Get description
    printf "Enter a short description: "
    read -r description
    
    # Get category
    printf "Enter category (system/performance/security/apps/network/storage/other): "
    read -r category
    
    # Get author
    printf "Enter author name [Mac Power Tools]: "
    read -r author
    author=${author:-Mac Power Tools}
    
    # Get commands
    printf "Enter main command name [${plugin_name}]: "
    read -r command
    command=${command:-$plugin_name}
    
    echo "$description|$category|$author|$command"
}

# Create plugin structure
create_plugin() {
    local plugin_name=$1
    
    # Validate plugin name
    if [[ ! "$plugin_name" =~ ^[a-z0-9-]+$ ]]; then
        printf "${RED}Error: Plugin name must contain only lowercase letters, numbers, and hyphens${NC}\n"
        exit 1
    fi
    
    # Check if plugin already exists
    if [ -d "${PLUGINS_DIR}/${plugin_name}" ]; then
        printf "${RED}Error: Plugin '${plugin_name}' already exists${NC}\n"
        exit 1
    fi
    
    # Get plugin details
    IFS='|' read -r description category author command <<< "$(get_plugin_details "$plugin_name")"
    
    # Create plugin directory
    local plugin_dir="${PLUGINS_DIR}/${plugin_name}"
    mkdir -p "${plugin_dir}/tests"
    
    # Create plugin.json
    cat > "${plugin_dir}/plugin.json" <<EOF
{
  "name": "${plugin_name}",
  "version": "1.0.0",
  "description": "${description}",
  "author": "${author}",
  "category": "${category}",
  "commands": ["${command}"],
  "dependencies": [],
  "homepage": "https://github.com/mac-power-tools/plugins",
  "license": "MIT"
}
EOF
    
    # Create main.sh
    cat > "${plugin_dir}/main.sh" <<'MAINSH'
#!/bin/bash

# Plugin: PLUGIN_NAME
# Description: PLUGIN_DESC

# Source the plugin API
source "${MAC_POWER_TOOLS_HOME}/lib/plugin-api.sh"

# Plugin configuration
PLUGIN_NAME="PLUGIN_NAME_VAR"
PLUGIN_VERSION="1.0.0"

# Main entry point
plugin_main() {
    local subcommand=${1:-help}
    shift
    
    case "$subcommand" in
        status)
            show_status "$@"
            ;;
        run)
            run_command "$@"
            ;;
        help)
            show_help
            ;;
        *)
            print_error "Unknown command: $subcommand"
            show_help
            return 1
            ;;
    esac
}

# Show status
show_status() {
    print_info "${PLUGIN_NAME} Status"
    
    # TODO(human): Implement status check for your plugin
    # This should show the current state or configuration
    
    printf "Plugin is installed and ready\n"
}

# Run main command
run_command() {
    print_info "Running ${PLUGIN_NAME}"
    
    # TODO(human): Implement main functionality
    # This is where your plugin's core logic goes
    
    print_success "Command completed successfully"
}

# Show help
show_help() {
    printf "${BLUE}${PLUGIN_NAME} Plugin${NC}\n"
    printf "Version: ${PLUGIN_VERSION}\n\n"
    printf "${YELLOW}Usage:${NC} mac COMMAND_NAME [subcommand] [options]\n\n"
    printf "${YELLOW}Subcommands:${NC}\n"
    printf "  status    Show current status\n"
    printf "  run       Execute main functionality\n"
    printf "  help      Show this help message\n\n"
    printf "${YELLOW}Examples:${NC}\n"
    printf "  mac COMMAND_NAME status\n"
    printf "  mac COMMAND_NAME run\n"
}

# Initialize plugin
plugin_init

# Register commands
register_command "COMMAND_NAME" "PLUGIN_DESC"

# Execute if called directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    plugin_main "$@"
fi
MAINSH
    
    # Replace placeholders
    sed -i.bak "s/PLUGIN_NAME/${plugin_name}/g" "${plugin_dir}/main.sh"
    sed -i.bak "s/PLUGIN_DESC/${description}/g" "${plugin_dir}/main.sh"
    sed -i.bak "s/PLUGIN_NAME_VAR/${plugin_name}/g" "${plugin_dir}/main.sh"
    sed -i.bak "s/COMMAND_NAME/${command}/g" "${plugin_dir}/main.sh"
    rm "${plugin_dir}/main.sh.bak"
    
    chmod +x "${plugin_dir}/main.sh"
    
    # Create README.md
    cat > "${plugin_dir}/README.md" <<EOF
# ${plugin_name} Plugin

${description}

## Installation

\`\`\`bash
# Enable the plugin
mac plugin enable ${plugin_name}
\`\`\`

## Usage

\`\`\`bash
# Show help
mac ${command} help

# Check status
mac ${command} status

# Run main command
mac ${command} run
\`\`\`

## Features

- Feature 1
- Feature 2
- Feature 3

## Configuration

Plugin configuration is stored in \`~/.mac-power-tools/plugins/${plugin_name}/config.json\`

## Development

To contribute to this plugin:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests in the \`tests/\` directory
5. Submit a pull request

## License

MIT
EOF
    
    # Create test file
    cat > "${plugin_dir}/tests/test_${plugin_name}.sh" <<'EOF'
#!/bin/bash

# Test suite for PLUGIN_NAME plugin

# Source test helper
source "$(dirname "$0")/../../../test/test_helper.sh"

# Test plugin loads
test_plugin_loads() {
    local result=$(mac COMMAND_NAME help 2>&1)
    assert_contains "$result" "PLUGIN_NAME Plugin" "Plugin should load and show help"
}

# Test status command
test_status_command() {
    local result=$(mac COMMAND_NAME status 2>&1)
    assert_contains "$result" "Status" "Status command should work"
}

# Run tests
run_tests() {
    test_plugin_loads
    test_status_command
    
    print_test_summary
}

# Execute tests
run_tests
EOF
    
    # Replace placeholders in test
    sed -i.bak "s/PLUGIN_NAME/${plugin_name}/g" "${plugin_dir}/tests/test_${plugin_name}.sh"
    sed -i.bak "s/COMMAND_NAME/${command}/g" "${plugin_dir}/tests/test_${plugin_name}.sh"
    rm "${plugin_dir}/tests/test_${plugin_name}.sh.bak"
    
    chmod +x "${plugin_dir}/tests/test_${plugin_name}.sh"
    
    printf "\n${GREEN}✓ Plugin '${plugin_name}' created successfully!${NC}\n\n"
    printf "Plugin location: ${plugin_dir}\n\n"
    printf "Next steps:\n"
    printf "  1. Edit ${plugin_dir}/main.sh to implement functionality\n"
    printf "  2. Update ${plugin_dir}/plugin.json with dependencies\n"
    printf "  3. Add tests in ${plugin_dir}/tests/\n"
    printf "  4. Enable the plugin: ./mac-plugin plugin enable ${plugin_name}\n"
    printf "  5. Test the plugin: ./mac-plugin ${command} help\n"
}

# Main
if [ $# -eq 0 ]; then
    show_help
    exit 0
fi

if [ "$1" = "help" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

create_plugin "$1"