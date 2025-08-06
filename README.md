# Mac Power Tools

A powerful and comprehensive macOS system management CLI tool. Modern replacement for the deprecated mac-cli with enhanced functionality for system updates, monitoring, and maintenance. **Now includes free, open-source alternatives to CleanMyMac features!**

## Features

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

### 🎯 CleanMyMac Alternative Features (NEW!)
- **App Uninstaller**: Completely remove applications and all associated files
- **Duplicate Finder**: Find and remove duplicate files to free up space
- **System Junk Cleaner**: Deep clean Xcode, package manager caches, iOS backups
- **Memory Optimizer**: Monitor and optimize RAM usage in real-time

### 💾 Power Management
- **Keep Awake**: Prevent Mac from sleeping with screensaver option
- Sleep, restart, and shutdown commands
- Close all applications at once
- Safe operation with confirmation prompts

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

# Power management
mac awake           # Keep Mac awake indefinitely
mac awake --screensaver  # Keep awake with screensaver
mac awake -t 2h     # Keep awake for 2 hours
mac awake --stop    # Stop keeping Mac awake
mac sleep           # Put Mac to sleep
mac restart         # Restart Mac
mac shutdown        # Shutdown Mac
```

### Examples

```bash
# Morning routine - update everything
mac update

# Check system performance
mac info memory
mac info cpu

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
│   └── mac-awake.sh       # Keep awake/caffeinate (NEW)
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

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

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