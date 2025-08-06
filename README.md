# Mac Power Tools

A powerful and comprehensive macOS system management CLI tool. Modern replacement for the deprecated mac-cli with enhanced functionality for system updates, monitoring, and maintenance.

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

### 💾 Power Management
- Sleep, restart, and shutdown commands
- Close all applications at once
- Safe operation with confirmation prompts

## Installation

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
mac trash           # Empty trash
mac cache           # Clear caches
mac large-files     # Find files >100MB
mac dns             # Flush DNS cache
mac hidden          # Toggle hidden files

# Power management
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

# Clean up disk space
mac trash
mac cache
mac large-files

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
│   └── mac-maintenance.sh # Maintenance utilities
├── install.sh             # Installation script
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

### v1.0.0 (2025-08-06)
- Initial release
- Complete replacement for mac-cli
- System update utilities
- System information tools
- Maintenance utilities
- Power management commands

---

**Made with ❤️ for macOS power users**