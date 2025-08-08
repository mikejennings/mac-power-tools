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
- **Current version: 1.6.4** ✅ LATEST (Released 2025-08-07)
- Version defined in main `mac` script
- Update version when making significant changes
- Releases automatically update Homebrew formula via GitHub Actions
- **Status**: All systems operational, Homebrew formula updated successfully

#### Creating Releases

## 🚀 Automatic Release System

### How it works:
When you push to master and the VERSION in the `mac` script has changed, it will automatically:
- Create a git tag
- Create a GitHub release with changelog
- Generate release assets (.tar.gz and SHA256)
- Trigger the Homebrew formula update workflow
- Update the Homebrew tap repository with the new version
- **Complete automation**: From commit to Homebrew in ~1 minute!

### Three ways to create releases:

1. **Quick local version bump** (Recommended):
   ```bash
   ./bump-version.sh
   # Interactive menu to bump version
   # Automatically commits and can push to trigger release
   ```

2. **GitHub Actions UI**:
   - Go to Actions → Version Bump → Run workflow
   - Select patch/minor/major
   - Creates a PR with version changes

3. **Manual tag**:
   ```bash
   git tag v1.2.4
   git push origin v1.2.4
   ```

The auto-release workflow monitors the `mac` script, `scripts/` directory, and `README.md` for changes. When it detects a version change that doesn't have a corresponding tag, it automatically creates a release.

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

## GitHub Actions Workflows

### Available Workflows

1. **auto-release.yml** - Automatic release on version change
   - Triggers on push to master when VERSION changes
   - Creates git tag and GitHub release
   - Extracts changelog from README.md automatically
   - Automatically triggers Homebrew formula update workflow
   - Homebrew tap is updated within ~30 seconds

2. **release.yml** - Manual release on tag push
   - Triggers when pushing tags like `v1.2.3`
   - Creates release assets (.tar.gz and SHA256)
   - Opens issue in Homebrew tap for formula update

3. **test.yml** - Runs tests on every push
   - Validates bash scripts
   - Runs shellcheck linting
   - Executes test suite

4. **version-bump.yml** - Interactive version bumping
   - Manual workflow dispatch from GitHub Actions UI
   - Creates PR with version changes
   - Options for patch/minor/major bumps

### Workflow Troubleshooting

If workflows fail with YAML syntax errors:
- Avoid multi-line strings with quotes in YAML
- Use echo commands or heredocs in bash scripts
- Use file-based approach for complex strings (--body-file)
- Validate with: `ruby -e "require 'yaml'; YAML.load_file('.github/workflows/file.yml')"`

### Common Workflow Issues and Fixes

1. **Multi-line strings in YAML**: Use `|` or `>` for literal/folded strings, or move to bash script
2. **Heredocs in YAML**: Better to use echo commands line by line
3. **GitHub CLI in workflows**: Always use `--body-file` instead of inline `--body` for complex content
4. **Permissions**: Add `issues: write` permission for creating issues

## Release History

### v1.5.2 (2025-08-07) - CURRENT RELEASE ✅
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

## TODO: Expanded Application Support for Dotfiles

### Priority 1 - Developer Tools
- [ ] **Neovim** - ~/.config/nvim/ directory
- [ ] **Sublime Text** - ~/Library/Application Support/Sublime Text/
- [ ] **JetBrains IDEs** - ~/Library/Application Support/JetBrains/
- [ ] **Zed Editor** - ~/.config/zed/settings.json
- [ ] **Cursor** - Similar to VS Code settings
- [ ] **Warp Terminal** - ~/.warp/
- [ ] **Alacritty** - ~/.config/alacritty/
- [ ] **Oh My Zsh** - ~/.oh-my-zsh/custom/
- [ ] **tmux** - ~/.tmux.conf and ~/.tmux/
- [ ] **Homebrew Bundle** - ~/Brewfile

### Priority 2 - Productivity Tools
- [ ] **Alfred** - ~/Library/Application Support/Alfred/
- [ ] **Rectangle/Spectacle** - Window management prefs
- [ ] **Raycast** - ~/Library/Application Support/com.raycast.macos/
- [ ] **Karabiner-Elements** - ~/.config/karabiner/
- [ ] **BetterTouchTool** - ~/Library/Application Support/BetterTouchTool/
- [ ] **Hammerspoon** - ~/.hammerspoon/
- [ ] **Keyboard Maestro** - ~/Library/Application Support/Keyboard Maestro/

### Priority 3 - Development Services
- [ ] **Docker Desktop** - ~/.docker/config.json
- [ ] **Kubernetes** - ~/.kube/ (beyond just config)
- [ ] **Postgres/MySQL** - Config files
- [ ] **Redis** - Config files
- [ ] **npm/yarn/pnpm** - RC files and global configs
- [ ] **Ruby/rbenv** - ~/.rbenv/ and .ruby-version
- [ ] **Python/pyenv** - ~/.pyenv/ and .python-version
- [ ] **Rust/cargo** - ~/.cargo/config.toml

### Priority 4 - Security & Privacy Tools
- [ ] **1Password CLI** - ~/.config/op/
- [ ] **GPG** - ~/.gnupg/ (careful with private keys!)
- [ ] **SSH** - Full ~/.ssh/ directory support
- [ ] **AWS CLI v2** - Additional config files
- [ ] **GitHub CLI** - ~/.config/gh/

### Implementation Approach
1. Add an `--apps` flag to `mac dotfiles backup` for application configs
2. Create app-specific backup functions in mac-dotfiles.sh
3. Add interactive selection for which apps to sync
4. Implement smart detection of installed applications
5. Add `mac dotfiles apps` subcommand to manage app preferences
6. Create restoration testing for each app config

### Safety Considerations
- Never sync sensitive credentials or private keys
- Add .gitignore patterns for each app's sensitive files
- Implement confirmation prompts for large directories
- Create app-specific exclude lists
- Add dry-run mode for testing

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
- **Dotfiles Expansion**: When implementing new app support, check Mackup's implementation for reference