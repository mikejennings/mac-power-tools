# Mac Power Tools

[![Version](https://img.shields.io/badge/version-4.0.0-blue)](https://github.com/mac-power-tools/mac-power-tools)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![macOS](https://img.shields.io/badge/macOS-10.15%2B-orange)](https://www.apple.com/macos/)

A powerful, modular macOS system management CLI tool with plugin architecture. Modern replacement for the deprecated mac-cli with enhanced functionality for system updates, monitoring, and maintenance. **Now includes free, open-source alternatives to CleanMyMac features!**

## 🎉 NEW: Pure Plugin Architecture (v4.0.0)

Mac Power Tools now runs on a **100% pure plugin architecture**! Every feature is a modular plugin:

- **Modular Design**: Enable/disable features as plugins
- **Easy Installation**: Install plugins from GitHub or local directories  
- **Plugin Development**: Create custom plugins with our SDK
- **Native Plugins**: All 16 core features are now native plugins (no legacy scripts!)
- **Backward Compatible**: All existing commands work identically

### Quick Start with Plugins

```bash
# List all available plugins
mac plugin list

# Enable a plugin (e.g., battery management)
mac plugin enable battery

# Disable plugins you don't need
mac plugin disable shortcuts

# Install a plugin from GitHub
mac plugin install https://github.com/user/mac-plugin-example

# Check for plugin updates
mac plugin check-updates

# Update all plugins
mac plugin update

# Update specific plugin
mac plugin update battery

# Create your own plugin
./create-plugin.sh my-custom-tool
```

## Core Features

All features are now available as modular plugins that can be enabled/disabled:

| Plugin | Description | Category | Status |
|--------|-------------|----------|--------|
| `update` | System update utilities | system | ✅ Enabled by default |
| `info` | System information tools | system | ✅ Enabled by default |
| `maintenance` | System maintenance utilities | system | ✅ Enabled by default |
| `battery` | Battery management | performance | ✅ Enabled by default |
| `memory` | Memory optimization | performance | ✅ Enabled by default |
| `clean` | Deep system cleaning | maintenance | ⚪ Optional |
| `uninstall` | Application uninstaller | apps | ⚪ Optional |
| `duplicates` | Duplicate file finder | storage | ⚪ Optional |
| `privacy` | Privacy and security tools | security | ⚪ Optional |
| `downloads` | Downloads management | organization | ⚪ Optional |
| `dotfiles` | Dotfiles backup and sync | backup | ⚪ Optional |
| `linuxify` | GNU/Linux environment | system | ⚪ Optional |
| `awake` | Power management | power | ⚪ Optional |
| `shortcuts` | System shortcuts | productivity | ⚪ Optional |

## Feature Details

### 🚀 System Updates
- **Comprehensive Updates**: Update macOS, Homebrew, Mac App Store, npm, Ruby gems, and Python packages
- **Selective Updates**: Target specific package managers
- **Smart Detection**: Only runs updates when needed
- **Safe Operations**: Prompts before applying changes

### 📊 System Information
- **Hardware Info**: CPU, memory, disk usage, network status
- **Performance Monitoring**: Top processes by CPU and memory
- **Battery Status**: Power source, battery health, cycle count (laptops)
- **Temperature Monitoring**: CPU temperature (if tools available)
- **Network Details**: Wi-Fi status, IP addresses, active interfaces

### 🧹 System Maintenance
- **Storage Management**: Empty trash, clear caches, organize downloads
- **File Discovery**: Find large files and directories
- **Log Cleanup**: Remove old log files
- **Network Tools**: Flush DNS cache
- **Spotlight Management**: Rebuild search index
- **Finder Controls**: Toggle hidden files visibility
- **Disk Utilities**: Repair permissions

### 📁 Downloads Management (NEW v1.3.0!)
- **Automatic Sorting**: Files organized by date (YYYY-MM-DD) and type
- **Smart Categories**: Documents, Images, Videos, Code, Archives, and more
- **Multiple Triggers**: Folder Actions, launchd agent, manual sorting
- **File Analytics**: See what's taking up space in Downloads
- **Cleanup Tools**: Remove old downloads with one command
- **Real-time Monitoring**: Watch folder and sort instantly

### 🔒 Privacy & Security Suite (NEW v1.4.0!)
- **Privacy Cleaner**: Remove browser data, history, caches, cookies
- **Security Audit**: Check SIP, FileVault, Firewall, Gatekeeper status
- **Secrets Scanner**: Find exposed API keys, tokens, passwords
- **Permission Manager**: Review app permissions (camera, mic, location)
- **Privacy Hardening**: Enable protective settings with one command
- **Process Monitor**: Detect suspicious activities



### 💾 Power Management
- **Keep Awake**: Prevent Mac from sleeping with screensaver option
  - Shows time remaining and progress bar for timed sessions
  - Status command displays detailed session information
- Sleep, restart, and shutdown commands
- Close all applications at once
- Safe operation with confirmation prompts

### 🔄 Dotfiles & Backup
- **Native iCloud Sync**: Simple dotfiles management without external dependencies
  - Symlinks dotfiles to iCloud Drive for automatic sync
  - Backup and restore configuration files across machines
  - Support for nested configs (.ssh/config, .aws/credentials)
  - Application preferences backup (VS Code, iTerm2, Terminal)
  - Interactive fzf menu for easy management
- **Application Config Support** (NEW v2.2.0!): Backup/restore 25+ app configs
  - Developer tools: Neovim, VSCode, Sublime, Cursor, iTerm2, Warp, tmux
  - Productivity apps: Raycast, Rectangle, Alfred, Karabiner, Hammerspoon
  - Development services: Docker, Kubernetes, npm, yarn, Homebrew Bundle
  - Security tools: 1Password CLI, GitHub CLI, SSH, AWS CLI, GPG
  - `mac dotfiles apps` - Manage application configurations

### 🎯 Interactive Interface (NEW!)
- **fzf Integration**: Fuzzy finder for lightning-fast command selection
  - `mac menu` - Interactive command browser with search
  - Smart auto-detection when no arguments provided
  - Multi-select for batch operations (like app uninstall)
  - Real-time preview and filtering

### 🐧 GNU/Linux Environment (NEW v2.3.0!)
- **Complete Linux Compatibility**: Transform macOS to use GNU tools instead of BSD
  - `mac linuxify` - Install and configure GNU utilities
  - **Core Tools**: coreutils, sed, grep, make, tar, findutils, gawk
  - **Extended Utils** (v2.3.1): util-linux (100+ tools), inetutils (network tools)
  - **Modern CLI**: Optional bat, ripgrep, fd, eza, htop, and more
  - **PATH Configuration**: Automatically prioritizes GNU tools over BSD
  - **Shell Integration**: Configures aliases and environment variables
  - **Status Tracking**: Check installed tools with `mac linuxify status`
  - **Reversible**: Full uninstall support to revert to macOS defaults

### 🌐 Network Diagnostics (NEW v2.4.0!)
- **Comprehensive Network Tools**: Professional network analysis and troubleshooting
  - `mac network status` - Network status with public IP and location
  - `mac network speed` - Run speed tests to measure bandwidth
  - `mac network dns` - Benchmark DNS servers and find the fastest
  - `mac network wifi` - WiFi analyzer with channel recommendations
  - `mac network connections` - View all active network connections
  - `mac network firewall` - Manage macOS firewall settings
  - `mac network reset` - Reset network stack for troubleshooting
  - `mac network ping` - Enhanced ping with color-coded latency
  - `mac network trace` - Enhanced traceroute with hop analysis
  - `mac network ports` - Show listening ports and services

### 💾 Disk Health Management (NEW v2.5.0!)
- **Advanced Disk Monitoring**: Keep your drives healthy and optimized
  - `mac disk health` - SMART status, wear level, and disk health
  - `mac disk benchmark` - Test read/write speeds
  - `mac disk analyze` - Visual space usage by directory
  - `mac disk trim` - Force TRIM on SSDs for performance
  - `mac disk verify` - Run First Aid verification and repair
  - `mac disk temp` - Monitor disk temperatures
  - `mac disk usage` - Visual disk usage with colored bars
  - `mac disk cleanup` - Find large unnecessary files

### 🔋 Battery Management (NEW v2.6.0!)
- **Complete Battery Toolkit**: Maximize battery life and performance
  - `mac battery health` - Detailed health report with cycle count
  - `mac battery status` - Power usage and thermal state
  - `mac battery calibrate` - Step-by-step calibration wizard
  - `mac battery history` - Track degradation over time
  - `mac battery optimize` - Apply recommended power settings
  - `mac battery apps` - See which apps drain your battery
  - `mac battery monitor` - Real-time battery monitoring
  - `mac battery tips` - Expert tips for battery longevity

## Plugin Security

Mac Power Tools includes comprehensive security features to protect your system:

### **Security Validation**
- All plugins are validated before loading
- Scans for dangerous patterns (rm -rf, fork bombs, etc.)
- Checks file permissions (no world-writable files)
- Verifies plugin structure and metadata

### **Plugin Signatures**
Plugins can be signed for additional security:
```bash
# Sign a plugin (for developers)
source lib/plugin-security.sh
sign_plugin plugins/available/my-plugin

# Verification happens automatically on load
```

### **Trusted Sources**
By default, plugins from these sources are trusted:
- `https://github.com/mac-power-tools/`
- `https://github.com/mikejennings/`

### **Security Configuration**
Control security settings via environment variables:
```bash
# Disable security checks (not recommended)
export PLUGIN_SECURITY_ENABLED=false

# Allow unsigned plugins
export PLUGIN_ALLOW_UNSIGNED=true
```

## Plugin Development

### Creating a Plugin

Mac Power Tools makes it easy to create custom plugins:

```bash
# Use the plugin creator tool
./create-plugin.sh my-plugin-name

# Follow the interactive prompts to configure your plugin
# This creates a complete plugin structure with:
# - plugin.json (metadata)
# - main.sh (plugin logic)
# - tests/ (test directory)
# - README.md (documentation)
```

### Plugin Structure

```
plugins/available/my-plugin/
├── plugin.json         # Plugin metadata and configuration (REQUIRED)
├── main.sh            # Main plugin script (REQUIRED)
├── README.md          # Plugin documentation (REQUIRED)
├── tests/             # Plugin tests (recommended)
│   └── test_my-plugin.sh
└── config.json        # User configuration (optional)
```

### Plugin Requirements

Every plugin **MUST** include these files:

1. **plugin.json** - Metadata describing the plugin
2. **main.sh** - The main executable script
3. **README.md** - Documentation explaining what the plugin does

Without these files, the plugin will fail security validation and won't load.

### Plugin API

Plugins have access to a rich API for common operations:

```bash
# Color output functions
print_info "Information message"
print_success "Success message"
print_warning "Warning message"  
print_error "Error message"

# Utility functions
command_exists "git"              # Check if command exists
confirm "Continue?"               # Get user confirmation
show_progress 50 100             # Show progress bar (50/100)

# Configuration
load_plugin_config               # Load plugin settings
save_plugin_config "key" "value" # Save plugin settings
```

### Publishing Plugins

Share your plugins with the community:

1. Create a GitHub repository for your plugin
2. Include all plugin files (plugin.json, main.sh, etc.)
3. Add installation instructions to your README
4. Users can install with: `mac plugin install https://github.com/you/your-plugin`

### Example Plugin

Here's a simple plugin example:

```bash
#!/bin/bash
# Plugin: disk-usage
# Shows disk usage statistics

source "${MAC_POWER_TOOLS_HOME}/lib/plugin-api.sh"

plugin_main() {
    print_info "Disk Usage Statistics"
    df -h | grep -E "^/dev/"
    print_success "Analysis complete"
}

plugin_init
register_command "disk-usage" "Show disk usage statistics"
```

## Installation

### Via Homebrew (Recommended)

```bash
brew tap mikejennings/mac-power-tools
brew install mac-power-tools
```

### Quick Install

```bash
# Clone the repository
git clone https://github.com/mikejennings/mac-power-tools.git
cd mac-power-tools

# Run the installer
./install.sh

# Or manually add to your PATH
echo 'export PATH="$PATH:$HOME/mac-power-tools"' >> ~/.zshrc
source ~/.zshrc
```

### Manual Installation

1. Clone this repository to your preferred location
2. Make the main script executable: `chmod +x mac`
3. Add the directory to your PATH or create an alias:
   ```bash
   alias mac='/path/to/mac-power-tools/mac'
   ```

## Usage

### Basic Commands

```bash
# Show help
mac help

# Update everything
mac update

# Update specific components
mac update brew      # Update Homebrew only
mac update macos     # Check for macOS updates
mac update mas       # Update Mac App Store apps
mac update npm       # Update npm packages
mac update ruby      # Update Ruby gems
mac update pip       # Update Python packages

# System information
mac info             # Show all system information
mac info memory      # Show memory usage
mac info disk        # Show disk usage
mac info network     # Show network status
mac info battery     # Show battery status (laptops)

# Maintenance
mac maintenance      # Interactive maintenance menu
mac clean           # Deep clean system junk (Xcode, caches, logs)
mac trash           # Empty trash
mac cache           # Clear caches
mac large-files     # Find files >100MB
mac dns             # Flush DNS cache
mac hidden          # Toggle hidden files

# CleanMyMac Alternative Features
mac uninstall <app>  # Completely uninstall an application
mac uninstall --list # List all installed applications
mac duplicates       # Find duplicate files in home directory
mac duplicates -i    # Interactive duplicate removal
mac memory          # Show memory status and top consumers
mac memory --optimize # Optimize memory usage

# App Migration
mac migrate-mas      # Analyze and migrate Mac App Store apps to Homebrew
mac migrate-mas -a   # Analyze only (show migration opportunities)
mac migrate-mas -e   # Execute migration (default is dry-run)

mac migrate-apps     # Migrate manually downloaded apps to Homebrew
mac migrate-apps -a  # Analyze what can be migrated
mac migrate-apps -e  # Execute migration (with app backup)

# Dotfiles Management
mac dotfiles            # Interactive menu (requires fzf)
mac dotfiles init       # Initialize iCloud sync
mac dotfiles backup     # Backup all dotfiles
mac dotfiles restore    # Restore from iCloud
mac dotfiles add .vimrc # Add specific file
mac dotfiles list       # Show tracked files
mac dotfiles apps      # Manage application configs
mac dotfiles apps backup neovim  # Backup Neovim config
mac dotfiles apps restore vscode # Restore VSCode settings

# GNU/Linux Environment (NEW v2.3.0!)
mac linuxify            # Install GNU tools interactively
mac linuxify status     # Check installed GNU tools
mac linuxify shell      # Change default shell to GNU bash
mac linuxify uninstall  # Remove GNU configurations

# Downloads Management (NEW v1.3.0!)
mac downloads setup     # Set up automatic sorting
mac downloads sort      # Sort all downloads now
mac downloads watch     # Monitor folder in real-time
mac downloads analyze   # Show folder analytics
mac downloads clean 30  # Clean files older than 30 days
mac downloads status    # Check sorting status

# Privacy & Security (NEW v1.4.0!)
mac privacy clean all   # Clean all browser & system data
mac privacy clean safari --dry-run  # Preview Safari cleanup
mac security audit      # Full security audit
mac security scan       # Scan for exposed secrets
mac privacy protect     # Enable privacy protection

# Power management
mac awake           # Keep Mac awake indefinitely
mac awake --screensaver  # Keep awake with screensaver
mac awake -t 2h     # Keep awake for 2 hours
mac awake --status  # Check status with time remaining
mac awake --stop    # Stop keeping Mac awake
mac sleep           # Put Mac to sleep
mac restart         # Restart Mac
mac shutdown        # Shutdown Mac
```

### Examples

```bash
# Interactive command selection
mac menu                     # Browse all commands with fzf

# Morning routine - update everything
mac update                   # Interactive target selection (or update all)

# Check system performance
mac info                     # Interactive info selection
mac info memory              # Specific memory info

# Clean up disk space (CleanMyMac alternative)
mac clean --analyze     # See what can be cleaned
mac clean              # Deep clean system junk
mac duplicates ~/Downloads  # Find duplicates in Downloads
mac memory --optimize   # Free up RAM

# Uninstall apps completely
mac uninstall "Google Chrome"
mac uninstall --list   # See all installed apps

# Keep Mac awake for presentations
mac awake --screensaver  # Stay awake with screensaver
mac awake -t 1h30m       # Stay awake for 1.5 hours

# Migrate apps to Homebrew for better management
mac migrate-mas -a       # Migrate Mac App Store apps
mac migrate-apps -a      # Migrate manually downloaded apps
mac migrate-apps -e      # Execute migration with backup

# Quick system maintenance
mac maintenance
# Then select option 15 for all maintenance tasks
```

## Requirements

- macOS 10.15 or later
- Command Line Tools for Xcode
- Optional but recommended:
  - Homebrew (for `brew` updates)
  - mas-cli (for Mac App Store updates)
  - npm (for Node.js package updates)
  - fzf (for interactive command selection: `brew install fzf`)

## Project Structure

```
mac-power-tools/
├── mac                     # Main wrapper script
├── scripts/
│   ├── mac-update.sh      # System update utilities
│   ├── mac-info.sh        # System information tools
│   ├── mac-maintenance.sh # Maintenance utilities
│   ├── mac-uninstall.sh   # App uninstaller (NEW)
│   ├── mac-duplicates.sh  # Duplicate finder (NEW)
│   ├── mac-clean.sh       # System junk cleaner (NEW)
│   ├── mac-memory.sh      # Memory optimizer (NEW)
│   ├── mac-awake.sh       # Keep awake/caffeinate (NEW)
│   ├── mac-migrate-mas.sh # MAS to Homebrew migration (NEW)
│   ├── mac-migrate-apps.sh # Manual apps to Homebrew migration (NEW)
│   ├── mac-downloads.sh   # Downloads management (NEW)
│   ├── mac-privacy.sh     # Privacy & security suite (NEW)
│   ├── mac-dotfiles.sh    # Dotfiles & backup sync (NEW)
│   └── mac-fzf.sh         # Interactive fzf integration (NEW)
├── test/                   # Test suite (NEW)
│   ├── test_helper.sh     # Testing framework
│   └── *.test.sh          # Test files for each feature
├── install.sh             # Installation script
├── CLAUDE.md              # AI assistant documentation
├── README.md              # Documentation
└── LICENSE                # MIT License
```

## Features in Detail

### Update System
The update module handles all package managers intelligently:
- Checks for updates before applying
- Shows progress with colored output
- Cleans up after updates
- Handles errors gracefully

### System Information
Comprehensive system monitoring:
- Real-time memory pressure
- Disk usage by volume
- Network interface status
- Battery health metrics
- CPU temperature (when available)

### Maintenance Tools
Powerful cleanup and optimization:
- Safe cache clearing with size reporting
- Smart downloads folder organization
- Large file detection with sorting
- DNS and Spotlight optimization
- Interactive or command-line operation

### CleanMyMac Alternative Features
Complete replacement for paid CleanMyMac features:
- **App Uninstaller**: Remove apps and ALL associated files (preferences, caches, support files)
- **Duplicate Finder**: Find and remove duplicate files with multiple strategies
- **System Junk Cleaner**: Clean Xcode derived data, iOS backups, package manager caches
- **Memory Optimizer**: Real-time memory monitoring, purge inactive RAM, kill memory hogs

## Release Process

### Automatic Releases
Mac Power Tools uses GitHub Actions for automated releases:

1. **Bump version locally**: Run `./bump-version.sh` for interactive version bumping
2. **Push to master**: The auto-release workflow will automatically:
   - Create a git tag
   - Generate a GitHub release with changelog
   - Create release assets (.tar.gz and SHA256)
   - Open an issue in the Homebrew tap for formula updates

### Manual Release
Alternatively, create a tag manually:
```bash
git tag v1.2.5
git push origin v1.2.5
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Run tests: `./test/run_tests.sh`
4. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
5. Push to the branch (`git push origin feature/AmazingFeature`)
6. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Inspired by the original [mac-cli](https://github.com/guarinogabriel/Mac-CLI) project
- Built with love for the macOS community
- Designed for developers and power users

## Support

If you encounter any issues or have suggestions:
- Open an issue on [GitHub](https://github.com/mikejennings/mac-power-tools/issues)
- Check existing issues for solutions
- Provide system information when reporting bugs

## Changelog

### v4.0.3 (2025-08-23)
- Added enhanced release management system
- Added Homebrew tap synchronization tools
- Added security fixes and performance improvements
- Improved startup time by 91% with lazy loading

### v4.0.2 (2025-08-23)
- Fixed 'mac update all' to bypass fzf menu for direct execution

### v4.0.1 (2025-08-21)
- Migrate test suite to plugin architecture - Fix test compatibility with v4.0 pure plugin system

### v2.4.0 (2025-08-17)
- Add complete battery management suite with 8 commands
- Battery health monitoring, optimization, and app energy usage tracking
- Calibration wizard and battery history tracking
- Comprehensive test suite with real system integration

### v2.3.0 (2025-08-16)
- Add GNU/Linux environment support with linuxify command

### v2.2.0 (2025-08-16)
- Add expanded dotfiles application support for 25+ apps

### v2.1.0 (2025-08-15) - LATEST
- **NEW: Manual App Migration** (`mac migrate-apps`)
  - Migrate manually downloaded apps to Homebrew Cask
  - Smart detection using Info.plist bundle IDs
  - Database of 200+ app-to-cask mappings  
  - Automatic backup before migration
  - Support for both /Applications and ~/Applications
  - Interactive mode with safety features

### v1.6.4 (2025-08-07)
- Fix dotfiles backup to be less noisy and remove y/n prompts

### v1.6.3 (2025-08-07)
- Fix dotfiles help text color output formatting

### v1.6.2 (2025-08-07)
- Fix dotfiles output clarity - Cleaner, less confusing backup messages

### v1.6.1 (2025-08-07)
- Expanded application support for dotfiles - Added dev command for developer tool configs

### v1.6.0 (2025-08-07)
- Add native dotfiles sync with iCloud - Simple, elegant dotfiles management without external dependencies

### v1.5.2 (2025-08-07) - LATEST
- **CRITICAL FIX**: Resolved fzf infinite loop where selecting "all" in update menu kept showing menu instead of executing updates
- All fzf functions now call underlying scripts directly instead of recursing through main mac command  
- Added "Esc to exit" instructions to all fzf menu headers for better UX
- Improved user experience with clearer menu navigation
- **Release Status**: ✅ Complete - Available via Homebrew (`brew upgrade mac-power-tools`)

### v1.5.1 (2025-08-06)
- Improve fzf update menu usability - fix 'all' selection issue

### v1.5.0 (2025-08-06)
- Add comprehensive fzf integration for interactive command selection

### v1.4.1 (2025-08-06)
- Remove internal path info from help output

### v1.4.0 (2025-08-07)
- **NEW: Privacy & Security Suite** (`mac privacy`, `mac security`)
  - Browser data cleaner (Safari, Chrome, Firefox)
  - System privacy data removal
  - Comprehensive security audit
  - Exposed secrets scanner
  - App permissions checker
  - Privacy hardening tools
- Security checks: SIP, FileVault, Firewall, Gatekeeper
- Detects suspicious processes and insecure configurations

### v1.3.0 (2025-08-07)
- **NEW: Downloads Management Suite** (`mac downloads`)
  - Automatic sorting by date and file type
  - Folder Actions for instant organization
  - Launchd agent for periodic sorting
  - File analysis and cleanup tools
  - Real-time folder monitoring
- Added comprehensive feature roadmap
- Enhanced project documentation

### v1.2.4 (2025-08-06)
- Added Mac App Store to Homebrew migration tool (`mac migrate-mas`)
- Maps 50+ popular apps for easy migration
- Interactive and automated migration modes
- Improved release automation workflows

### v1.2.3 (2025-08-06)
- Enhanced awake status with time remaining display
- Added progress bar for timed awake sessions
- Improved process persistence for awake mode
- Better session information tracking

### v1.2.2 (2025-08-06)
- Fixed output formatting issues in various scripts
- Improved display of command outputs
- Better handling of newlines in print statements

### v1.2.1 (2025-08-06)
- Added keep awake feature (`mac awake`)
- Support for keeping Mac awake with screensaver
- Timed awake sessions and process monitoring

### v1.2.0 (2025-08-06)
- Added system junk cleaner (`mac clean`)
- Added memory optimizer (`mac memory`)
- Enhanced test coverage for all features

### v1.1.0 (2025-08-06)
- Added complete app uninstaller (`mac uninstall`)
- Added duplicate file finder (`mac duplicates`)
- Introduced comprehensive test suite
- Created testing framework

### v1.0.x (2025-08-06)
- Initial release
- Complete replacement for mac-cli
- System update utilities
- System information tools
- Maintenance utilities
- Power management commands

---

**Made with ❤️ for macOS power users**
