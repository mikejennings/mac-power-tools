#!/bin/bash

# Mac Maintenance Plugin - Native implementation
# System maintenance utilities

# Source the plugin API
source "${MAC_POWER_TOOLS_HOME}/lib/plugin-api.sh"

# Empty trash
empty_trash() {
    print_info "Emptying trash..."
    
    # Get trash size first
    local trash_size=$(du -sh ~/.Trash 2>/dev/null | cut -f1 || echo "0B")
    print_info "Current trash size: $trash_size"
    
    if [ "$trash_size" = "0B" ]; then
        print_success "Trash is already empty"
    else
        if confirm "Empty trash?"; then
            rm -rf ~/.Trash/*
            print_success "Trash emptied (freed $trash_size)"
        else
            print_warning "Skipping trash empty"
        fi
    fi
}

# Clear caches
clear_caches() {
    print_info "Clearing system caches..."
    
    local cache_size=$(du -sh ~/Library/Caches 2>/dev/null | cut -f1 || echo "0B")
    print_info "Current user cache size: $cache_size"
    
    if confirm "Clear user caches?"; then
        rm -rf ~/Library/Caches/*
        print_success "User caches cleared"
    else
        print_warning "Skipping user cache clear"
    fi
    
    if confirm "Clear system caches (requires sudo)?"; then
        sudo rm -rf /Library/Caches/*
        sudo rm -rf /System/Library/Caches/*
        print_success "System caches cleared"
    else
        print_warning "Skipping system cache clear"
    fi
}

# Clean downloads folder
clean_downloads() {
    print_info "Analyzing Downloads folder..."
    
    local downloads_size=$(du -sh ~/Downloads 2>/dev/null | cut -f1 || echo "0B")
    print_info "Downloads folder size: $downloads_size"
    
    # Check if our sorting system is active
    if [ -f ~/Library/Scripts/Folder\ Action\ Scripts/Sort\ Downloads\ by\ Date\ and\ Type.scpt ]; then
        print_success "Downloads folder is automatically sorted"
        
        # Show recent sorted folders
        echo -e "${CYAN}Recent date folders:${NC}"
        ls -dt ~/Downloads/20*/ 2>/dev/null | head -5 | while read folder; do
            local size=$(du -sh "$folder" | cut -f1)
            echo "  $(basename "$folder"): $size"
        done
    else
        print_warning "Downloads sorting not configured"
        echo "Run mac downloads setup to organize Downloads folder"
    fi
}

# Find large files
find_large_files() {
    print_info "Finding large files (>100MB)..."
    
    echo -e "${CYAN}Largest files in home directory:${NC}"
    find ~ -type f -size +100M 2>/dev/null | xargs -I {} du -h {} 2>/dev/null | sort -rh | head -10 || echo "No large files found"
}

# Find large directories
find_large_directories() {
    print_info "Finding large directories..."
    
    echo -e "${CYAN}Largest directories in home:${NC}"
    du -sh ~/* 2>/dev/null | sort -rh | head -10
}

# Clean old logs
clean_logs() {
    print_info "Cleaning old log files..."
    
    # User logs
    local user_logs_size=$(du -sh ~/Library/Logs 2>/dev/null | cut -f1 || echo "0B")
    print_info "User logs size: $user_logs_size"
    
    if confirm "Clean old user logs (>30 days)?"; then
        find ~/Library/Logs -type f -mtime +30 -delete 2>/dev/null
        print_success "Old user logs cleaned"
    else
        print_warning "Skipping user logs cleanup"
    fi
    
    # System logs
    if confirm "Clean old system logs (requires sudo, >30 days)?"; then
        sudo find /var/log -type f -mtime +30 -delete 2>/dev/null
        print_success "Old system logs cleaned"
    else
        print_warning "Skipping system logs cleanup"
    fi
}

# Flush DNS cache
flush_dns() {
    print_info "Flushing DNS cache..."
    
    sudo dscacheutil -flushcache
    sudo killall -HUP mDNSResponder
    print_success "DNS cache flushed"
}

# Rebuild Spotlight index
rebuild_spotlight() {
    print_info "Rebuilding Spotlight index..."
    
    if confirm "Rebuild Spotlight index? This may take a while."; then
        sudo mdutil -E /
        print_success "Spotlight index rebuild initiated"
    else
        print_warning "Skipping Spotlight rebuild"
    fi
}

# Toggle hidden files
toggle_hidden_files() {
    local current_state=$(defaults read com.apple.finder AppleShowAllFiles 2>/dev/null || echo "NO")
    
    if [ "$current_state" = "YES" ]; then
        print_info "Hiding hidden files..."
        defaults write com.apple.finder AppleShowAllFiles NO
        print_success "Hidden files are now hidden"
    else
        print_info "Showing hidden files..."
        defaults write com.apple.finder AppleShowAllFiles YES
        print_success "Hidden files are now visible"
    fi
    
    killall Finder
}

# Repair disk permissions
repair_permissions() {
    print_info "Repairing disk permissions..."
    
    if confirm "Run disk First Aid (requires sudo)?"; then
        sudo diskutil verifyVolume /
        sudo diskutil repairVolume /
        print_success "Disk permissions repaired"
    else
        print_warning "Skipping disk repair"
    fi
}

# Kill all apps
kill_all_apps() {
    print_info "This will close all open applications..."
    
    if confirm "Close all applications?"; then
        osascript -e 'tell application "System Events" to set quitapps to name of every application process whose visible is true and name is not "Finder"'
        osascript -e 'repeat with appname in quitapps
            tell application appname to quit
        end repeat' 2>/dev/null
        print_success "All applications closed"
    else
        print_warning "Cancelled"
    fi
}

# System sleep
system_sleep() {
    print_info "Putting system to sleep in 5 seconds..."
    echo "Press Ctrl+C to cancel"
    sleep 5
    pmset sleepnow
}

# System restart
system_restart() {
    print_info "System will restart in 10 seconds..."
    echo "Press Ctrl+C to cancel"
    sleep 10
    sudo shutdown -r now
}

# System shutdown
system_shutdown() {
    print_info "System will shutdown in 10 seconds..."
    echo "Press Ctrl+C to cancel"
    sleep 10
    sudo shutdown -h now
}

# Run all maintenance tasks
run_all_maintenance() {
    print_info "Running all maintenance tasks..."
    empty_trash
    clear_caches
    clean_downloads
    clean_logs
    flush_dns
    print_success "All maintenance tasks completed"
}

# Main menu
show_menu() {
    echo "==================================="
    echo "    Mac Maintenance Utilities      "
    echo "==================================="
    echo
    echo "1) Empty trash"
    echo "2) Clear caches"
    echo "3) Clean Downloads folder"
    echo "4) Find large files"
    echo "5) Find large directories"
    echo "6) Clean old logs"
    echo "7) Flush DNS cache"
    echo "8) Rebuild Spotlight index"
    echo "9) Toggle hidden files"
    echo "10) Repair disk permissions"
    echo "11) Kill all apps"
    echo "12) Sleep"
    echo "13) Restart"
    echo "14) Shutdown"
    echo "15) Run all maintenance tasks"
    echo "0) Exit"
    echo
    read -p "Select option: " choice
    
    case $choice in
        1) empty_trash ;;
        2) clear_caches ;;
        3) clean_downloads ;;
        4) find_large_files ;;
        5) find_large_directories ;;
        6) clean_logs ;;
        7) flush_dns ;;
        8) rebuild_spotlight ;;
        9) toggle_hidden_files ;;
        10) repair_permissions ;;
        11) kill_all_apps ;;
        12) system_sleep ;;
        13) system_restart ;;
        14) system_shutdown ;;
        15) run_all_maintenance ;;
        0) exit 0 ;;
        *) print_error "Invalid option" ;;
    esac
}

# Plugin main entry point
plugin_main() {
    if [ $# -eq 0 ]; then
        # Interactive menu
        show_menu
    else
        # Direct command execution
        case $1 in
            trash)
                empty_trash
                ;;
            cache|caches)
                clear_caches
                ;;
            downloads)
                clean_downloads
                ;;
            large-files)
                find_large_files
                ;;
            large-dirs|large-directories)
                find_large_directories
                ;;
            logs)
                clean_logs
                ;;
            dns)
                flush_dns
                ;;
            spotlight)
                rebuild_spotlight
                ;;
            hidden)
                toggle_hidden_files
                ;;
            permissions)
                repair_permissions
                ;;
            kill-apps)
                kill_all_apps
                ;;
            sleep)
                system_sleep
                ;;
            restart)
                system_restart
                ;;
            shutdown)
                system_shutdown
                ;;
            all)
                run_all_maintenance
                ;;
            *)
                print_error "Unknown command: $1"
                echo "Available commands:"
                echo "  trash, cache, downloads, large-files, large-dirs,"
                echo "  logs, dns, spotlight, hidden, permissions,"
                echo "  kill-apps, sleep, restart, shutdown, all"
                return 1
                ;;
        esac
    fi
}

# Initialize the plugin
plugin_init

# Call the main function if not sourced
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    plugin_main "$@"
fi
