# Mac Power Tools - Claude AI Assistant Instructions

## Project Overview
Mac Power Tools is a comprehensive macOS system management CLI tool with a modular plugin architecture. It provides system updates, monitoring, and maintenance utilities through a flexible plugin system. It's a modern replacement for the deprecated mac-cli project.

### Plugin Architecture (v3.0.1-alpha)
The project now features a complete plugin system allowing users to:
- Enable/disable features as needed
- Install custom plugins from GitHub
- Create their own plugins using the SDK
- Maintain backward compatibility with all existing commands

**Plugin Requirements** (see PLUGIN_SPECIFICATION.md):
- Every plugin MUST have: plugin.json, main.sh, and README.md
- Security validation before loading (pattern scanning, permissions)
- Automatic updates from GitHub repositories
- Metadata caching for O(1) command lookup performance

## Project Structure
```
mac-power-tools/
├── mac                     # Main wrapper script (plugin-enabled)
├── mac-plugin             # New plugin-based architecture script
├── lib/                   # Plugin system libraries
│   ├── plugin-api.sh      # Plugin API functions
│   ├── plugin-loader.sh   # Plugin discovery and loading
│   └── plugin-manager.sh  # Plugin management commands
├── plugins/
│   ├── core/              # Essential plugins (always enabled)
│   ├── available/         # All installed plugins
│   └── enabled/           # Symlinks to active plugins
├── scripts/               # Legacy scripts (wrapped by plugins)
│   ├── mac-update.sh      # System update utilities
│   ├── mac-info.sh        # System information tools
│   └── mac-maintenance.sh # Maintenance utilities
├── create-plugin.sh       # Plugin development SDK
├── migrate-to-plugins.sh  # Migration tool for plugin conversion
├── install.sh             # Installation script
├── README.md              # User documentation
└── LICENSE                # MIT License
```

## Key Commands

### Plugin Management (NEW)
- `mac plugin list` - List all available and enabled plugins
- `mac plugin enable <name>` - Enable a plugin
- `mac plugin disable <name>` - Disable a plugin
- `mac plugin install <url|path>` - Install a plugin from GitHub or local path
- `mac plugin remove <name>` - Remove an installed plugin
- `mac plugin info <name>` - Show detailed plugin information
- `./create-plugin.sh <name>` - Create a new plugin with SDK

### System Management
- `mac update` - Update system packages (Homebrew, npm, Ruby gems, Python packages, Mac App Store)
- `mac info` - Display system information (CPU, memory, disk, network, battery)
- `mac maintenance` - Interactive maintenance menu for system cleanup

### CleanMyMac Replacement Features (v1.1.0+)
- `mac uninstall <app>` - Complete app uninstaller (removes app and all associated files)
- `mac duplicates [path]` - Find and remove duplicate files
- `mac clean` - Deep clean system junk (Xcode, caches, logs, iOS backups)
- `mac memory` - Monitor and optimize memory usage
- `mac migrate-mas` - Migrate Mac App Store apps to Homebrew Cask (v1.2.4+)
- `mac migrate-apps` - Migrate manually downloaded apps to Homebrew Cask

### GNU/Linux Environment (v2.3.0+)
- `mac linuxify` - Install GNU tools and configure Linux-like environment
- `mac linuxify status` - Show installed GNU tools and configuration
- `mac linuxify shell` - Change default shell to Homebrew bash
- `mac linuxify uninstall` - Remove linuxify configuration
- **Features**: Installs GNU coreutils, sed, grep, make, and more via Homebrew
- **PATH Configuration**: Prioritizes GNU tools over BSD defaults
- **Modern Tools**: Optionally installs bat, ripgrep, eza, fd, etc.

### Interactive fzf Integration (v1.5.0+)
- `mac menu` - Interactive command browser with fuzzy finder search
- `mac update` (no args) - Interactive update target selection
- `mac info` (no args) - Interactive system info selection  
- `mac uninstall` (no args) - Interactive app selection with multi-select (TAB)
- `mac duplicates` (no args) - Interactive directory selection for duplicate search
- `mac downloads` (no args) - Interactive downloads management menu
- `mac privacy` (no args) - Interactive privacy and security tools menu
- **Requirements**: `brew install fzf` for full interactive functionality
- **Fallback**: All commands work without fzf, just with different UX

### Power Management
- `mac awake` - Keep Mac awake (prevent sleep)
- `mac awake --screensaver` - Keep awake with screensaver
- `mac awake -t 2h` - Keep awake for 2 hours
- `mac awake --status` - Check status with time remaining and progress bar
- `mac awake --stop` - Stop keeping Mac awake
- `mac sleep` - Put Mac to sleep
- `mac restart` - Restart Mac
- `mac shutdown` - Shutdown Mac

### Basic Maintenance
- `mac trash` - Empty trash
- `mac cache` - Clear system caches
- `mac dns` - Flush DNS cache
- `mac large-files` - Find large files
- `mac logs` - Clean old log files

## Development Guidelines

### Code Style
- **Language**: Bash shell scripts
- **Formatting**: Use consistent indentation (4 spaces)
- **Colors**: Use ANSI color codes for terminal output (already defined in main script)
- **Error Handling**: Always check command existence before execution
- **User Prompts**: Use confirmation prompts for destructive operations

### Testing Requirements
- **Test Suite Available**: Run `./test/run_tests.sh` to execute all tests
- **Test Framework**: Custom bash testing framework in `test/test_helper.sh`
- **Test Coverage**: All major features have comprehensive test suites
- Test commands manually before committing
- Verify scripts work on macOS 10.15+
- Check for command availability (brew, mas, npm, etc.) before using

### Running Tests
```bash
# Run all tests
./test/run_tests.sh

# Run specific test suite
./test/run_tests.sh uninstall
./test/run_tests.sh duplicates
./test/run_tests.sh clean
./test/run_tests.sh memory
```

### Important Patterns
1. **Color Output**: Use predefined color variables (RED, GREEN, YELLOW, BLUE, CYAN, MAGENTA, NC)
2. **Script Location**: Use `SCRIPT_DIR` variable to reference other scripts
3. **Command Routing**: Main `mac` script routes to individual scripts in `scripts/` directory
4. **Safe Operations**: Always prompt user before system-level changes (restart, shutdown, etc.)
5. **Error Messages**: Use colored output with clear error descriptions

### Security Considerations
- Never store credentials or API keys
- Use sudo only when absolutely necessary
- Prompt for confirmation on destructive operations
- Validate user input to prevent injection attacks

### Version Management
- **Current version: 2.4.0** ✅ LATEST
- Version defined in main `mac` script
- Update version when making significant changes
- **Status**: Local release management system active

#### Creating Releases

## 🚀 Local Release Management System

### How it works:
All releases are now managed locally without GitHub Actions to avoid costs:
- Run tests locally with comprehensive test suite
- Create release archives and tags manually
- Update Homebrew formula from your local machine
- **Complete control**: No external dependencies or costs!

### Release Workflow:

1. **Version Bump**:
   ```bash
   ./bump-version.sh
   # Interactive menu to bump version
   # Commits locally and optionally runs tests
   ```

2. **Run Tests**:
   ```bash
   ./local-test.sh        # Run all tests
   ./local-test.sh quick  # Run quick tests only
   ```

3. **Create Release**:
   ```bash
   ./local-release.sh release  # Full release process
   # Or use interactive menu:
   ./local-release.sh
   ```

### Local Scripts:

- **bump-version.sh**: Bump version and update files
- **local-test.sh**: Comprehensive test suite
- **local-release.sh**: Release management (replaces GitHub Actions)

### Common Tasks

#### Adding New Commands
1. Add command case in main `mac` script
2. Create or update appropriate script in `scripts/` directory
3. Update help text in `show_help()` function
4. Test command thoroughly

#### Updating Existing Commands
1. Locate the relevant script in `scripts/` directory
2. Make changes following existing patterns
3. Test all affected functionality
4. Update help text if behavior changes

### Debugging
- Use `set -x` for verbose output during debugging
- Check `$?` for command exit codes
- Use `printf` instead of `echo` for consistent output
- Test with different macOS versions when possible

### Dependencies
- **Required**: macOS 10.15+, Command Line Tools for Xcode
- **Optional**: Homebrew, mas-cli, npm, Ruby, Python
- Always check for optional dependencies before using

### Git Workflow
- Main branch: `master`
- Commit message format: Clear, concise descriptions of changes
- Run manual tests before committing
- Keep commits focused on single features/fixes

## Local Development Workflow (No GitHub Actions)

### Available Local Scripts

1. **local-test.sh** - Comprehensive test suite
   ```bash
   ./local-test.sh         # Run all tests
   ./local-test.sh quick   # Quick tests only
   ./local-test.sh syntax  # Syntax check only
   ```
   - Validates bash scripts
   - Runs shellcheck linting (if installed)
   - Checks file permissions
   - Validates version consistency
   - Runs unit tests

2. **local-release.sh** - Release management
   ```bash
   ./local-release.sh              # Interactive menu
   ./local-release.sh release      # Full release
   ./local-release.sh test         # Run tests only
   ./local-release.sh archive      # Create release archive
   ```
   - Creates release archives (.tar.gz)
   - Generates SHA256 checksums
   - Creates and pushes git tags
   - Updates Homebrew formula locally

3. **bump-version.sh** - Version management
   ```bash
   ./bump-version.sh
   ```
   - Interactive version bumping
   - Updates version in all files
   - Commits changes locally
   - Optionally runs tests and creates release

### Development Workflow

1. **Make changes** to the codebase
2. **Run tests** with `./local-test.sh`
3. **Bump version** with `./bump-version.sh`
4. **Create release** with `./local-release.sh release`
5. **Push to GitHub** when ready: `git push origin master`

### Why Local-Only?

- **No costs**: GitHub Actions can incur charges for private repos
- **Full control**: Everything runs on your machine
- **Faster feedback**: No waiting for CI/CD pipelines
- **Privacy**: Keep development local until ready to share
- **Simplicity**: No YAML debugging or workflow issues

## 🚧 Development Progress (As of 2025-08-17)

### Completed Features (3/8)
1. **✅ Network Diagnostics** (`feature/network-diagnostics`)
   - 10 commands implemented
   - 12 comprehensive tests passing
   - Ready for merge

2. **✅ Disk Health Management** (`feature/disk-health`)
   - 8 commands implemented
   - 12 comprehensive tests passing
   - Ready for merge

3. **✅ Battery Management** (`feature/battery-management`)
   - 8 commands implemented
   - 12 comprehensive tests passing (1 TODO for human contribution)
   - Ready for merge

### Pending Features (5/8)
4. **📋 Process Manager** - Enhanced process monitoring and control
   - Planned: `mac process top`, `kill`, `limit`, `startup`, `ports`
   - Better than Activity Monitor with CPU/memory limits
   - Login items and launch agents management
   
5. **📋 Scheduled Maintenance** - Automated system maintenance
   - Planned: `mac schedule daily`, `weekly`, `custom`, `status`, `logs`
   - Automate existing maintenance commands
   - Cron/launchd integration for scheduling
   
6. **📋 Bluetooth Manager** - Device management and troubleshooting
   - Planned: `mac bluetooth devices`, `reset`, `disconnect`, `monitor`
   - Battery levels for connected devices
   - Quick disconnect and reset utilities
   
7. **📋 Time Machine Enhancements** - Advanced backup management
   - Planned: `mac backup status`, `thin`, `verify`, `browse`
   - Thin old backups to save space
   - Verify backup integrity
   
8. **📋 System Shortcuts** - Quick access to common tasks
   - Planned: `mac quick screenshot`, `lock`, `caffeinate`, `airplane`
   - Enhanced screenshots with annotations
   - Quick system toggles

### Testing Strategy
- **Comprehensive Test Suites**: Each feature has 12+ tests
- **Mock System**: Safe testing without system modifications
- **Performance Tests**: All commands complete in <3 seconds
- **Integration Tests**: Multi-command sequences verified
- **Current Test Pass Rate**: 100% (36/36 tests passing)

### Branch Strategy
- Each feature in isolated branch: `feature/[feature-name]`
- Test suite included with each feature
- Master branch remains stable
- Target: v3.0.0 with all 8 features merged

## Release History

### v4.0.0 (2025-08-20) - Pure Plugin Architecture 🚀
- **BREAKING CHANGE**: Complete migration to pure plugin system
- **Removed**: Legacy scripts directory (archived in legacy-archive/)
- **Converted**: All 16 commands now run as native plugins
- **Architecture**: Single unified entry point with plugin-first routing
- **Performance**: Eliminated wrapper overhead, improved load times
- **Benefits**:
  - 100% modular architecture
  - Every feature is a self-contained plugin
  - Consistent API usage across all commands
  - Easier maintenance and testing
  - Ready for community plugin development
- **Migration**: Seamless for users - all commands work identically
- **Technical**: 
  - 16 native plugin implementations
  - 0 legacy script dependencies
  - Unified plugin API usage
  - Complete test coverage maintained

### v3.0.1-alpha (2025-08-20) - Enhanced Plugin Security & Updates 🔒
- **SECURITY UPDATE**: Added comprehensive plugin validation system
- **Plugin Updates**: New `mac plugin update` command for GitHub plugins
- **Security Features**:
  - Validation before loading any plugin
  - Dangerous pattern scanning (rm -rf, fork bombs, etc.)
  - Plugin signature verification with checksums
  - Permission checking (no world-writable files)
  - Trusted source verification for installations
- **Performance**: Added metadata caching for O(1) command lookup
- **Error Handling**: Proper error boundaries around plugin execution
- **Update System**:
  - Check for updates: `mac plugin check-updates`
  - Update single plugin: `mac plugin update [name]`
  - Update all plugins: `mac plugin update`
  - Automatic backup before updates with rollback on failure
- **Version Comparison**: Semantic versioning support for updates

### v3.0.0-alpha (2025-08-20) - Plugin Architecture 🎉
- **MAJOR UPDATE**: Complete plugin architecture implementation
- **Plugin System**: Modular design allowing users to enable/disable features
- **Plugin Manager**: Install, remove, enable, disable plugins with simple commands
- **Plugin SDK**: Create custom plugins with `./create-plugin.sh`
- **Plugin API**: Rich API for plugin developers (colors, utilities, configuration)
- **Backward Compatible**: All existing commands work through plugin wrappers
- **Migration Tool**: Automatic conversion of existing scripts to plugins
- **16 Default Plugins**: All existing features converted to modular plugins
- **GitHub Integration**: Install plugins directly from GitHub repositories
- **Documentation**: Complete plugin development guide and API reference
- **Benefits**:
  - Users can disable features they don't need (e.g., battery management on desktops)
  - Easier maintenance with isolated plugin code
  - Community can create and share custom plugins
  - Better performance by loading only needed features
  - Cleaner codebase with standardized plugin structure

### v2.6.0 (In Development) - Battery Management
- **NEW FEATURE**: Complete battery management suite
- **Commands**: health, status, calibrate, history, optimize, apps, monitor, tips
- **Key Features**: Cycle tracking, degradation history, calibration wizard
- **Testing**: 12 comprehensive tests with mock system commands

### v2.5.0 (In Development) - Disk Health Management  
- **NEW FEATURE**: Advanced disk monitoring and maintenance
- **Commands**: health, benchmark, analyze, trim, verify, temp, usage, cleanup
- **Key Features**: SMART monitoring, speed benchmarks, space analysis
- **Testing**: 12 comprehensive tests with performance validation

### v2.4.0 (In Development) - Network Diagnostics
- **NEW FEATURE**: Professional network analysis tools
- **Commands**: status, speed, dns, wifi, connections, firewall, reset, ping, trace, ports
- **Key Features**: DNS benchmarking, WiFi analysis, speed tests
- **Testing**: 12 comprehensive tests with mock network data

### v2.3.1 (2025-08-17) - CURRENT STABLE RELEASE ✅
- **ENHANCED**: Linuxify feature with extended GNU utilities support
- **Added util-linux**: Provides 100+ utilities (cal, column, hexdump, rename, etc.)
- **Added inetutils**: Network tools (ftp, telnet, traceroute, whois, etc.)
- **Fixed**: Bash 3.2 compatibility issues with arithmetic operations
- **Improved**: Status display now shows core, extended, and optional packages
- **Better UX**: Interactive prompts for different levels of GNU tool installation

### v2.3.0 (2025-08-17)
- **NEW FEATURE**: GNU/Linux environment support via `mac linuxify` command
- **Installs GNU Tools**: coreutils, sed, grep, make, tar, which, and more
- **PATH Configuration**: Automatically configures PATH to prioritize GNU tools
- **Shell Integration**: Updates shell config files with aliases and environment
- **Modern CLI Tools**: Optional installation of bat, ripgrep, eza, fd, etc.
- **Homebrew Integration**: Uses Homebrew for all package management
- **Status Tracking**: Check installed tools and configuration with `mac linuxify status`
- **Reversible**: Full uninstall support to revert to macOS defaults

### v2.2.0 (2025-08-17)
- **MAJOR FEATURE**: Expanded dotfiles application support for 25+ apps
- **Application Registry**: Support for developer tools, productivity apps, services
- **Smart Detection**: Automatically detects installed applications
- **Safety Features**: Excludes sensitive files (keys, tokens, credentials)
- **Interactive Selection**: fzf integration for batch operations
- **Categories**: Developer Tools, Productivity, Services, Security tools

### v1.5.2 (2025-08-07)
- **CRITICAL FIX**: Fixed infinite loop bug in fzf integration where selecting "all" in update menu would keep showing the menu instead of executing updates
- **Technical Details**: Changed fzf functions to call underlying scripts directly (`mac-update.sh`) instead of recursing through main `mac` command
- **UX Improvements**: Added "Esc to exit" instructions to all fzf menu headers for better user experience
- **Release Process**: Complete automation from commit to Homebrew formula update
- **User Impact**: Resolved major usability issue affecting interactive command selection
- **Status**: ✅ Released, GitHub Actions workflows completed, Homebrew formula updated

### v1.5.1 (2025-08-06)
- **fzf Menu Enhancements**: Improved update menu usability with clearer instructions
- **Selection Fix**: Made "all" option more discoverable and selectable in fzf interface
- **User Feedback**: Added default fallback for easier "all" selection
- **Status**: Superseded by v1.5.2 due to infinite loop discovery

### v1.5.0 (2025-08-06)
- **NEW FEATURE**: Comprehensive fzf integration for interactive command selection
- **Interactive Menus**: Added fuzzy finder support for update, info, uninstall, privacy, downloads, and duplicates commands
- **Command Browser**: New `mac menu` command for browsing all available commands with search
- **Multi-select**: TAB support for batch operations (like app uninstalling)
- **Branch Workflow**: Implemented proper git workflow (feature branch → PR → merge → release)
- **Status**: Foundation for interactive features, enhanced by v1.5.1 and v1.5.2

### v1.4.1 (2025-08-07)
- Remove internal path info from help output
- Fix help text showing Homebrew Cellar paths
- Cleaner help display for end users

### v1.4.0 (2025-08-07)
- Added Privacy & Security Suite (`mac privacy`, `mac security`)
- Browser data cleaners for Safari, Chrome, Firefox
- Comprehensive security audit with 8+ checks
- Exposed secrets scanner for API keys and passwords
- Privacy hardening with one-command protection
- App permissions review

### v1.3.0 (2025-08-07)
- Added Downloads Management Suite (`mac downloads`)
- Automatic file sorting with Folder Actions and launchd
- Downloads analytics and cleanup tools
- Real-time folder monitoring
- Comprehensive feature roadmap added

### v1.2.4 (2025-08-06)
- Added Mac App Store to Homebrew migration tool (`mac migrate-mas`)
- Maps 50+ popular apps for easy migration
- Fixed GitHub Actions workflow YAML syntax issues
- Improved release automation


### v1.2.3 (2025-08-06)
- Enhanced awake status with time remaining display
- Added progress bar for timed awake sessions
- Improved process persistence for awake mode
- Better session information tracking

### v1.2.2 (2025-08-06)
- Fixed output formatting issues
- Improved newline handling in scripts
- Cleaner command output display

### v1.2.1 (2025-08-06)
- Added keep awake feature (`mac awake`)
- Screensaver support while keeping Mac awake
- Timed sessions and process monitoring

### v1.2.0 (2025-08-06)
- Added system junk cleaner (`mac clean`)
- Added memory optimizer (`mac memory`)
- Enhanced test coverage

### v1.1.0 (2025-08-06)
- Added complete app uninstaller (`mac uninstall`)
- Added duplicate file finder (`mac duplicates`)
- Introduced comprehensive test suite
- Created testing framework

### v1.0.x
- Initial release with basic maintenance features
- System update utilities
- System information tools

## Recent Development Patterns & Lessons Learned (v1.5.x)

### fzf Integration Architecture (Critical Learning)
The v1.5.x series revealed important patterns for interactive shell script design:

**❌ AVOID: Command Recursion**
```bash
# BAD - Creates infinite loops
case "$target" in
    all) exec mac update ;;  # This triggers fzf detection again!
esac
```

**✅ CORRECT: Direct Script Execution**
```bash
# GOOD - Calls scripts directly
local scripts_dir="$(dirname "${BASH_SOURCE[0]}")"
case "$target" in
    all) exec "$scripts_dir/mac-update.sh" ;;  # Direct script call
esac
```

### Key Development Insights
1. **User Feedback via Screenshots**: Visual feedback from users showing exact issues (menu loops, selection problems) is invaluable
2. **Iterative Release Process**: v1.5.0 → v1.5.1 → v1.5.2 shows importance of quick iterations based on real usage
3. **Automated Release Pipeline**: GitHub Actions automation from commit to Homebrew formula update works flawlessly
4. **Shell Script Recursion**: Be extremely careful with `exec mac command` patterns in wrapper scripts
5. **fzf UX Patterns**: Always provide escape instructions and clear default selections

### Development Workflow That Works
1. **User Reports Issue** (via screenshot/demo)
2. **Quick Fix & Test** (focus on specific problem)  
3. **Version Bump** (bump-version.sh or manual)
4. **Commit & Push** (triggers auto-release)
5. **GitHub Actions** (creates release, updates Homebrew)
6. **User Verification** (brew upgrade mac-power-tools)

### fzf Integration Best Practices
- Always call underlying scripts directly, never recurse through main wrapper
- Provide clear exit instructions ("Esc to exit")
- Use consistent prompt styles across all menus
- Include preview windows for better UX
- Test "all" or default selections thoroughly
- Use `$(dirname "${BASH_SOURCE[0]}")` for script directory resolution

## ✅ Expanded Application Support for Dotfiles (v2.2.0)

**COMPLETED**: The dotfiles system now supports 25+ applications across 4 categories!

### Supported Applications

#### Developer Tools (Priority 1) - ✅ Implemented
- **Neovim** - ~/.config/nvim/ directory
- **Visual Studio Code** - Settings, keybindings, snippets
- **Sublime Text** - Packages/User directory
- **Cursor** - VS Code-like settings
- **iTerm2** - Preferences plist
- **Warp Terminal** - ~/.warp/
- **Alacritty** - ~/.config/alacritty/
- **Oh My Zsh** - ~/.oh-my-zsh/custom/
- **tmux** - ~/.tmux.conf and ~/.tmux/
- **Homebrew Bundle** - ~/Brewfile

#### Productivity Tools (Priority 2) - ✅ Implemented
- **Alfred** - Workflows and preferences
- **Rectangle/Rectangle Pro** - Window management prefs
- **Raycast** - Extensions and settings
- **Karabiner-Elements** - ~/.config/karabiner/
- **Hammerspoon** - ~/.hammerspoon/

#### Development Services (Priority 3) - ✅ Implemented
- **Docker Desktop** - config.json (excludes credentials)
- **Kubernetes** - ~/.kube/config
- **npm** - .npmrc (excludes auth tokens)
- **Yarn** - .yarnrc and config

#### Security & Privacy Tools (Priority 4) - ✅ Implemented
- **1Password CLI** - ~/.config/op/ (excludes sessions)
- **GitHub CLI** - ~/.config/gh/ (excludes auth)
- **SSH** - config and known_hosts only (never private keys)
- **AWS CLI** - config only (excludes credentials)
- **GPG** - config files only (excludes keys)

### Usage

```bash
# List all available apps and their installation status
mac dotfiles apps list

# Show installed apps with config sizes
mac dotfiles apps status

# Backup specific app
mac dotfiles apps backup vscode

# Interactive backup (with fzf)
mac dotfiles apps backup

# Restore specific app
mac dotfiles apps restore vscode

# Backup all dotfiles AND app configs
mac dotfiles backup --apps

# Backup only app configs
mac dotfiles backup --only-apps
```

### Safety Features Implemented
- ✅ Automatic exclusion of sensitive files (keys, tokens, credentials)
- ✅ Smart detection of installed applications
- ✅ Size calculation before backup
- ✅ Confirmation prompts for overwrites
- ✅ Compatible with bash 3.2 (macOS default)

## Implementation Notes for Remaining Features

### Next Steps for Development
1. **Complete Battery Management Feature**
   - Implement the `test_battery_apps()` function marked with TODO(human)
   - Test the battery history tracking over time
   - Verify calibration wizard works correctly

2. **Process Manager Implementation**
   - Use `ps`, `top`, `lsof` for process information
   - Implement CPU/memory limiting with `cpulimit` or `nice`
   - Parse and manage login items from `~/Library/LaunchAgents`

3. **Scheduled Maintenance**
   - Create launchd plists for scheduling
   - Store schedules in `~/.mac-power-tools/schedules/`
   - Log outputs to `~/.mac-power-tools/logs/`

4. **Bluetooth Manager**
   - Use `blueutil` for Bluetooth control (brew install blueutil)
   - Parse `system_profiler SPBluetoothDataType` for device info
   - Implement connection monitoring with periodic checks

5. **Time Machine Enhancements**
   - Use `tmutil` for Time Machine operations
   - Parse backup metadata from `/Volumes/[Backup]/Backups.backupdb/`
   - Implement thin with `tmutil delete` for old snapshots

6. **System Shortcuts**
   - Use `screencapture` command for screenshots
   - Implement lock with `pmset displaysleepnow`
   - Quick toggles using `networksetup` and system commands

### Testing Requirements for New Features
- Minimum 12 tests per feature
- Mock all system commands for safety
- Performance tests (<3 second response)
- Integration tests between related commands
- Help text validation

## Notes for AI Assistants
- This is a system administration tool - focus on safety and reliability
- Always preserve existing functionality when making changes
- Test commands in isolation before integrating
- Consider edge cases (missing dependencies, different macOS versions)
- Maintain backward compatibility where possible
- Keep user experience consistent with existing commands
- **CleanMyMac Alternative**: This tool provides free, open-source alternatives to CleanMyMac features
- **Testing is Required**: Always write tests for new features using the test framework
- **Lint and Typecheck**: Run appropriate linters when available
- **fzf Integration**: Follow the patterns established in v1.5.2 - direct script execution, no recursion
- **User-Driven Development**: Users provide excellent feedback via screenshots showing exact UX issues
- **IMPORTANT: Always bump version and push to master** when making changes to this project
- **Automatic Homebrew Updates**: Version bumps trigger automatic Homebrew formula updates within ~1 minute
- **Dotfiles Expansion**: When implementing new app support, check Mackup's implementation for reference
- **MANDATORY DOCUMENTATION**: When adding ANY new feature or making changes:
  - ALWAYS update README.md with user-facing documentation and examples
  - ALWAYS update CLAUDE.md with release notes and technical details
  - NEVER ask if documentation should be updated - just do it automatically
  - Include feature descriptions, usage examples, and version history
- memorize
- memorize
- to memorize