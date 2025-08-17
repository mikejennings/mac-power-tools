# Mac Power Tools - Claude AI Assistant Instructions

## Project Overview
Mac Power Tools is a comprehensive macOS system management CLI tool that provides system updates, monitoring, and maintenance utilities. It's a modern replacement for the deprecated mac-cli project.

## Project Structure
```
mac-power-tools/
├── mac                     # Main wrapper script (Bash)
├── scripts/
│   ├── mac-update.sh      # System update utilities
│   ├── mac-info.sh        # System information tools
│   └── mac-maintenance.sh # Maintenance utilities
├── install.sh             # Installation script
├── README.md              # User documentation
└── LICENSE                # MIT License
```

## Key Commands

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
- **Current version: 2.3.1** ✅ LATEST
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

## Release History

### v2.3.1 (2025-08-17) - CURRENT RELEASE ✅
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