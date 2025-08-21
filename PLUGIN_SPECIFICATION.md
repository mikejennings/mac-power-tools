# Mac Power Tools Plugin Specification v1.0

## Overview

This document defines the specification for Mac Power Tools plugins. All plugins must conform to this specification to be compatible with the plugin system.

## Required Files

Every plugin **MUST** contain these three files:

### 1. plugin.json (REQUIRED)
The metadata file describing the plugin.

```json
{
  "name": "plugin-name",           // REQUIRED: Unique plugin identifier
  "version": "1.0.0",              // REQUIRED: Semantic version (major.minor.patch)
  "description": "Short desc",     // REQUIRED: One-line description
  "author": "Author Name",         // REQUIRED: Plugin author
  "category": "system",            // REQUIRED: Plugin category
  "commands": ["cmd1", "cmd2"],    // REQUIRED: Commands this plugin handles
  "dependencies": ["git", "jq"],   // OPTIONAL: Required system commands
  "homepage": "https://...",       // OPTIONAL: Plugin homepage/repo
  "license": "MIT"                 // OPTIONAL: License identifier
}
```

#### Categories
- `system` - System management and configuration
- `performance` - Performance monitoring and optimization
- `security` - Security and privacy tools
- `apps` - Application management
- `network` - Network utilities
- `storage` - Storage and file management
- `backup` - Backup and sync utilities
- `development` - Developer tools
- `productivity` - Productivity enhancements
- `other` - Miscellaneous plugins

### 2. main.sh (REQUIRED)
The main executable script for the plugin.

```bash
#!/bin/bash

# Source the plugin API
source "${MAC_POWER_TOOLS_HOME}/lib/plugin-api.sh"

# Main entry point
plugin_main() {
    local command=${1:-help}
    shift
    
    case "$command" in
        help)
            show_help
            ;;
        *)
            # Handle other commands
            ;;
    esac
}

# Show help
show_help() {
    printf "Usage: mac [plugin-name] [command]\n"
}

# Initialize plugin
plugin_init

# Execute if called directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    plugin_main "$@"
fi
```

### 3. README.md (REQUIRED)
Documentation explaining the plugin's purpose and usage.

```markdown
# Plugin Name

Brief description of what this plugin does.

## Features

- Feature 1
- Feature 2
- Feature 3

## Installation

```bash
mac plugin install [plugin-source]
mac plugin enable [plugin-name]
```

## Usage

```bash
# Basic usage
mac [plugin-name] [command]

# Examples
mac [plugin-name] help
mac [plugin-name] status
```

## Configuration

Describe any configuration options.

## Requirements

- macOS version requirements
- System dependencies
- Other requirements

## License

License information
```

## Optional Files

### tests/ directory
Recommended for plugin quality assurance.

```bash
tests/
└── test_plugin-name.sh
```

### config.json
User-specific configuration (stored in plugin directory).

```json
{
  "setting1": "value1",
  "setting2": true,
  "setting3": 123
}
```

### .checksum
Plugin signature for security verification (auto-generated).

## Plugin API

Plugins have access to these API functions:

### Output Functions
- `print_info(message)` - Information message (blue)
- `print_success(message)` - Success message (green)
- `print_warning(message)` - Warning message (yellow)
- `print_error(message)` - Error message (red)

### Utility Functions
- `command_exists(cmd)` - Check if command exists
- `confirm(prompt)` - Get user confirmation
- `show_progress(current, total)` - Display progress bar
- `check_dependencies(deps...)` - Verify dependencies

### Configuration Functions
- `load_plugin_config()` - Load plugin configuration
- `save_plugin_config(key, value)` - Save configuration value

### Plugin Metadata
- `plugin_dir()` - Get plugin directory path
- `plugin_name()` - Get plugin name
- `plugin_version()` - Get plugin version

## Security Requirements

Plugins must pass security validation:

1. **No Dangerous Patterns**: No `rm -rf /`, fork bombs, etc.
2. **Proper Permissions**: No world-writable files
3. **Valid Structure**: All required files present
4. **Valid JSON**: plugin.json must be valid JSON

## Installation Methods

### From GitHub
```bash
mac plugin install https://github.com/user/plugin-repo
```

### From Local Directory
```bash
mac plugin install /path/to/plugin
```

### From Registry (Future)
```bash
mac plugin install plugin-name
```

## Update Support

Plugins installed from GitHub support automatic updates:

```bash
# Check for updates
mac plugin check-updates

# Update specific plugin
mac plugin update plugin-name

# Update all plugins
mac plugin update
```

## Best Practices

1. **Documentation**: Write clear, comprehensive README files
2. **Error Handling**: Handle errors gracefully
3. **Dependencies**: Minimize external dependencies
4. **Testing**: Include test suites
5. **Versioning**: Use semantic versioning
6. **Security**: Never execute untrusted input
7. **Performance**: Cache expensive operations
8. **User Experience**: Provide helpful error messages

## Example Plugin

See the `battery` plugin for a complete example:
- Location: `plugins/available/battery/`
- Features: Multiple commands, help system, error handling
- Documentation: Comprehensive README with examples

## Version History

- **v1.0** (2025-08-20): Initial specification
  - Required files: plugin.json, main.sh, README.md
  - Security validation
  - Update support
  - Plugin API

## Contributing

To contribute a plugin:

1. Follow this specification exactly
2. Test thoroughly on macOS 10.15+
3. Include comprehensive documentation
4. Add security signature if distributing publicly
5. Submit to the plugin registry (when available)

## License

This specification is part of Mac Power Tools (MIT License).