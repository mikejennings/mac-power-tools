# Mac Power Tools - Tab Completion

Tab completion makes using Mac Power Tools much faster and more convenient. Just type `mac ` and press `<TAB>` to see available commands and options.

## Features

### ✨ Smart Command Completion
- **Main commands**: `mac <TAB>` shows all available commands
- **Subcommands**: `mac downloads <TAB>` shows downloads-specific options
- **Options**: `mac awake <TAB>` shows awake command options
- **Applications**: `mac uninstall <TAB>` lists installed applications
- **Directories**: `mac duplicates <TAB>` completes directory paths

### 🔧 Supported Commands

#### Core Commands
```bash
mac <TAB>
# Shows: help, version, update, info, maintenance, clean, etc.
```

#### Update Command
```bash
mac update <TAB>
# Shows: macos, brew, mas, npm, ruby, pip
```

#### Info Command  
```bash
mac info <TAB>
# Shows: system, memory, disk, network, battery, temp, cpu
```

#### Downloads Management
```bash
mac downloads <TAB>
# Shows: sort, setup, status, watch, analyze, clean, disable
```

#### Privacy & Security
```bash
mac privacy <TAB>
# Shows: clean, audit, scan, permissions, protect

mac privacy clean <TAB>  
# Shows: safari, chrome, firefox, system, all

mac security <TAB>
# Shows: audit, scan, protect
```

#### Application Management
```bash
mac uninstall <TAB>
# Shows: --list, --dry-run, and all installed applications

mac uninstall Google<TAB>
# Completes to "Google Chrome" (if installed)
```

#### Power Management
```bash
mac awake <TAB>
# Shows: --screensaver, --status, --stop, -t, --time, -w, --wait-for
```

#### Memory Management
```bash
mac memory <TAB>
# Shows: --optimize, --status, --help
```

## Installation

### Automatic Installation (Recommended)

**Via Homebrew**: Tab completion is automatically installed with Mac Power Tools.

**Manual Installation**: Run the installer and choose "Yes" when asked about tab completion.

### Manual Installation

```bash
# From the Mac Power Tools directory
./install-completions.sh

# Or install to specific location
cp completions/_mac /opt/homebrew/share/zsh/site-functions/  # zsh
cp completions/mac-completion.bash /opt/homebrew/etc/bash_completion.d/mac  # bash
```

## Shell Support

### Zsh (Default on macOS)
- ✅ Full support with intelligent context-aware completion
- ✅ Application name completion for `uninstall` command
- ✅ Directory path completion for file operations
- ✅ Option flag completion with descriptions

### Bash
- ✅ Command and subcommand completion
- ✅ Application name completion  
- ✅ Basic option completion
- ⚠️ Requires `bash-completion` package

## Activation

### Zsh
Tab completion is automatically active after installation. If needed:
```bash
# Reload completions
compinit

# Or restart terminal
```

### Bash  
```bash
# Install bash-completion if not installed
brew install bash-completion

# Add to .bashrc if needed
echo 'source $(brew --prefix)/etc/profile.d/bash_completion.sh' >> ~/.bashrc

# Reload
source ~/.bashrc
```

## Examples

### Quick Command Discovery
```bash
mac <TAB><TAB>
# Shows all available commands with descriptions
```

### Context-Aware Completion
```bash
mac privacy clean <TAB>
# safari  chrome  firefox  system  all

mac awake --<TAB>  
# --screensaver  --status  --stop  --time  --wait-for
```

### Application Management
```bash
mac uninstall <TAB>
# Lists all installed applications from /Applications

mac uninstall Goo<TAB>
# Expands to "Google Chrome" or "Google Drive" etc.
```

### File Operations
```bash
mac duplicates ~/Doc<TAB>
# Expands to ~/Documents/

mac downloads clean <TAB>
# Allows entering number of days
```

## Troubleshooting

### Tab Completion Not Working

1. **Check if installed**:
   ```bash
   # Zsh
   ls /opt/homebrew/share/zsh/site-functions/_mac
   
   # Bash
   ls /opt/homebrew/etc/bash_completion.d/mac
   ```

2. **Reload completions**:
   ```bash
   # Zsh
   compinit
   
   # Bash  
   source ~/.bashrc
   ```

3. **Reinstall**:
   ```bash
   ./install-completions.sh
   ```

### Zsh Completion Issues
```bash
# Check if completion system is enabled
echo $fpath | grep -o '/[^:]*completion[^:]*'

# Force rebuild completion cache
rm ~/.zcompdump && compinit
```

### Bash Completion Issues
```bash
# Install bash-completion
brew install bash-completion

# Check if bash-completion is loaded
complete -p | grep mac
```

## Advanced Usage

### Custom Completion Directories
```bash
# Add custom completion directory to zsh
echo 'fpath=(~/.zsh/completions $fpath)' >> ~/.zshrc
mkdir -p ~/.zsh/completions
cp completions/_mac ~/.zsh/completions/
```

### Completion Performance
The completion system is optimized for speed:
- Command lists are cached
- Application scanning is done on-demand
- File operations use native shell completion

## Contributing

To add new completions:

1. **Edit `completions/_mac`** for zsh completion
2. **Edit `completions/mac-completion.bash`** for bash completion  
3. **Test with**: `mac command <TAB>`
4. **Submit PR** with new completion features

### Completion Format

**Zsh**: Uses `_describe` function with command:description pairs
**Bash**: Uses `compgen -W` with space-separated word lists

---

Tab completion makes Mac Power Tools much more efficient to use. Try `mac <TAB>` to explore all the available commands!