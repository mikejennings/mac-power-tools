# CLAUDE.md - Mac Power Tools Project-Specific Configuration

## 📦 Project Context
Collection of powerful macOS utilities and system tools.

## 🔧 Project-Specific Guidelines

### Development Environment
- **Platform**: macOS only
- **Languages**: Swift, Shell, Python
- **Tools**: May require sudo for system operations

### Development Priorities
1. Always test on current macOS version
2. Handle permissions gracefully (especially for system operations)
3. Provide clear error messages for permission issues
4. Use native macOS APIs when possible

### Security & Permissions
- Request minimal necessary permissions
- Explain why permissions are needed
- Never store credentials in plain text
- Use macOS Keychain for sensitive data

### Common Patterns
- Use `osascript` for AppleScript automation
- Leverage `defaults` for preferences
- Use `launchctl` for services
- Proper handling of system paths with spaces

## 🎯 Testing Guidelines
- Test with both admin and standard user accounts
- Verify compatibility with latest macOS
- Check for Gatekeeper and notarization requirements