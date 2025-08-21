#!/bin/bash

# Mac Power Tools - Dotfiles Application Support
# Modular application configuration management

set -euo pipefail

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Application Registry using parallel arrays (compatible with bash 3.2)
APP_IDS=()
APP_NAMES=()
APP_CATEGORIES=()
APP_DETECTIONS=()
APP_PATHS=()
APP_EXCLUDES=()

# Initialize the application registry
init_app_registry() {
    # Clear arrays
    APP_IDS=()
    APP_NAMES=()
    APP_CATEGORIES=()
    APP_DETECTIONS=()
    APP_PATHS=()
    APP_EXCLUDES=()
    
    # Developer Tools - Priority 1
    register_app "neovim" "Neovim" "developer" \
        "check_dir:~/.config/nvim" \
        ".config/nvim" \
        ".git,node_modules,*.log,.netrwhist"
    
    register_app "vscode" "Visual Studio Code" "developer" \
        "check_dir:~/Library/Application Support/Code" \
        "Library/Application Support/Code/User/settings.json,Library/Application Support/Code/User/keybindings.json,Library/Application Support/Code/User/snippets" \
        "workspaceStorage,globalStorage,Cache,CachedData"
    
    register_app "sublime" "Sublime Text" "developer" \
        "check_dir:~/Library/Application Support/Sublime Text" \
        "Library/Application Support/Sublime Text/Packages/User" \
        "Package Control.cache,*.cache"
    
    register_app "cursor" "Cursor" "developer" \
        "check_dir:~/Library/Application Support/Cursor" \
        "Library/Application Support/Cursor/User/settings.json,Library/Application Support/Cursor/User/keybindings.json" \
        "workspaceStorage,globalStorage,Cache"
    
    register_app "iterm2" "iTerm2" "developer" \
        "check_app:iTerm" \
        "Library/Preferences/com.googlecode.iterm2.plist" \
        ""
    
    register_app "warp" "Warp Terminal" "developer" \
        "check_dir:~/.warp" \
        ".warp" \
        "*.log,*.cache"
    
    register_app "alacritty" "Alacritty" "developer" \
        "check_dir:~/.config/alacritty" \
        ".config/alacritty" \
        ""
    
    register_app "tmux" "tmux" "developer" \
        "check_file:~/.tmux.conf" \
        ".tmux.conf,.tmux" \
        "plugins/*/.*,resurrect"
    
    register_app "oh-my-zsh" "Oh My Zsh" "developer" \
        "check_dir:~/.oh-my-zsh" \
        ".oh-my-zsh/custom" \
        "*.zwc"
    
    # Productivity Tools - Priority 2
    register_app "raycast" "Raycast" "productivity" \
        "check_app:Raycast" \
        ".config/raycast,Library/Application Support/com.raycast.macos" \
        "*.log,Cache"
    
    register_app "rectangle" "Rectangle" "productivity" \
        "check_app:Rectangle" \
        "Library/Preferences/com.knollsoft.Rectangle.plist" \
        ""
    
    register_app "rectangle-pro" "Rectangle Pro" "productivity" \
        "check_app:Rectangle Pro" \
        "Library/Preferences/net.matthewpalmer.Rectangle-Pro.plist" \
        ""
    
    register_app "alfred" "Alfred" "productivity" \
        "check_app:Alfred" \
        "Library/Application Support/Alfred,Library/Preferences/com.runningwithcrayons.Alfred-Preferences.plist" \
        "Databases,Knowledge"
    
    register_app "karabiner" "Karabiner-Elements" "productivity" \
        "check_app:Karabiner-Elements" \
        ".config/karabiner" \
        "automatic_backups"
    
    register_app "hammerspoon" "Hammerspoon" "productivity" \
        "check_app:Hammerspoon" \
        ".hammerspoon" \
        "*.log"
    
    # Development Services - Priority 3
    register_app "docker" "Docker Desktop" "services" \
        "check_app:Docker" \
        ".docker/config.json,.docker/daemon.json" \
        "*.tar,*.log,auths"
    
    register_app "kubernetes" "Kubernetes" "services" \
        "check_file:~/.kube/config" \
        ".kube/config" \
        ""
    
    register_app "npm" "npm" "services" \
        "check_cmd:npm" \
        ".npmrc" \
        ""
    
    register_app "yarn" "Yarn" "services" \
        "check_cmd:yarn" \
        ".yarnrc,.yarnrc.yml,.config/yarn" \
        "cache,global/node_modules"
    
    register_app "homebrew" "Homebrew Bundle" "services" \
        "check_file:~/Brewfile" \
        "Brewfile,.config/brewfile/Brewfile" \
        ""
    
    # Security & Privacy Tools - Priority 4
    register_app "1password-cli" "1Password CLI" "security" \
        "check_cmd:op" \
        ".config/op" \
        "*.log,session*"
    
    register_app "gh-cli" "GitHub CLI" "security" \
        "check_cmd:gh" \
        ".config/gh" \
        "hosts.yml"
    
    register_app "ssh" "SSH Config" "security" \
        "check_file:~/.ssh/config" \
        ".ssh/config,.ssh/known_hosts" \
        "id_*,*.pem,*.key,authorized_keys"
    
    register_app "aws-cli" "AWS CLI" "security" \
        "check_dir:~/.aws" \
        ".aws/config" \
        "credentials,cli/cache"
    
    register_app "gpg" "GPG" "security" \
        "check_dir:~/.gnupg" \
        ".gnupg/gpg.conf,.gnupg/gpg-agent.conf" \
        "*.key,*.gpg,private*,secring*,trustdb*,random_seed"
}

# Register an application
register_app() {
    local app_id="$1"
    local display_name="$2"
    local category="$3"
    local detection="$4"
    local paths="$5"
    local excludes="$6"
    
    APP_IDS+=("$app_id")
    APP_NAMES+=("$display_name")
    APP_CATEGORIES+=("$category")
    APP_DETECTIONS+=("$detection")
    APP_PATHS+=("$paths")
    APP_EXCLUDES+=("$excludes")
}

# Get app index by ID
get_app_index() {
    local app_id="$1"
    local i
    for i in "${!APP_IDS[@]}"; do
        if [[ "${APP_IDS[$i]}" == "$app_id" ]]; then
            echo "$i"
            return 0
        fi
    done
    return 1
}

# Check if an application is installed
is_app_installed() {
    local app_id="$1"
    local index=$(get_app_index "$app_id")
    
    if [[ -z "$index" ]]; then
        return 1
    fi
    
    local detection="${APP_DETECTIONS[$index]}"
    local method="${detection%%:*}"
    local target="${detection#*:}"
    
    case "$method" in
        check_app)
            # Check if app exists in /Applications or ~/Applications
            [[ -d "/Applications/${target}.app" ]] || [[ -d "$HOME/Applications/${target}.app" ]]
            ;;
        check_dir)
            # Expand tilde and check if directory exists
            eval "[[ -d \"$target\" ]]"
            ;;
        check_file)
            # Expand tilde and check if file exists
            eval "[[ -f \"$target\" ]]"
            ;;
        check_cmd)
            # Check if command is available
            command -v "$target" &> /dev/null
            ;;
        *)
            return 1
            ;;
    esac
}

# Get all registered app IDs
get_all_app_ids() {
    printf '%s\n' "${APP_IDS[@]}"
}

# Get installed apps
get_installed_apps() {
    local app_id
    for app_id in "${APP_IDS[@]}"; do
        if is_app_installed "$app_id"; then
            echo "$app_id"
        fi
    done
}

# Get app display name
get_app_name() {
    local app_id="$1"
    local index=$(get_app_index "$app_id")
    if [[ -n "$index" ]]; then
        echo "${APP_NAMES[$index]}"
    else
        echo "$app_id"
    fi
}

# Get app category
get_app_category() {
    local app_id="$1"
    local index=$(get_app_index "$app_id")
    if [[ -n "$index" ]]; then
        echo "${APP_CATEGORIES[$index]}"
    else
        echo "unknown"
    fi
}

# Get app paths to backup
get_app_paths() {
    local app_id="$1"
    local index=$(get_app_index "$app_id")
    if [[ -n "$index" ]]; then
        echo "${APP_PATHS[$index]}" | tr ',' '\n'
    fi
}

# Get app exclude patterns
get_app_excludes() {
    local app_id="$1"
    local index=$(get_app_index "$app_id")
    if [[ -n "$index" ]]; then
        echo "${APP_EXCLUDES[$index]}"
    fi
}

# Calculate size of app configs
get_app_config_size() {
    local app_id="$1"
    local total_size=0
    
    while IFS= read -r path; do
        local full_path="$HOME/$path"
        if eval "[[ -e \"$full_path\" ]]"; then
            local size=$(du -sk "$full_path" 2>/dev/null | cut -f1)
            total_size=$((total_size + size))
        fi
    done < <(get_app_paths "$app_id")
    
    echo "$total_size"
}

# Format size for display
format_size() {
    local size_kb="$1"
    if [[ $size_kb -lt 1024 ]]; then
        echo "${size_kb}KB"
    elif [[ $size_kb -lt 1048576 ]]; then
        echo "$((size_kb / 1024))MB"
    else
        echo "$((size_kb / 1048576))GB"
    fi
}

# List all available apps
list_available_apps() {
    printf "${CYAN}=== Available Applications ===${NC}\n\n"
    
    local categories=("developer" "productivity" "services" "security")
    local category
    
    for category in "${categories[@]}"; do
        # Capitalize first letter for display (bash 3.2 compatible)
        local category_display="$(echo "$category" | sed 's/^./\U&/')"
        printf "${YELLOW}${category_display} Tools:${NC}\n"
        
        local i
        for i in "${!APP_IDS[@]}"; do
            local app_id="${APP_IDS[$i]}"
            if [[ "${APP_CATEGORIES[$i]}" == "$category" ]]; then
                local name="${APP_NAMES[$i]}"
                local status="${RED}✗ Not Installed${NC}"
                
                if is_app_installed "$app_id"; then
                    local size=$(get_app_config_size "$app_id")
                    local formatted_size=$(format_size "$size")
                    status="${GREEN}✓ Installed${NC} ($formatted_size)"
                fi
                
                printf "  %-20s - %-25s %b\n" "$app_id" "$name" "$status"
            fi
        done
        echo
    done
}

# List installed apps with backup status
list_installed_apps_status() {
    printf "${CYAN}=== Installed Applications ===${NC}\n\n"
    
    local installed_count=0
    
    local app_id
    for app_id in "${APP_IDS[@]}"; do
        if is_app_installed "$app_id"; then
            local name=$(get_app_name "$app_id")
            local category=$(get_app_category "$app_id")
            local size=$(get_app_config_size "$app_id")
            local formatted_size=$(format_size "$size")
            
            printf "  ${GREEN}✓${NC} %-20s - %-25s [%s] %s\n" \
                "$app_id" "$name" "$category" "$formatted_size"
            ((installed_count++))
        fi
    done
    
    if [[ $installed_count -eq 0 ]]; then
        printf "  No supported applications found\n"
    else
        printf "\n${BLUE}Total: $installed_count applications found${NC}\n"
    fi
}

# Interactive app selection with fzf
select_apps_interactive() {
    if ! command -v fzf &> /dev/null; then
        printf "${RED}Error: fzf is required for interactive selection${NC}\n"
        printf "Install with: brew install fzf\n"
        return 1
    fi
    
    local apps=()
    local app_id
    for app_id in "${APP_IDS[@]}"; do
        if is_app_installed "$app_id"; then
            local name=$(get_app_name "$app_id")
            local category=$(get_app_category "$app_id")
            local size=$(get_app_config_size "$app_id")
            local formatted_size=$(format_size "$size")
            apps+=("$app_id:$name [$category] ($formatted_size)")
        fi
    done
    
    if [[ ${#apps[@]} -eq 0 ]]; then
        printf "${YELLOW}No supported applications found${NC}\n"
        return 1
    fi
    
    printf '%s\n' "${apps[@]}" | \
        fzf --multi \
            --height=60% \
            --border \
            --prompt="Select apps to backup (TAB to select, Enter to confirm) > " \
            --header="Available Applications (Esc to cancel)" \
            --preview='echo "Press TAB to select multiple apps"' | \
        cut -d: -f1
}

# Main function
main() {
    local command="${1:-}"
    
    # Initialize the registry
    init_app_registry
    
    case "$command" in
        list)
            list_available_apps
            ;;
        status)
            list_installed_apps_status
            ;;
        installed)
            get_installed_apps
            ;;
        select)
            select_apps_interactive
            ;;
        info)
            local app_id="${2:-}"
            if [[ -z "$app_id" ]]; then
                printf "${RED}Error: App ID required${NC}\n"
                exit 1
            fi
            printf "Name: %s\n" "$(get_app_name "$app_id")"
            printf "Category: %s\n" "$(get_app_category "$app_id")"
            printf "Installed: %s\n" "$(is_app_installed "$app_id" && echo "Yes" || echo "No")"
            printf "Config Size: %s\n" "$(format_size "$(get_app_config_size "$app_id")")"
            printf "Paths:\n"
            get_app_paths "$app_id" | sed 's/^/  - /'
            ;;
        *)
            # Return app info for use by other scripts
            if [[ -n "$command" ]]; then
                # Check if it's a valid app ID
                local index=$(get_app_index "$command")
                if [[ -n "$index" ]]; then
                    is_app_installed "$command"
                    exit $?
                fi
            fi
            printf "${RED}Unknown command: $command${NC}\n"
            printf "Usage: mac-dotfiles-apps.sh [list|status|installed|select|info <app>]\n"
            exit 1
            ;;
    esac
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi