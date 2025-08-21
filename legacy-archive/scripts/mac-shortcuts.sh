#!/bin/bash

# System shortcuts for macOS - quick access to common tasks
# Part of Mac Power Tools - https://github.com/mikejennings/mac-power-tools

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

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
    echo -e "${CYAN}📸 Enhanced Screenshot Tool${NC}"
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
                echo -e "${RED}Unknown option: $1${NC}"
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
            echo -e "${GREEN}✓ Screenshot copied to clipboard${NC}"
        else
            echo -e "${GREEN}✓ Screenshot saved successfully${NC}"
            
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
        echo -e "${RED}✗ Screenshot failed or cancelled${NC}"
        return 1
    fi
}

shortcuts_lock() {
    echo -e "${CYAN}🔒 Locking Screen${NC}"
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
        echo -e "${GREEN}✓ Screen locked${NC}"
    else
        echo -e "${RED}✗ Unable to lock screen (pmset not available)${NC}"
        return 1
    fi
}

shortcuts_caffeinate() {
    echo -e "${CYAN}☕ Caffeinate System${NC}"
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
            echo -e "${RED}Invalid duration format. Use: 30s, 5m, 2h${NC}"
            return 1
        fi
    fi
    
    # Show current caffeinate status
    if pgrep caffeinate &> /dev/null; then
        echo -e "${YELLOW}⚠ System is already caffeinated${NC}"
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
        
        echo -e "${GREEN}✓ System caffeinated for $duration${NC}"
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
        echo -e "${GREEN}✓ Caffeinate session completed${NC}"
    else
        echo "Running indefinitely (press Ctrl+C to stop)"
        echo ""
        
        # Run caffeinate indefinitely
        caffeinate -d &
        local caffeinate_pid=$!
        
        echo -e "${GREEN}✓ System caffeinated indefinitely${NC}"
        echo "PID: $caffeinate_pid"
        echo "Use 'pkill caffeinate' or Ctrl+C to stop"
    fi
}

shortcuts_airplane() {
    echo -e "${CYAN}✈️  Airplane Mode Toggle${NC}"
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
                echo -e "${GREEN}✓ WiFi disabled${NC}"
            else
                echo -e "${RED}✗ Failed to disable WiFi${NC}"
            fi
            
            # Disable Bluetooth
            if command -v blueutil &> /dev/null; then
                if blueutil -p 0; then
                    echo -e "${GREEN}✓ Bluetooth disabled${NC}"
                else
                    echo -e "${RED}✗ Failed to disable Bluetooth${NC}"
                fi
            else
                echo -e "${YELLOW}⚠ Install blueutil for Bluetooth control: brew install blueutil${NC}"
            fi
            
            echo ""
            echo -e "${GREEN}✓ Airplane mode enabled${NC}"
            ;;
        off)
            echo "Disabling airplane mode (enabling WiFi and Bluetooth)..."
            
            # Enable WiFi
            if networksetup -setairportpower en0 on 2>/dev/null; then
                echo -e "${GREEN}✓ WiFi enabled${NC}"
            else
                echo -e "${RED}✗ Failed to enable WiFi${NC}"
            fi
            
            # Enable Bluetooth
            if command -v blueutil &> /dev/null; then
                if blueutil -p 1; then
                    echo -e "${GREEN}✓ Bluetooth enabled${NC}"
                else
                    echo -e "${RED}✗ Failed to enable Bluetooth${NC}"
                fi
            else
                echo -e "${YELLOW}⚠ Install blueutil for Bluetooth control: brew install blueutil${NC}"
            fi
            
            echo ""
            echo -e "${GREEN}✓ Airplane mode disabled${NC}"
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
    echo -e "${CYAN}🚢 Dock Management${NC}"
    echo ""
    
    local action="$1"
    
    case "$action" in
        show)
            echo "Showing Dock..."
            defaults write com.apple.dock autohide -bool false
            killall Dock
            echo -e "${GREEN}✓ Dock is now always visible${NC}"
            ;;
        hide)
            echo "Hiding Dock (auto-hide enabled)..."
            defaults write com.apple.dock autohide -bool true
            killall Dock
            echo -e "${GREEN}✓ Dock will auto-hide${NC}"
            ;;
        restart)
            echo "Restarting Dock..."
            killall Dock
            echo -e "${GREEN}✓ Dock restarted${NC}"
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
    echo -e "${CYAN}📁 Finder Controls${NC}"
    echo ""
    
    local action="$1"
    
    case "$action" in
        restart)
            echo "Restarting Finder..."
            killall Finder
            echo -e "${GREEN}✓ Finder restarted${NC}"
            ;;
        showall)
            local current_setting=$(defaults read com.apple.finder AppleShowAllFiles 2>/dev/null || echo "false")
            
            if [ "$current_setting" = "true" ] || [ "$current_setting" = "1" ]; then
                echo "Hiding hidden files..."
                defaults write com.apple.finder AppleShowAllFiles -bool false
                echo -e "${GREEN}✓ Hidden files are now hidden${NC}"
            else
                echo "Showing hidden files..."
                defaults write com.apple.finder AppleShowAllFiles -bool true
                echo -e "${GREEN}✓ Hidden files are now visible${NC}"
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
    echo -e "${CYAN}🖥️  Display Control${NC}"
    echo ""
    
    local action="$1"
    
    case "$action" in
        sleep)
            echo "Putting display to sleep..."
            pmset displaysleepnow
            echo -e "${GREEN}✓ Display sleeping${NC}"
            ;;
        wake)
            echo "Waking display..."
            # Move mouse slightly to wake display
            if command -v cliclick &> /dev/null; then
                cliclick m:+1,+1
                cliclick m:-1,-1
                echo -e "${GREEN}✓ Display awakened${NC}"
            else
                echo -e "${YELLOW}Install cliclick for programmatic wake: brew install cliclick${NC}"
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
    echo -e "${CYAN}🔊 Volume Control${NC}"
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
            echo -e "${GREEN}✓ Volume set to ${new_volume}%${NC}"
            ;;
        down)
            local decrease=${amount:-10}
            local new_volume=$((current_volume - decrease))
            if [ $new_volume -lt 0 ]; then
                new_volume=0
            fi
            
            echo "Decreasing volume by ${decrease}%..."
            osascript -e "set volume output volume $new_volume"
            echo -e "${GREEN}✓ Volume set to ${new_volume}%${NC}"
            ;;
        mute)
            if [ "$current_muted" = "true" ]; then
                echo "Unmuting..."
                osascript -e "set volume output muted false"
                echo -e "${GREEN}✓ Volume unmuted${NC}"
            else
                echo "Muting..."
                osascript -e "set volume output muted true"
                echo -e "${GREEN}✓ Volume muted${NC}"
            fi
            ;;
        [0-9]|[0-9][0-9]|100)
            local target_volume="$action"
            echo "Setting volume to ${target_volume}%..."
            osascript -e "set volume output volume $target_volume"
            echo -e "${GREEN}✓ Volume set to ${target_volume}%${NC}"
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