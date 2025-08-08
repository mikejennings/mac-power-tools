#!/bin/bash

# Mac Power Tools - Dotfiles & Preferences Sync
# Simple, elegant iCloud-based dotfiles management

set -euo pipefail

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Don't source the main script to avoid conflicts

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# iCloud Drive path
ICLOUD_PATH="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
DOTFILES_DIR="$ICLOUD_PATH/Dotfiles"
PREFS_DIR="$ICLOUD_PATH/AppPreferences"

# Common dotfiles to track
DEFAULT_DOTFILES=(
    ".bashrc"
    ".bash_profile"
    ".zshrc"
    ".zprofile"
    ".gitconfig"
    ".gitignore_global"
    ".vimrc"
    ".tmux.conf"
    ".ssh/config"
    ".aws/config"
    ".aws/credentials"
)

# Extended dotfiles for developer tools
DEVELOPER_CONFIGS=(
    ".config/nvim"
    ".config/gh"
    ".config/raycast"
    ".config/zed"
    ".config/fish"
    ".hammerspoon"
    ".docker/config.json"
    ".kube/config"
    ".npmrc"
    ".yarnrc"
)

# Common application preferences
APP_PREFS=(
    "com.apple.Terminal.plist"
    "com.googlecode.iterm2.plist"
    "com.microsoft.VSCode.plist"
    "com.sublimetext.4.plist"
    "com.github.atom.plist"
    "com.knollsoft.Rectangle.plist"
    "net.matthewpalmer.Rectangle-Pro.plist"
    "com.raycast.macos.plist"
)

# Check if iCloud is available
check_icloud() {
    if [[ ! -d "$ICLOUD_PATH" ]]; then
        printf "${RED}Error: iCloud Drive not found${NC}\n"
        printf "Please ensure iCloud Drive is enabled in System Preferences\n"
        return 1
    fi
    return 0
}

# Initialize dotfiles directory
init_dotfiles() {
    check_icloud || return 1
    
    local show_header=true
    # Don't show header if called from backup_all or other functions
    if [[ "${1:-}" == "--quiet" ]]; then
        show_header=false
    fi
    
    if $show_header; then
        printf "${CYAN}=== Initializing Dotfiles Sync ===${NC}\n\n"
    fi
    
    # Create directories if they don't exist
    local created_new=false
    if [[ ! -d "$DOTFILES_DIR" ]]; then
        mkdir -p "$DOTFILES_DIR"
        if $show_header; then
            printf "${GREEN}✓ Created dotfiles directory in iCloud${NC}\n"
        fi
        created_new=true
    fi
    
    if [[ ! -d "$PREFS_DIR" ]]; then
        mkdir -p "$PREFS_DIR"
        if $show_header; then
            printf "${GREEN}✓ Created preferences directory in iCloud${NC}\n"
        fi
        created_new=true
    fi
    
    # Create subdirectories for nested configs
    mkdir -p "$DOTFILES_DIR/.ssh"
    mkdir -p "$DOTFILES_DIR/.aws"
    mkdir -p "$DOTFILES_DIR/.config"
    
    if $show_header && $created_new; then
        printf "${GREEN}✓ Dotfiles sync initialized${NC}\n"
        printf "  Dotfiles: $DOTFILES_DIR\n"
        printf "  Preferences: $PREFS_DIR\n"
    fi
}

# Backup a single dotfile
backup_dotfile() {
    local file="$1"
    local source="$HOME/$file"
    local backup="$DOTFILES_DIR/$file"
    
    # Skip if source doesn't exist
    if [[ ! -e "$source" ]]; then
        return 1
    fi
    
    # Create parent directory if needed
    local backup_dir=$(dirname "$backup")
    mkdir -p "$backup_dir"
    
    # If it's already a symlink pointing to our backup, skip
    if [[ -L "$source" ]] && [[ "$(readlink "$source")" == "$backup" ]]; then
        printf "${BLUE}✓ $file (already linked)${NC}\n"
        return 0
    fi
    
    # If backup exists and is not the same, prompt
    if [[ -e "$backup" ]] && [[ ! -L "$source" ]]; then
        if ! diff -q "$source" "$backup" > /dev/null 2>&1; then
            printf "${YELLOW}Conflict for $file. Keep (l)ocal, (i)Cloud, or (s)kip?${NC} "
            read -r choice
            case "$choice" in
                l|L)
                    cp -f "$source" "$backup"
                    ;;
                i|I)
                    # Will be handled below
                    ;;
                s|S)
                    return 0
                    ;;
                *)
                    return 0
                    ;;
            esac
        fi
    fi
    
    # Move file to iCloud if it's not there yet
    if [[ ! -L "$source" ]]; then
        if [[ -e "$source" ]]; then
            cp -a "$source" "$backup"
            rm -rf "$source"
        fi
    fi
    
    # Create symlink
    ln -sf "$backup" "$source"
    printf "${GREEN}✓ $file${NC}\n"
    return 0
}

# Backup all dotfiles
backup_all() {
    check_icloud || return 1
    init_dotfiles --quiet
    
    printf "${CYAN}=== Backing Up Dotfiles ===${NC}\n\n"
    
    local backed_up=0
    
    # Backup default dotfiles
    for file in "${DEFAULT_DOTFILES[@]}"; do
        if backup_dotfile "$file"; then
            ((backed_up++))
        fi
    done
    
    # Look for other common dotfiles
    while IFS= read -r file; do
        local basename="${file#$HOME/}"
        # Skip if already in our list or if it's our symlink
        if [[ ! " ${DEFAULT_DOTFILES[@]} " =~ " ${basename} " ]] && [[ ! -L "$file" ]]; then
            printf "${YELLOW}Found: $basename - Back up? (y/n)${NC} "
            read -r response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                if backup_dotfile "$basename"; then
                    ((backed_up++))
                fi
            fi
        fi
    done < <(find "$HOME" -maxdepth 1 -name ".*" -type f 2>/dev/null)
    
    printf "\n${GREEN}✓ Backed up $backed_up dotfiles${NC}\n"
    printf "${BLUE}Location: $DOTFILES_DIR${NC}\n"
}

# Restore dotfiles
restore_all() {
    check_icloud || return 1
    
    if [[ ! -d "$DOTFILES_DIR" ]]; then
        printf "${RED}Error: No dotfiles backup found in iCloud${NC}\n"
        return 1
    fi
    
    printf "${CYAN}=== Restoring Dotfiles ===${NC}\n\n"
    
    local restored=0
    
    # Find all files in the backup directory
    while IFS= read -r backup_file; do
        local relative_path="${backup_file#$DOTFILES_DIR/}"
        local target="$HOME/$relative_path"
        
        # Skip if it's already a correct symlink
        if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$backup_file" ]]; then
            printf "${BLUE}✓ $relative_path (already linked)${NC}\n"
            ((restored++))
            continue
        fi
        
        # Handle existing files
        if [[ -e "$target" ]] && [[ ! -L "$target" ]]; then
            printf "${YELLOW}$relative_path exists. Overwrite? (y/n)${NC} "
            read -r response
            if [[ ! "$response" =~ ^[Yy]$ ]]; then
                continue
            fi
            rm -rf "$target"
        fi
        
        # Create parent directory if needed
        local target_dir=$(dirname "$target")
        mkdir -p "$target_dir"
        
        # Create symlink
        ln -sf "$backup_file" "$target"
        printf "${GREEN}✓ $relative_path${NC}\n"
        ((restored++))
    done < <(find "$DOTFILES_DIR" -type f 2>/dev/null)
    
    printf "\n${GREEN}✓ Restored $restored dotfiles from iCloud${NC}\n"
}

# Backup application preferences
backup_preferences() {
    check_icloud || return 1
    init_dotfiles --quiet
    
    printf "${CYAN}=== Backing Up Application Preferences ===${NC}\n\n"
    
    local prefs_source="$HOME/Library/Preferences"
    local backed_up=0
    
    for pref in "${APP_PREFS[@]}"; do
        local source="$prefs_source/$pref"
        local backup="$PREFS_DIR/$pref"
        
        if [[ -f "$source" ]]; then
            cp -a "$source" "$backup"
            printf "${GREEN}✓ $pref${NC}\n"
            ((backed_up++))
        fi
    done
    
    # VS Code settings
    local vscode_dir="$HOME/Library/Application Support/Code/User"
    if [[ -d "$vscode_dir" ]]; then
        local vscode_backup="$PREFS_DIR/VSCode"
        mkdir -p "$vscode_backup"
        
        for file in settings.json keybindings.json snippets; do
            if [[ -e "$vscode_dir/$file" ]]; then
                cp -a "$vscode_dir/$file" "$vscode_backup/"
                printf "${GREEN}✓ VS Code $file${NC}\n"
                ((backed_up++))
            fi
        done
    fi
    
    printf "\n${GREEN}✓ Backed up $backed_up preference files${NC}\n"
    printf "${BLUE}Location: $PREFS_DIR${NC}\n"
}

# List tracked files
list_tracked() {
    check_icloud || return 1
    
    printf "${CYAN}=== Tracked Dotfiles ===${NC}\n\n"
    
    if [[ -d "$DOTFILES_DIR" ]]; then
        printf "${YELLOW}Dotfiles in iCloud:${NC}\n"
        find "$DOTFILES_DIR" -type f -exec basename {} \; | sort | sed 's/^/  /'
    else
        printf "${YELLOW}No dotfiles backed up yet${NC}\n"
    fi
    
    printf "\n${YELLOW}Symlinked files:${NC}\n"
    local count=0
    while IFS= read -r link; do
        if [[ "$(readlink "$link" 2>/dev/null)" =~ $DOTFILES_DIR ]]; then
            printf "  ${link#$HOME/}\n"
            ((count++))
        fi
    done < <(find "$HOME" -maxdepth 3 -type l 2>/dev/null)
    
    [[ $count -eq 0 ]] && printf "  None\n"
}

# Backup developer configs
backup_dev_configs() {
    check_icloud || return 1
    init_dotfiles --quiet
    
    printf "${CYAN}=== Backing Up Developer Configs ===${NC}\n\n"
    
    local backed_up=0
    
    for config in "${DEVELOPER_CONFIGS[@]}"; do
        local source="$HOME/$config"
        
        # Check if the config exists
        if [[ -e "$source" ]]; then
            printf "${YELLOW}Found $config - Back up? (y/n)${NC} "
            read -r response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                if backup_dotfile "$config"; then
                    ((backed_up++))
                fi
            fi
        fi
    done
    
    printf "\n${GREEN}✓ Backed up $backed_up developer configs${NC}\n"
}

# Add a new dotfile to track
add_dotfile() {
    local file="${1:-}"
    
    if [[ -z "$file" ]]; then
        printf "${YELLOW}Enter path to dotfile (relative to home):${NC} "
        read -r file
    fi
    
    # Remove leading slash or ~/
    file="${file#/}"
    file="${file#~/}"
    
    if backup_dotfile "$file"; then
        printf "${GREEN}✓ Added $file to dotfiles sync${NC}\n"
    else
        printf "${RED}Failed to add $file${NC}\n"
    fi
}

# Remove a dotfile from tracking
remove_dotfile() {
    local file="${1:-}"
    
    if [[ -z "$file" ]]; then
        printf "${YELLOW}Enter dotfile to remove (relative to home):${NC} "
        read -r file
    fi
    
    file="${file#/}"
    file="${file#~/}"
    
    local source="$HOME/$file"
    local backup="$DOTFILES_DIR/$file"
    
    if [[ -L "$source" ]] && [[ "$(readlink "$source")" == "$backup" ]]; then
        # Copy the file back
        rm "$source"
        cp -a "$backup" "$source"
        printf "${GREEN}✓ Removed $file from sync (file kept locally)${NC}\n"
    else
        printf "${YELLOW}$file is not currently synced${NC}\n"
    fi
}

# Interactive menu
interactive_menu() {
    if command -v fzf &> /dev/null; then
        local options=(
            "backup:Backup all dotfiles to iCloud"
            "restore:Restore dotfiles from iCloud"
            "add:Add a specific dotfile"
            "remove:Stop syncing a dotfile"
            "list:List tracked dotfiles"
            "prefs:Backup application preferences"
            "init:Initialize dotfiles directories"
        )
        
        local choice=$(printf '%s\n' "${options[@]}" | \
            fzf --height=40% \
                --border \
                --prompt="Select dotfiles operation > " \
                --header="Dotfiles Manager (Esc to exit)" \
                --preview='echo {}' \
                --preview-window=right:50%:wrap)
        
        [[ -z "$choice" ]] && return
        
        local action="${choice%%:*}"
        case "$action" in
            backup) backup_all ;;
            restore) restore_all ;;
            add) add_dotfile ;;
            remove) remove_dotfile ;;
            list) list_tracked ;;
            prefs) backup_preferences ;;
            init) init_dotfiles ;;
        esac
    else
        show_help
    fi
}

# Show help
show_help() {
    echo -e "${CYAN}Mac Dotfiles - Simple iCloud Sync${NC}\n"
    
    echo -e "${YELLOW}Usage:${NC}"
    echo "  mac dotfiles                  Interactive menu (requires fzf)"
    echo -e "  mac dotfiles <command>        Run specific command\n"
    
    echo -e "${YELLOW}Commands:${NC}"
    echo "  init                          Initialize dotfiles directories"
    echo "  backup                        Backup all dotfiles to iCloud"
    echo "  restore                       Restore dotfiles from iCloud"
    echo "  add <file>                    Add a specific dotfile"
    echo "  remove <file>                 Stop syncing a dotfile"
    echo "  list                          List tracked dotfiles"
    echo "  prefs                         Backup application preferences"
    echo "  dev                           Backup developer tool configs"
    echo -e "  help                          Show this help message\n"
    
    echo -e "${YELLOW}Examples:${NC}"
    echo "  mac dotfiles                  # Interactive menu"
    echo "  mac dotfiles init             # First-time setup"
    echo "  mac dotfiles backup           # Backup all dotfiles"
    echo "  mac dotfiles add .bashrc      # Add specific file"
    echo -e "  mac dotfiles restore          # Restore on new machine\n"
    
    echo -e "${YELLOW}How it works:${NC}"
    echo "  1. Copies your dotfiles to iCloud Drive"
    echo "  2. Replaces local files with symlinks"
    echo "  3. Changes sync automatically via iCloud"
    echo -e "  4. Simple, native, no external dependencies\n"
    
    echo -e "${YELLOW}Default tracked files:${NC}"
    echo "  .bashrc, .zshrc, .gitconfig, .vimrc, .tmux.conf"
    echo -e "  .ssh/config, .aws/config, and more\n"
}

# Main function
main() {
    local command="${1:-}"
    
    case "$command" in
        "")
            interactive_menu
            ;;
        init)
            init_dotfiles
            ;;
        backup)
            backup_all
            ;;
        restore)
            restore_all
            ;;
        add)
            add_dotfile "$2"
            ;;
        remove)
            remove_dotfile "$2"
            ;;
        list)
            list_tracked
            ;;
        prefs|preferences)
            backup_preferences
            ;;
        dev|developer)
            backup_dev_configs
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            printf "${RED}Unknown command: $command${NC}\n"
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"