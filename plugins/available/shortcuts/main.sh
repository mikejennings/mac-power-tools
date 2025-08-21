#!/bin/bash

# Native plugin implementation
# Migrated from legacy script to use plugin API

# Source the plugin API
source "${MAC_POWER_TOOLS_HOME}/lib/plugin-api.sh"




# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

show_shortcuts_help() {
    echo "Usage: mac shortcuts [command] [options]"
    echo ""
    echo "Quick access to common macOS system tasks"
    echo ""
    echo "Commands:"
    echo "  screenshot [options]    Enhanced screenshot with annotations"
    echo "  lock                    Lock screen immediately"
    echo "  caffeinate [duration]   Keep Mac awake (like awake command)"
    echo "  airplane [on/off]       Toggle airplane mode"
    echo "  dock [show/hide/restart] Dock management"
    echo "  finder [restart/showall] Finder controls"
    echo "  display [sleep/wake]     Display control"
    echo "  volume [up/down/mute/level] Volume control"
    echo ""
    echo "Screenshot Options:"
    echo "  --selection             Capture selection (default)"
    echo "  --window                Capture window"
    echo "  --screen                Capture entire screen"
    echo "  --timed [seconds]       Capture after delay (default: 5 seconds)"
    echo "  --clipboard             Copy to clipboard only"
    echo "  --shadow                Include window shadow"
    echo "  --no-shadow             Exclude window shadow"
    echo ""
    echo "Volume Options:"
    echo "  up [amount]             Increase volume (default: 10%)"
    echo "  down [amount]           Decrease volume (default: 10%)"
    echo "  mute                    Toggle mute"
    echo "  [0-100]                 Set specific volume level"
    echo ""
    echo "Examples:"
    echo "  mac shortcuts screenshot --window"
    echo "  mac shortcuts volume 50"
    echo "  mac shortcuts caffeinate 2h"
    echo "  mac shortcuts airplane on"
    echo ""
}

shortcuts_screenshot() {
    print_info "📸 Enhanced Screenshot Tool"
    echo ""
    
    local mode="selection"
    local output_path="$HOME/Desktop"
    local filename="Screenshot $(date '+%Y-%m-%d at %H.%M.%S').png"
    local clipboard_only=false
    local timed=false
    local delay=5
    local shadow=true
    local screencapture_args=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --selection)
                mode="selection"
                shift
                ;;
            --window)
                mode="window"
                shift
                ;;
            --screen)
                mode="screen"
                shift
                ;;
            --timed)
                timed=true
                if [[ $2 =~ ^[0-9]+$ ]]; then
                    delay=$2
                    shift
                fi
                shift
                ;;
            --clipboard)
                clipboard_only=true
                shift
                ;;
            --shadow)
                shadow=true
                shift
                ;;
            --no-shadow)
                shadow=false
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                return 1
                ;;
        esac
    done
    
    # Build screencapture command
    if [ "$clipboard_only" = true ]; then
        screencapture_args="-c"
        echo "Capturing to clipboard..."
    else
        screencapture_args="$output_path/$filename"
        echo "Saving to: $output_path/$filename"
    fi
    
    # Add timing if requested
    if [ "$timed" = true ]; then
        screencapture_args="-T $delay $screencapture_args"
        echo "Starting capture in $delay seconds..."
    fi
    
    # Add shadow settings for window capture
    if [ "$mode" = "window" ]; then
        if [ "$shadow" = false ]; then
            screencapture_args="-o $screencapture_args"
        fi
        screencapture_args="-w $screencapture_args"
        echo "Click on a window to capture..."
    elif [ "$mode" = "screen" ]; then
        screencapture_args="-m $screencapture_args"
        echo "Capturing entire screen..."
    else
        screencapture_args="-s $screencapture_args"
        echo "Click and drag to select area..."
    fi
    
    # Execute screenshot
    if screencapture $screencapture_args 2>/dev/null; then
        if [ "$clipboard_only" = true ]; then
            print_success "✓ Screenshot copied to clipboard"
        else
            print_success "✓ Screenshot saved successfully"
            
            # Offer to open
            read -p "Open screenshot? (y/N): " -r
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                open "$output_path/$filename"
            fi
            
            # Offer annotations
            read -p "Add annotations? (y/N): " -r
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                if command -v open &> /dev/null; then
                    open -a Preview "$output_path/$filename"
                    echo "Use Preview's markup tools to add annotations"
                fi
            fi
        fi
    else
        print_error "✗ Screenshot failed or cancelled"
        return 1
    fi
}

shortcuts_lock() {
    print_info "🔒 Locking Screen"
    echo ""
    
    # Check if we should confirm
    read -p "Lock screen now? (Y/n): " -r
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo "Lock cancelled"
        return 0
    fi
    
    echo "Locking screen..."
    
    # Use pmset to sleep display immediately (most reliable method)
    if command -v pmset &> /dev/null; then
        pmset displaysleepnow
        print_success "✓ Screen locked"
    else
        print_error "✗ Unable to lock screen (pmset not available)"
        return 1
    fi
}

shortcuts_caffeinate() {
    print_info "☕ Caffeinate System"
    echo ""
    
    local duration=""
    local duration_seconds=""
    
    if [ -n "$1" ]; then
        duration="$1"
        
        # Parse duration (support h, m, s suffixes)
        if [[ "$duration" =~ ^([0-9]+)([hms]?)$ ]]; then
            local num="${BASH_REMATCH[1]}"
            local unit="${BASH_REMATCH[2]:-s}"
            
            case "$unit" in
                h) duration_seconds=$((num * 3600)) ;;
                m) duration_seconds=$((num * 60)) ;;
                s) duration_seconds=$num ;;
            esac
        else
            print_error "Invalid duration format. Use: 30s, 5m, 2h"
            return 1
        fi
    fi
    
    # Show current caffeinate status
    if pgrep caffeinate &> /dev/null; then
        print_warning "⚠ System is already caffeinated"
        echo ""
        read -p "Stop current caffeinate and start new session? (y/N): " -r
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            pkill caffeinate
            echo "Stopped previous caffeinate session"
        else
            return 0
        fi
    fi
    
    echo "Starting caffeinate session..."
    
    if [ -n "$duration_seconds" ]; then
        echo "Duration: $duration"
        echo "Press Ctrl+C to stop early"
        echo ""
        
        # Run caffeinate with timeout
        caffeinate -d -t "$duration_seconds" &
        local caffeinate_pid=$!
        
        print_success "✓ System caffeinated for $duration"
        echo "PID: $caffeinate_pid"
        
        # Show countdown
        local remaining=$duration_seconds
        while [ $remaining -gt 0 ] && kill -0 $caffeinate_pid 2>/dev/null; do
            local hours=$((remaining / 3600))
            local minutes=$(((remaining % 3600) / 60))
            local seconds=$((remaining % 60))
            
            if [ $hours -gt 0 ]; then
                printf "\rTime remaining: %02d:%02d:%02d" $hours $minutes $seconds
            else
                printf "\rTime remaining: %02d:%02d" $minutes $seconds
            fi
            
            sleep 1
            remaining=$((remaining - 1))
        done
        
        echo ""
        print_success "✓ Caffeinate session completed"
    else
        echo "Running indefinitely (press Ctrl+C to stop)"
        echo ""
        
        # Run caffeinate indefinitely
        caffeinate -d &
        local caffeinate_pid=$!
        
        print_success "✓ System caffeinated indefinitely"
        echo "PID: $caffeinate_pid"
        echo "Use 'pkill caffeinate' or Ctrl+C to stop"
    fi
}

shortcuts_airplane() {
    print_info "✈️  Airplane Mode Toggle"
    echo ""
    
    local action="$1"
    
    # Get current network status
    local wifi_status=$(networksetup -getairportpower en0 2>/dev/null | grep -o "On\|Off")
    local bluetooth_status
    
    if command -v blueutil &> /dev/null; then
        bluetooth_status=$(blueutil -p)
        if [ "$bluetooth_status" = "1" ]; then
            bluetooth_status="On"
        else
            bluetooth_status="Off"
        fi
    else
        bluetooth_status="Unknown (blueutil not installed)"
    fi
    
    echo "Current Status:"
    echo "  WiFi: $wifi_status"
    echo "  Bluetooth: $bluetooth_status"
    echo ""
    
    case "$action" in
        on)
            echo "Enabling airplane mode (disabling WiFi and Bluetooth)..."
            
            # Disable WiFi
            if networksetup -setairportpower en0 off 2>/dev/null; then
                print_success "✓ WiFi disabled"
            else
                print_error "✗ Failed to disable WiFi"
            fi
            
            # Disable Bluetooth
            if command -v blueutil &> /dev/null; then
                if blueutil -p 0; then
                    print_success "✓ Bluetooth disabled"
                else
                    print_error "✗ Failed to disable Bluetooth"
                fi
            else
                print_warning "⚠ Install blueutil for Bluetooth control: brew install blueutil"
            fi
            
            echo ""
            print_success "✓ Airplane mode enabled"
            ;;
        off)
            echo "Disabling airplane mode (enabling WiFi and Bluetooth)..."
            
            # Enable WiFi
            if networksetup -setairportpower en0 on 2>/dev/null; then
                print_success "✓ WiFi enabled"
            else
                print_error "✗ Failed to enable WiFi"
            fi
            
            # Enable Bluetooth
            if command -v blueutil &> /dev/null; then
                if blueutil -p 1; then
                    print_success "✓ Bluetooth enabled"
                else
                    print_error "✗ Failed to enable Bluetooth"
                fi
            else
                print_warning "⚠ Install blueutil for Bluetooth control: brew install blueutil"
            fi
            
            echo ""
            print_success "✓ Airplane mode disabled"
            ;;
        *)
            echo "Choose action:"
            echo "  1) Enable airplane mode (disable WiFi & Bluetooth)"
            echo "  2) Disable airplane mode (enable WiFi & Bluetooth)"
            echo ""
            read -p "Enter choice (1-2): " -r choice
            
            case "$choice" in
                1) shortcuts_airplane on ;;
                2) shortcuts_airplane off ;;
                *) echo "Invalid choice" ;;
            esac
            ;;
    esac
}

shortcuts_dock() {
    print_info "🚢 Dock Management"
    echo ""
    
    local action="$1"
    
    case "$action" in
        show)
            echo "Showing Dock..."
            defaults write com.apple.dock autohide -bool false
            killall Dock
            print_success "✓ Dock is now always visible"
            ;;
        hide)
            echo "Hiding Dock (auto-hide enabled)..."
            defaults write com.apple.dock autohide -bool true
            killall Dock
            print_success "✓ Dock will auto-hide"
            ;;
        restart)
            echo "Restarting Dock..."
            killall Dock
            print_success "✓ Dock restarted"
            ;;
        *)
            # Show current status
            local autohide=$(defaults read com.apple.dock autohide 2>/dev/null || echo "0")
            echo "Current Status:"
            if [ "$autohide" = "1" ]; then
                echo "  Auto-hide: Enabled"
            else
                echo "  Auto-hide: Disabled"
            fi
            echo ""
            
            echo "Available actions:"
            echo "  1) Show dock (disable auto-hide)"
            echo "  2) Hide dock (enable auto-hide)"
            echo "  3) Restart dock"
            echo ""
            read -p "Enter choice (1-3): " -r choice
            
            case "$choice" in
                1) shortcuts_dock show ;;
                2) shortcuts_dock hide ;;
                3) shortcuts_dock restart ;;
                *) echo "Invalid choice" ;;
            esac
            ;;
    esac
}

shortcuts_finder() {
    print_info "📁 Finder Controls"
    echo ""
    
    local action="$1"
    
    case "$action" in
        restart)
            echo "Restarting Finder..."
            killall Finder
            print_success "✓ Finder restarted"
            ;;
        showall)
            local current_setting=$(defaults read com.apple.finder AppleShowAllFiles 2>/dev/null || echo "false")
            
            if [ "$current_setting" = "true" ] || [ "$current_setting" = "1" ]; then
                echo "Hiding hidden files..."
                defaults write com.apple.finder AppleShowAllFiles -bool false
                print_success "✓ Hidden files are now hidden"
            else
                echo "Showing hidden files..."
                defaults write com.apple.finder AppleShowAllFiles -bool true
                print_success "✓ Hidden files are now visible"
            fi
            
            # Restart Finder to apply changes
            killall Finder
            ;;
        *)
            local show_hidden=$(defaults read com.apple.finder AppleShowAllFiles 2>/dev/null || echo "false")
            
            echo "Current Status:"
            if [ "$show_hidden" = "true" ] || [ "$show_hidden" = "1" ]; then
                echo "  Hidden files: Visible"
            else
                echo "  Hidden files: Hidden"
            fi
            echo ""
            
            echo "Available actions:"
            echo "  1) Restart Finder"
            echo "  2) Toggle hidden files visibility"
            echo ""
            read -p "Enter choice (1-2): " -r choice
            
            case "$choice" in
                1) shortcuts_finder restart ;;
                2) shortcuts_finder showall ;;
                *) echo "Invalid choice" ;;
            esac
            ;;
    esac
}

shortcuts_display() {
    print_info "🖥️  Display Control"
    echo ""
    
    local action="$1"
    
    case "$action" in
        sleep)
            echo "Putting display to sleep..."
            pmset displaysleepnow
            print_success "✓ Display sleeping"
            ;;
        wake)
            echo "Waking display..."
            # Move mouse slightly to wake display
            if command -v cliclick &> /dev/null; then
                cliclick m:+1,+1
                cliclick m:-1,-1
                print_success "✓ Display awakened"
            else
                print_warning "Install cliclick for programmatic wake: brew install cliclick"
                echo "Alternative: Press any key or move mouse to wake display"
            fi
            ;;
        *)
            echo "Available actions:"
            echo "  1) Sleep display"
            echo "  2) Wake display"
            echo ""
            read -p "Enter choice (1-2): " -r choice
            
            case "$choice" in
                1) shortcuts_display sleep ;;
                2) shortcuts_display wake ;;
                *) echo "Invalid choice" ;;
            esac
            ;;
    esac
}

shortcuts_volume() {
    print_info "🔊 Volume Control"
    echo ""
    
    local action="$1"
    local amount="$2"
    
    # Get current volume
    local current_volume=$(osascript -e "output volume of (get volume settings)")
    local current_muted=$(osascript -e "output muted of (get volume settings)")
    
    echo "Current Volume: ${current_volume}%"
    if [ "$current_muted" = "true" ]; then
        echo "Status: Muted"
    else
        echo "Status: Unmuted"
    fi
    echo ""
    
    case "$action" in
        up)
            local increase=${amount:-10}
            local new_volume=$((current_volume + increase))
            if [ $new_volume -gt 100 ]; then
                new_volume=100
            fi
            
            echo "Increasing volume by ${increase}%..."
            osascript -e "set volume output volume $new_volume"
            print_success "✓ Volume set to ${new_volume}%"
            ;;
        down)
            local decrease=${amount:-10}
            local new_volume=$((current_volume - decrease))
            if [ $new_volume -lt 0 ]; then
                new_volume=0
            fi
            
            echo "Decreasing volume by ${decrease}%..."
            osascript -e "set volume output volume $new_volume"
            print_success "✓ Volume set to ${new_volume}%"
            ;;
        mute)
            if [ "$current_muted" = "true" ]; then
                echo "Unmuting..."
                osascript -e "set volume output muted false"
                print_success "✓ Volume unmuted"
            else
                echo "Muting..."
                osascript -e "set volume output muted true"
                print_success "✓ Volume muted"
            fi
            ;;
        [0-9]|[0-9][0-9]|100)
            local target_volume="$action"
            echo "Setting volume to ${target_volume}%..."
            osascript -e "set volume output volume $target_volume"
            print_success "✓ Volume set to ${target_volume}%"
            ;;
        *)
            echo "Volume controls:"
            echo "  1) Increase volume (+10%)"
            echo "  2) Decrease volume (-10%)"
            echo "  3) Toggle mute"
            echo "  4) Set specific level"
            echo ""
            read -p "Enter choice (1-4): " -r choice
            
            case "$choice" in
                1) shortcuts_volume up ;;
                2) shortcuts_volume down ;;
                3) shortcuts_volume mute ;;
                4) 
                    read -p "Enter volume level (0-100): " -r level
                    if [[ "$level" =~ ^[0-9]+$ ]] && [ "$level" -ge 0 ] && [ "$level" -le 100 ]; then
                        shortcuts_volume "$level"
                    else
                        echo "Invalid volume level"
                    fi
                    ;;
                *) echo "Invalid choice" ;;
            esac
            ;;
    esac
}

# Main command handler
case "${1:-}" in
    screenshot)
        shift
        shortcuts_screenshot "$@"
        ;;
    lock)
        shortcuts_lock
        ;;
    caffeinate)
        shift
        shortcuts_caffeinate "$@"
        ;;
    airplane)
        shift
        shortcuts_airplane "$@"
        ;;
    dock)
        shift
        shortcuts_dock "$@"
        ;;
    finder)
        shift
        shortcuts_finder "$@"
        ;;
    display)
        shift
        shortcuts_display "$@"
        ;;
    volume)
        shift
        shortcuts_volume "$@"
        ;;
    *)
        show_shortcuts_help
        ;;
esac

# Plugin main entry point
plugin_main() {
    # This plugin uses case statement structure - execute case directly
    local arg1="${1:-}"
    
    case "$arg1" in
        screenshot)
            shift
            shortcuts_screenshot "$@"
            ;;
        lock)
            shortcuts_lock
            ;;
        caffeinate)
            shift
            shortcuts_caffeinate "$@"
            ;;
        airplane)
            shift
            shortcuts_airplane "$@"
            ;;
        dock)
            shift
            shortcuts_dock "$@"
            ;;
        finder)
            shift
            shortcuts_finder "$@"
            ;;
        display)
            shift
            shortcuts_display "$@"
            ;;
        volume)
            shift
            shortcuts_volume "$@"
            ;;
        *)
            show_shortcuts_help
            ;;
    esac
}

# Initialize the plugin
plugin_init

# Call the main function if not sourced
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    plugin_main "$@"
fi
