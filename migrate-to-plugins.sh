#!/bin/bash

# Migration script to convert existing Mac Power Tools to plugin architecture

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PLUGINS_DIR="${SCRIPT_DIR}/plugins/available"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

printf "${BLUE}Mac Power Tools - Plugin Migration${NC}\n"
printf "This will convert existing commands to the plugin architecture\n\n"

# Create plugins for each existing script
create_plugin() {
    local script_file=$1
    local plugin_name=$2
    local description=$3
    local category=$4
    
    printf "${YELLOW}Creating plugin: ${plugin_name}${NC}\n"
    
    plugin_dir="${PLUGINS_DIR}/${plugin_name}"
    mkdir -p "$plugin_dir"
    
    # Create plugin.json
    cat > "${plugin_dir}/plugin.json" <<EOF
{
  "name": "${plugin_name}",
  "version": "1.0.0",
  "description": "${description}",
  "author": "Mac Power Tools",
  "category": "${category}",
  "commands": ["${plugin_name}"],
  "legacy_script": "scripts/${script_file}",
  "migrated": true
}
EOF
    
    # Create main.sh wrapper
    cat > "${plugin_dir}/main.sh" <<'EOF'
#!/bin/bash

# Auto-generated plugin wrapper
# This plugin wraps the legacy script for backward compatibility

# Source the plugin API
source "${MAC_POWER_TOOLS_HOME}/lib/plugin-api.sh"

# Get the legacy script path from metadata
PLUGIN_DIR="$(dirname "${BASH_SOURCE[0]}")"
LEGACY_SCRIPT=$(grep -o '"legacy_script"[[:space:]]*:[[:space:]]*"[^"]*"' "${PLUGIN_DIR}/plugin.json" | cut -d'"' -f4)

# Plugin main entry point
plugin_main() {
    # Delegate to legacy script
    local script_path="${MAC_POWER_TOOLS_HOME}/${LEGACY_SCRIPT}"
    
    if [ -f "$script_path" ]; then
        "$script_path" "$@"
    else
        print_error "Legacy script not found: $LEGACY_SCRIPT"
        return 1
    fi
}

# Initialize the plugin
plugin_init

# Call the main function if not sourced
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    plugin_main "$@"
fi
EOF
    
    chmod +x "${plugin_dir}/main.sh"
    printf "  ✓ Created ${plugin_name} plugin\n"
}

# Create all plugins
create_plugin "mac-update.sh" "update" "System update utilities" "system"
create_plugin "mac-info.sh" "info" "System information tools" "system"
create_plugin "mac-maintenance.sh" "maintenance" "System maintenance utilities" "system"
create_plugin "mac-clean.sh" "clean" "Deep system cleaning" "maintenance"
create_plugin "mac-memory.sh" "memory" "Memory optimization" "performance"
create_plugin "mac-battery.sh" "battery" "Battery management" "performance"
create_plugin "mac-uninstall.sh" "uninstall" "Application uninstaller" "apps"
create_plugin "mac-duplicates.sh" "duplicates" "Duplicate file finder" "storage"
create_plugin "mac-privacy.sh" "privacy" "Privacy and security tools" "security"
create_plugin "mac-downloads.sh" "downloads" "Downloads management" "organization"
create_plugin "mac-dotfiles.sh" "dotfiles" "Dotfiles backup and sync" "backup"
create_plugin "mac-linuxify.sh" "linuxify" "GNU/Linux environment" "system"
create_plugin "mac-awake.sh" "awake" "Power management" "power"
create_plugin "mac-shortcuts.sh" "shortcuts" "System shortcuts" "productivity"
create_plugin "mac-migrate-mas.sh" "migrate-mas" "App Store migration" "apps"
create_plugin "mac-migrate-apps.sh" "migrate-apps" "App migration tools" "apps"

# Create core plugins (help and version)
printf "\n${YELLOW}Creating core plugins${NC}\n"

# Help plugin
mkdir -p "${SCRIPT_DIR}/plugins/core/help"
cat > "${SCRIPT_DIR}/plugins/core/help/plugin.json" <<EOF
{
  "name": "help",
  "version": "1.0.0",
  "description": "Show help information",
  "author": "Mac Power Tools",
  "category": "core",
  "commands": ["help"],
  "core": true
}
EOF

cat > "${SCRIPT_DIR}/plugins/core/help/main.sh" <<'EOF'
#!/bin/bash

# Help plugin
plugin_main() {
    # This is handled by the main script
    return 0
}
EOF

# Version plugin
mkdir -p "${SCRIPT_DIR}/plugins/core/version"
cat > "${SCRIPT_DIR}/plugins/core/version/plugin.json" <<EOF
{
  "name": "version",
  "version": "1.0.0",
  "description": "Show version information",
  "author": "Mac Power Tools",
  "category": "core",
  "commands": ["version"],
  "core": true
}
EOF

cat > "${SCRIPT_DIR}/plugins/core/version/main.sh" <<'EOF'
#!/bin/bash

# Version plugin
plugin_main() {
    # This is handled by the main script
    return 0
}
EOF

printf "  ✓ Created core plugins\n"

# Make the new plugin-based script executable
chmod +x "${SCRIPT_DIR}/mac-plugin"

printf "\n${GREEN}Migration complete!${NC}\n"
printf "\nTo use the new plugin system:\n"
printf "  1. Test with: ./mac-plugin help\n"
printf "  2. List plugins: ./mac-plugin plugin list\n"
printf "  3. When ready, replace the main script: mv mac mac-legacy && mv mac-plugin mac\n"
printf "\nThe plugin system is backward compatible with all existing commands.\n"