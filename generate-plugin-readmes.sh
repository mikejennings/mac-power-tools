#!/bin/bash

# Generate README.md files for all existing plugins

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PLUGINS_DIR="${SCRIPT_DIR}/plugins/available"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

printf "${BLUE}Generating README files for existing plugins...${NC}\n\n"

# Function to generate README based on plugin metadata
generate_readme() {
    local plugin_dir=$1
    local plugin_name=$(basename "$plugin_dir")
    local readme_file="${plugin_dir}/README.md"
    
    # Skip if README already exists
    if [ -f "$readme_file" ]; then
        printf "  Skipping ${plugin_name} (README exists)\n"
        return
    fi
    
    # Get metadata
    local metadata_file="${plugin_dir}/plugin.json"
    if [ ! -f "$metadata_file" ]; then
        printf "  Skipping ${plugin_name} (no metadata)\n"
        return
    fi
    
    # Extract metadata fields
    local description=$(grep -o '"description"[[:space:]]*:[[:space:]]*"[^"]*"' "$metadata_file" | cut -d'"' -f4)
    local version=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$metadata_file" | cut -d'"' -f4)
    local category=$(grep -o '"category"[[:space:]]*:[[:space:]]*"[^"]*"' "$metadata_file" | cut -d'"' -f4)
    local author=$(grep -o '"author"[[:space:]]*:[[:space:]]*"[^"]*"' "$metadata_file" | cut -d'"' -f4)
    
    # Get the original script name if it's a migrated plugin
    local legacy_script=$(grep -o '"legacy_script"[[:space:]]*:[[:space:]]*"[^"]*"' "$metadata_file" | cut -d'"' -f4)
    
    printf "  Generating README for ${plugin_name}...\n"
    
    # Generate README content based on plugin type
    case "$plugin_name" in
        battery)
            cat > "$readme_file" << 'EOF'
# Battery Management Plugin

Advanced battery management and monitoring for macOS.

## Features

- **Battery Health**: Check battery health percentage and condition
- **Cycle Count**: Monitor battery cycle count and lifespan
- **Power Status**: Real-time battery status and charging information
- **Usage History**: Track battery usage patterns over time
- **Optimization Tips**: Get personalized battery optimization recommendations
- **App Analysis**: Identify apps that drain battery the most
- **Calibration**: Battery calibration wizard for accurate readings

## Installation

This plugin is included with Mac Power Tools by default.

## Usage

```bash
# Check battery status
mac battery status

# View battery health
mac battery health

# Show cycle count
mac battery cycles

# Get optimization tips
mac battery optimize

# View battery history
mac battery history

# Analyze battery-draining apps
mac battery apps

# Monitor battery in real-time
mac battery monitor

# Calibrate battery
mac battery calibrate
```

## Requirements

- macOS 10.15 or later
- `pmset` and `ioreg` commands (included with macOS)

## Configuration

No additional configuration required. The plugin automatically detects your battery type and adjusts recommendations accordingly.

## Tips

- Keep battery between 20% and 80% for optimal lifespan
- Avoid extreme temperatures
- Use optimized charging in System Settings
- Run calibration monthly for accurate readings

## License

MIT - Part of Mac Power Tools
EOF
            ;;
            
        update)
            cat > "$readme_file" << 'EOF'
# System Update Plugin

Comprehensive system update management for macOS.

## Features

- **macOS Updates**: Check and install system updates
- **Homebrew Updates**: Update all Homebrew packages and casks
- **Mac App Store**: Update apps from the App Store
- **Package Managers**: Update npm, Ruby gems, Python packages
- **Selective Updates**: Choose specific update targets
- **Interactive Mode**: fzf-powered selection interface

## Installation

This plugin is included with Mac Power Tools by default.

## Usage

```bash
# Update everything
mac update

# Update specific target
mac update brew
mac update mas
mac update npm
mac update ruby
mac update pip
mac update macos

# Interactive selection (requires fzf)
mac update  # Shows menu when fzf is installed
```

## Supported Package Managers

- **Homebrew**: Formulae and Casks
- **Mac App Store**: Via mas-cli
- **npm**: Global Node packages
- **RubyGems**: System and user gems
- **pip**: Python packages
- **macOS**: System software updates

## Configuration

The plugin automatically detects installed package managers and only runs updates for those that are available.

## License

MIT - Part of Mac Power Tools
EOF
            ;;
            
        clean)
            cat > "$readme_file" << 'EOF'
# System Clean Plugin

Deep cleaning utilities for macOS system maintenance.

## Features

- **Cache Cleaning**: Clear system and user caches
- **Log Cleanup**: Remove old log files
- **Downloads Folder**: Organize and clean downloads
- **Xcode Cleanup**: Remove derived data and archives
- **iOS Backups**: Clean old device backups
- **Mail Attachments**: Remove cached email attachments
- **Trash Management**: Empty trash securely
- **Language Files**: Remove unused language packs

## Installation

This plugin is included with Mac Power Tools by default.

## Usage

```bash
# Interactive cleaning menu
mac clean

# Clean specific categories
mac clean cache
mac clean logs
mac clean downloads
mac clean xcode
mac clean ios
mac clean mail
mac clean trash

# Dry run (preview what will be deleted)
mac clean --dry-run

# Force clean without confirmation
mac clean --force
```

## Space Savings

Typical space recovered:
- Xcode: 5-20 GB
- iOS Backups: 2-10 GB per device
- Caches: 1-5 GB
- Logs: 500 MB - 2 GB

## Safety

- Always prompts before deletion
- Skips system-critical files
- Creates list of deleted items
- Dry-run mode available

## License

MIT - Part of Mac Power Tools
EOF
            ;;
            
        *)
            # Generic README for other plugins
            cat > "$readme_file" << EOF
# ${plugin_name^} Plugin

${description:-A Mac Power Tools plugin for system management.}

## Features

This plugin provides ${category:-system} functionality for Mac Power Tools.

## Installation

This plugin is included with Mac Power Tools.

To enable:
\`\`\`bash
mac plugin enable ${plugin_name}
\`\`\`

To disable:
\`\`\`bash
mac plugin disable ${plugin_name}
\`\`\`

## Usage

\`\`\`bash
# Show help
mac ${plugin_name} help

# Run main command
mac ${plugin_name}
\`\`\`

## Version

Current version: ${version:-1.0.0}

## Author

${author:-Mac Power Tools}

## License

MIT - Part of Mac Power Tools
EOF
            ;;
    esac
    
    printf "${GREEN}  ✓ Created README for ${plugin_name}${NC}\n"
}

# Generate READMEs for all plugins
for plugin_dir in "$PLUGINS_DIR"/*; do
    if [ -d "$plugin_dir" ]; then
        generate_readme "$plugin_dir"
    fi
done

# Also generate for core plugins
CORE_DIR="${SCRIPT_DIR}/plugins/core"
if [ -d "$CORE_DIR" ]; then
    for plugin_dir in "$CORE_DIR"/*; do
        if [ -d "$plugin_dir" ]; then
            generate_readme "$plugin_dir"
        fi
    done
fi

printf "\n${GREEN}README generation complete!${NC}\n"
printf "Note: Security validation now requires README.md for all plugins.\n"