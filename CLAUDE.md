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
- Current version: 1.5.1
- Version defined in main `mac` script
- Update version when making significant changes
- Releases automatically update Homebrew formula via GitHub Actions

#### Creating Releases

## 🚀 Automatic Release System

### How it works:
When you push to master and the VERSION in the `mac` script has changed, it will automatically:
- Create a git tag
- Create a GitHub release with changelog
- Generate release assets (.tar.gz and SHA256)
- Create an issue in the Homebrew tap repo for updating the formula

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
   - Creates git tag, GitHub release, and Homebrew update issue
   - Extracts changelog from README.md automatically

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