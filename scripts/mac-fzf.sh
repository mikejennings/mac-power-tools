#!/bin/bash

# Mac Power Tools - fzf Integration
# Enhanced interactive command selection with fuzzy finder

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    local color=$1
    shift
    printf "${color}%s${NC}\n" "$*"
}

# Check if fzf is available
check_fzf() {
    if ! command -v fzf &> /dev/null; then
        print_color "$YELLOW" "fzf not found. Install with: brew install fzf"
        return 1
    fi
    return 0
}

# Enhanced command selection with fzf
fzf_command_menu() {
    local commands=(
        "help:Show help message and usage information"
        "version:Show version and system information"
        "update:Update system packages (macOS, Homebrew, MAS, etc.)"
        "info:Display comprehensive system information"
        "maintenance:Interactive system maintenance menu"
        "clean:Deep clean system junk and caches"
        "trash:Empty trash and recover disk space"
        "cache:Clear system and application caches"
        "downloads:Smart downloads folder management"
        "duplicates:Find and remove duplicate files"
        "large-files:Find files larger than 100MB"
        "large-dirs:Find largest directories"
        "logs:Clean old system log files"
        "dns:Flush DNS cache and reset network"
        "spotlight:Rebuild Spotlight search index"
        "hidden:Toggle hidden files visibility in Finder"
        "permissions:Repair disk permissions"
        "memory:Monitor and optimize RAM usage"
        "privacy:Privacy protection and data cleaning"
        "security:Security audit and hardening"
        "awake:Keep Mac awake with optional screensaver"
        "sleep:Put Mac to sleep immediately"
        "restart:Restart Mac with confirmation"
        "shutdown:Shutdown Mac with confirmation"
        "kill-apps:Close all running applications"
        "uninstall:Completely remove applications"
        "migrate-mas:Migrate Mac App Store apps to Homebrew"
    )
    
    print_color "$BLUE" "🔍 Mac Power Tools - Interactive Command Selection"
    echo
    
    local selected=$(printf '%s\n' "${commands[@]}" | fzf \
        --height=20 \
        --layout=reverse \
        --border \
        --prompt="Select command: " \
        --preview='echo {} | cut -d: -f2 | sed "s/^ *//"' \
        --preview-window=up:3:wrap \
        --header="Use ↑↓ arrows, type to search, Enter to select, Esc to cancel" \
        --color="header:italic:blue,prompt:green,pointer:red")
    
    if [[ -n "$selected" ]]; then
        local cmd=$(echo "$selected" | cut -d: -f1)
        echo
        print_color "$GREEN" "Executing: mac $cmd"
        echo
        exec mac "$cmd"
    else
        print_color "$YELLOW" "No command selected"
        exit 0
    fi
}

# fzf-enhanced update target selection
fzf_update_menu() {
    local targets=(
        "all:Update everything (recommended)"
        "macos:Check for macOS system updates"
        "brew:Update Homebrew packages"
        "mas:Update Mac App Store applications"
        "npm:Update Node.js packages globally"
        "ruby:Update Ruby gems"
        "pip:Update Python packages"
    )
    
    print_color "$BLUE" "📦 Select Update Target"
    echo
    
    local selected=$(printf '%s\n' "${targets[@]}" | fzf \
        --height=15 \
        --layout=reverse \
        --border \
        --prompt="Update target: " \
        --preview='echo {} | cut -d: -f2 | sed "s/^ *//"' \
        --preview-window=up:2:wrap \
        --header="Choose what to update" \
        --color="header:italic:blue,prompt:green")
    
    if [[ -n "$selected" ]]; then
        local target=$(echo "$selected" | cut -d: -f1)
        echo
        print_color "$GREEN" "Updating: $target"
        echo
        if [[ "$target" == "all" ]]; then
            exec mac update
        else
            exec mac update "$target"
        fi
    fi
}

# fzf-enhanced info selection
fzf_info_menu() {
    local info_types=(
        "all:Show all system information (recommended)"
        "system:Basic system overview"
        "memory:RAM usage and memory pressure"
        "disk:Storage usage and available space"
        "network:Network interfaces and connectivity"
        "battery:Battery health and power status"
        "temp:CPU temperature monitoring"
        "cpu:Processor information and usage"
    )
    
    print_color "$BLUE" "ℹ️  Select Information Type"
    echo
    
    local selected=$(printf '%s\n' "${info_types[@]}" | fzf \
        --height=15 \
        --layout=reverse \
        --border \
        --prompt="Info type: " \
        --preview='echo {} | cut -d: -f2 | sed "s/^ *//"' \
        --preview-window=up:2:wrap \
        --header="Choose information to display" \
        --color="header:italic:blue,prompt:green")
    
    if [[ -n "$selected" ]]; then
        local info_type=$(echo "$selected" | cut -d: -f1)
        echo
        print_color "$GREEN" "Showing: $info_type information"
        echo
        if [[ "$info_type" == "all" ]]; then
            exec mac info
        else
            exec mac info "$info_type"
        fi
    fi
}

# fzf-enhanced application uninstaller
fzf_uninstall_menu() {
    print_color "$BLUE" "🗑️  Application Uninstaller"
    print_color "$YELLOW" "Scanning installed applications..."
    
    # Get installed applications
    local apps=()
    while IFS= read -r app; do
        [[ -n "$app" ]] && apps+=("$app")
    done < <(find /Applications -name "*.app" -maxdepth 1 -exec basename {} .app \; 2>/dev/null | sort)
    
    if [[ ${#apps[@]} -eq 0 ]]; then
        print_color "$RED" "No applications found in /Applications"
        exit 1
    fi
    
    echo
    print_color "$CYAN" "Found ${#apps[@]} applications"
    echo
    
    local selected=$(printf '%s\n' "${apps[@]}" | fzf \
        --height=20 \
        --layout=reverse \
        --border \
        --multi \
        --prompt="Select app(s) to uninstall: " \
        --preview='ls -la "/Applications/{}.app" 2>/dev/null || echo "Application: {}"' \
        --preview-window=up:5:wrap \
        --header="TAB to select multiple, Enter to confirm, Esc to cancel" \
        --color="header:italic:blue,prompt:red")
    
    if [[ -n "$selected" ]]; then
        echo
        print_color "$YELLOW" "Selected applications:"
        echo "$selected" | while read -r app; do
            echo "  • $app"
        done
        
        echo
        read -p "Are you sure you want to uninstall these applications? (y/N): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "$selected" | while read -r app; do
                print_color "$GREEN" "Uninstalling: $app"
                mac uninstall "$app"
            done
        else
            print_color "$YELLOW" "Uninstall cancelled"
        fi
    fi
}

# fzf-enhanced privacy cleaner
fzf_privacy_menu() {
    local privacy_options=(
        "audit:Comprehensive security audit"
        "scan:Scan for exposed secrets and credentials"
        "clean-all:Clean all browser and system data"
        "clean-safari:Clean Safari data only"
        "clean-chrome:Clean Chrome data only"
        "clean-firefox:Clean Firefox data only"
        "clean-system:Clean system privacy data"
        "permissions:Review app permissions"
        "protect:Enable privacy protection settings"
    )
    
    print_color "$BLUE" "🔒 Privacy & Security Tools"
    echo
    
    local selected=$(printf '%s\n' "${privacy_options[@]}" | fzf \
        --height=15 \
        --layout=reverse \
        --border \
        --prompt="Privacy action: " \
        --preview='echo {} | cut -d: -f2 | sed "s/^ *//"' \
        --preview-window=up:2:wrap \
        --header="Choose privacy/security action" \
        --color="header:italic:blue,prompt:cyan")
    
    if [[ -n "$selected" ]]; then
        local action=$(echo "$selected" | cut -d: -f1)
        echo
        print_color "$GREEN" "Executing: $action"
        echo
        
        case "$action" in
            audit)
                exec mac security audit
                ;;
            scan)
                exec mac security scan
                ;;
            clean-all)
                exec mac privacy clean all
                ;;
            clean-safari)
                exec mac privacy clean safari
                ;;
            clean-chrome)
                exec mac privacy clean chrome
                ;;
            clean-firefox)
                exec mac privacy clean firefox
                ;;
            clean-system)
                exec mac privacy clean system
                ;;
            permissions)
                exec mac privacy permissions
                ;;
            protect)
                exec mac privacy protect
                ;;
        esac
    fi
}

# fzf-enhanced downloads management
fzf_downloads_menu() {
    local downloads_options=(
        "sort:Sort all downloads by date and type"
        "setup:Set up automatic sorting with Folder Actions"
        "status:Show current downloads organization status"
        "watch:Monitor downloads folder in real-time"
        "analyze:Analyze downloads folder contents"
        "clean:Clean old downloads (interactive)"
        "disable:Disable automatic sorting"
    )
    
    print_color "$BLUE" "📁 Downloads Management"
    echo
    
    local selected=$(printf '%s\n' "${downloads_options[@]}" | fzf \
        --height=12 \
        --layout=reverse \
        --border \
        --prompt="Downloads action: " \
        --preview='echo {} | cut -d: -f2 | sed "s/^ *//"' \
        --preview-window=up:2:wrap \
        --header="Manage your Downloads folder" \
        --color="header:italic:blue,prompt:magenta")
    
    if [[ -n "$selected" ]]; then
        local action=$(echo "$selected" | cut -d: -f1)
        echo
        print_color "$GREEN" "Executing: mac downloads $action"
        echo
        exec mac downloads "$action"
    fi
}

# Interactive fuzzy finder for duplicates
fzf_duplicates_menu() {
    print_color "$BLUE" "🔍 Duplicate File Finder"
    echo "Select directory to search for duplicates:"
    echo
    
    local common_dirs=(
        "$HOME:Home directory"
        "$HOME/Downloads:Downloads folder"
        "$HOME/Documents:Documents folder"
        "$HOME/Pictures:Pictures folder"
        "$HOME/Desktop:Desktop"
        "$HOME/Movies:Movies folder"
        "$HOME/Music:Music folder"
        "custom:Choose custom directory"
    )
    
    local selected=$(printf '%s\n' "${common_dirs[@]}" | fzf \
        --height=12 \
        --layout=reverse \
        --border \
        --prompt="Search directory: " \
        --preview='echo {} | cut -d: -f2 | sed "s/^ *//"' \
        --preview-window=up:2:wrap \
        --header="Select directory to scan for duplicates" \
        --color="header:italic:blue,prompt:yellow")
    
    if [[ -n "$selected" ]]; then
        local dir=$(echo "$selected" | cut -d: -f1)
        
        if [[ "$dir" == "custom" ]]; then
            echo
            read -p "Enter directory path: " custom_dir
            dir="${custom_dir/#\~/$HOME}"
        fi
        
        if [[ -d "$dir" ]]; then
            echo
            print_color "$GREEN" "Searching for duplicates in: $dir"
            echo
            exec mac duplicates "$dir"
        else
            print_color "$RED" "Directory not found: $dir"
            exit 1
        fi
    fi
}

# Main fzf integration function
main() {
    case "${1:-menu}" in
        menu)
            check_fzf && fzf_command_menu
            ;;
        update)
            check_fzf && fzf_update_menu
            ;;
        info)
            check_fzf && fzf_info_menu
            ;;
        uninstall)
            check_fzf && fzf_uninstall_menu
            ;;
        privacy)
            check_fzf && fzf_privacy_menu
            ;;
        downloads)
            check_fzf && fzf_downloads_menu
            ;;
        duplicates)
            check_fzf && fzf_duplicates_menu
            ;;
        *)
            print_color "$RED" "Unknown fzf command: $1"
            echo "Available: menu, update, info, uninstall, privacy, downloads, duplicates"
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi