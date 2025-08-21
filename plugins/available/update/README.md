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
