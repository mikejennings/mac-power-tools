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
- `mac update` - Update system packages (Homebrew, npm, Ruby gems, Python packages, Mac App Store)
- `mac info` - Display system information (CPU, memory, disk, network, battery)
- `mac maintenance` - Interactive maintenance menu for system cleanup
- `mac trash` - Empty trash
- `mac cache` - Clear system caches
- `mac dns` - Flush DNS cache

## Development Guidelines

### Code Style
- **Language**: Bash shell scripts
- **Formatting**: Use consistent indentation (4 spaces)
- **Colors**: Use ANSI color codes for terminal output (already defined in main script)
- **Error Handling**: Always check command existence before execution
- **User Prompts**: Use confirmation prompts for destructive operations

### Testing Requirements
- No formal test suite currently exists
- Test commands manually before committing
- Verify scripts work on macOS 10.15+
- Check for command availability (brew, mas, npm, etc.) before using

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
- Current version: 1.0.2
- Version defined in main `mac` script
- Update version when making significant changes

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

## Notes for AI Assistants
- This is a system administration tool - focus on safety and reliability
- Always preserve existing functionality when making changes
- Test commands in isolation before integrating
- Consider edge cases (missing dependencies, different macOS versions)
- Maintain backward compatibility where possible
- Keep user experience consistent with existing commands