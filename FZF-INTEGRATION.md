# Mac Power Tools - fzf Integration

Enhanced interactive command selection with fuzzy finding powered by [fzf](https://github.com/junegunn/fzf).

## 🚀 Features

### ✨ Interactive Command Selection
- **Fuzzy search** through all available commands
- **Real-time preview** of command descriptions
- **Smart filtering** - type to narrow down options
- **Keyboard navigation** with arrow keys
- **Multi-selection** for certain commands (like uninstall)

### 🎯 Auto-Detection
Mac Power Tools automatically uses fzf when:
- fzf is installed (`brew install fzf`)
- No specific arguments are provided
- Terminal supports interactive input

### 🔍 Enhanced Commands

#### Interactive Command Menu
```bash
mac menu              # Browse all commands with fzf
mac fzf               # Same as 'mac menu'
```

#### Smart Command Enhancement
```bash
# These commands auto-launch fzf when no arguments provided:
mac update            # → Interactive update target selection  
mac info              # → Interactive info type selection
mac uninstall         # → Interactive app selection with multi-select
mac privacy           # → Interactive privacy/security actions
mac downloads         # → Interactive downloads management
mac duplicates        # → Interactive directory selection
```

## 📋 Installation

### Install fzf
```bash
# Via Homebrew (recommended)
brew install fzf

# Set up key bindings and completion (optional)
$(brew --prefix)/opt/fzf/install
```

### Verify Installation
```bash
mac menu              # Should show interactive command selection
fzf --version         # Should show fzf version
```

## 🎮 Usage Examples

### Main Command Menu
```bash
mac menu
```
- Browse all commands with descriptions
- Type to filter (e.g., type "clean" to see cleaning commands)
- Use ↑↓ arrows to navigate
- Press Enter to execute
- Press Esc to cancel

### Update Target Selection
```bash
mac update
```
- Choose what to update: macOS, Homebrew, MAS, npm, etc.
- Preview shows description of each option
- Much faster than remembering command syntax

### Interactive App Uninstaller
```bash
mac uninstall
```
- Lists all installed applications
- Use TAB for multi-select
- Preview shows application details
- Confirm before uninstalling

### Privacy & Security Actions
```bash
mac privacy
```
- Choose from audit, scan, clean options
- Target-specific cleaning (Safari, Chrome, etc.)
- One-command security protection

### Downloads Management
```bash
mac downloads
```
- Sort, analyze, clean, or setup automation
- Real-time folder monitoring
- Interactive cleanup with date selection

### Directory Selection for Duplicates
```bash
mac duplicates
```
- Choose common directories or enter custom path
- Smart suggestions (Downloads, Documents, etc.)
- Preview shows directory descriptions

## ⚙️ Configuration

### fzf Options
Mac Power Tools uses optimized fzf settings:
- `--height=20` - Compact display
- `--layout=reverse` - Results at top
- `--border` - Clean visual separation
- `--preview` - Command descriptions
- `--color` - Syntax highlighting

### Customization
You can customize fzf behavior by setting environment variables:

```bash
# Add to ~/.zshrc or ~/.bashrc
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --preview-window=up:3:wrap"

# Custom colors
export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS --color=header:italic:blue,prompt:green,pointer:red"
```

## 🎨 Interface Features

### Visual Elements
- **🔍 Icons** - Clear visual indicators
- **Color coding** - Commands grouped by type
- **Preview pane** - Shows command descriptions
- **Progress indicators** - For long-running operations
- **Error handling** - Graceful fallback when fzf unavailable

### Keyboard Shortcuts
- **↑↓** - Navigate options
- **Tab** - Multi-select (where supported)
- **Enter** - Execute selection
- **Esc/Ctrl+C** - Cancel
- **Type** - Filter/search options

## 🔄 Fallback Behavior

When fzf is not available:
- Commands work exactly as before
- Helpful message suggests installing fzf
- Full functionality maintained
- No breaking changes

```bash
# Without fzf
mac update brew       # Works normally

# With fzf installed
mac update           # Shows interactive menu
mac update brew      # Still works directly
```

## 🛠️ Advanced Usage

### Command Chaining
```bash
# Use fzf to select, then run additional commands
mac menu && mac info memory
```

### Scripting Integration
```bash
# Skip fzf in scripts by providing arguments
mac update brew       # Direct command, no fzf
mac update           # Interactive only in terminal
```

### Performance
- **Fast loading** - Commands cached for speed
- **Efficient search** - fzf handles thousands of items
- **Low memory** - Minimal overhead
- **Responsive** - Real-time filtering

## 🐛 Troubleshooting

### fzf Not Found
```bash
# Install fzf
brew install fzf

# Verify installation
which fzf
fzf --version
```

### Interactive Menu Not Showing
```bash
# Check if running in interactive terminal
echo $-                # Should include 'i'

# Test fzf directly
echo -e "test1\ntest2" | fzf
```

### Performance Issues
```bash
# Check if fzf is up to date
brew upgrade fzf

# Reset fzf cache
unset FZF_DEFAULT_OPTS
```

### Command Not Working
```bash
# Test with verbose output
mac menu 2>&1 | head -10

# Check script permissions
ls -la scripts/mac-fzf.sh
```

## 🎓 Tips & Tricks

### Productivity Tips
1. **Type to filter** - Don't scroll, just type part of command name
2. **Use Tab** for multi-select in app uninstaller
3. **Bookmark common commands** - `mac update`, `mac uninstall`
4. **Preview pane** - Read descriptions before selecting

### Efficiency Shortcuts
```bash
mac menu              # Fastest way to discover commands
mac u<TAB>           # Tab completion still works
mac update<Enter>    # Quick access to update menu
```

### Customization Ideas
```bash
# Alias for super quick access
alias m='mac menu'
alias mu='mac update'
alias mi='mac info'
alias mu='mac uninstall'
```

## 🔗 Integration with Other Tools

### Works With
- **Tab completion** - Both systems work together
- **Shell history** - Commands saved normally
- **Aliases** - Create shortcuts to fzf commands
- **Scripts** - Conditional fzf usage

### Complements
- **Homebrew** - Enhanced package management
- **mas-cli** - Mac App Store integration
- **terminal-notifier** - Desktop notifications

---

fzf integration makes Mac Power Tools incredibly fast and discoverable. Try `mac menu` to explore all available commands interactively! 🚀