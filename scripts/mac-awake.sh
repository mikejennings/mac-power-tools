#!/bin/bash

# Mac Power Tools - Keep Awake / Caffeinate
# Keep Mac awake with various options including screensaver mode

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Default settings
DURATION=""
USE_SCREENSAVER=false
PREVENT_DISK_SLEEP=false
PREVENT_DISPLAY_SLEEP=true
WAIT_FOR_PROCESS=""
PID_FILE="/tmp/mac-awake.pid"

# Function to print colored output
print_color() {
    local color=$1
    shift
    printf "${color}%s${NC}\n" "$*"
}

# Function to cleanup on exit
cleanup() {
    if [[ -f "$PID_FILE" ]]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null
            print_color "$YELLOW" "Stopped keeping Mac awake"
        fi
        rm -f "$PID_FILE"
    fi
}

# Function to check if already running
is_running() {
    if [[ -f "$PID_FILE" ]]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            return 0
        else
            rm -f "$PID_FILE"
        fi
    fi
    return 1
}

# Function to stop awake mode
stop_awake() {
    if is_running; then
        local pid=$(cat "$PID_FILE")
        kill "$pid" 2>/dev/null
        rm -f "$PID_FILE"
        print_color "$GREEN" "✓ Stopped keeping Mac awake"
    else
        print_color "$YELLOW" "Mac awake mode is not currently running"
    fi
}

# Function to show status
show_status() {
    if is_running; then
        local pid=$(cat "$PID_FILE")
        print_color "$GREEN" "✓ Mac is being kept awake (PID: $pid)"
        
        # Show process details
        local cmd=$(ps -p "$pid" -o command= 2>/dev/null)
        if [[ -n "$cmd" ]]; then
            print_color "$CYAN" "Command: $cmd"
        fi
    else
        print_color "$YELLOW" "Mac awake mode is not currently running"
    fi
}

# Function to start screensaver
start_screensaver() {
    print_color "$CYAN" "Starting screensaver..."
    open -a ScreenSaverEngine
}

# Function to keep Mac awake
keep_awake() {
    local caffeinate_args=""
    
    # Build caffeinate command arguments
    if [[ "$USE_SCREENSAVER" == true ]]; then
        # -d prevents display sleep but allows screensaver
        # -i prevents system idle sleep
        # -s keeps Mac awake while connected to AC power
        caffeinate_args="-dis"
        print_color "$BLUE" "Keeping Mac awake with screensaver allowed"
    else
        if [[ "$PREVENT_DISPLAY_SLEEP" == true ]]; then
            caffeinate_args="${caffeinate_args}d"
        fi
        caffeinate_args="${caffeinate_args}i"
        print_color "$BLUE" "Keeping Mac awake (display sleep prevented)"
    fi
    
    # Add disk sleep prevention if requested
    if [[ "$PREVENT_DISK_SLEEP" == true ]]; then
        caffeinate_args="${caffeinate_args}m"
        print_color "$CYAN" "Disk sleep prevention enabled"
    fi
    
    # Add process waiting if specified
    if [[ -n "$WAIT_FOR_PROCESS" ]]; then
        # Find process PID
        local process_pid=$(pgrep -f "$WAIT_FOR_PROCESS" | head -1)
        if [[ -n "$process_pid" ]]; then
            caffeinate_args="${caffeinate_args} -w $process_pid"
            print_color "$CYAN" "Will stay awake while process '$WAIT_FOR_PROCESS' (PID: $process_pid) is running"
        else
            print_color "$RED" "Process '$WAIT_FOR_PROCESS' not found"
            return 1
        fi
    fi
    
    # Add duration if specified
    local duration_msg=""
    if [[ -n "$DURATION" ]]; then
        caffeinate_args="${caffeinate_args} -t $DURATION"
        local hours=$((DURATION / 3600))
        local minutes=$(((DURATION % 3600) / 60))
        duration_msg=" for ${hours}h ${minutes}m"
    else
        duration_msg=" (indefinitely)"
    fi
    
    # Start caffeinate in background
    caffeinate -${caffeinate_args} &
    local pid=$!
    
    # Save PID
    echo "$pid" > "$PID_FILE"
    
    print_color "$GREEN" "✓ Mac will stay awake${duration_msg}"
    print_color "$CYAN" "PID: $pid"
    
    # Start screensaver if requested
    if [[ "$USE_SCREENSAVER" == true ]]; then
        sleep 2
        start_screensaver
        print_color "$GREEN" "✓ Screensaver started"
        print_color "$YELLOW" "Note: Move mouse or press a key to exit screensaver (Mac will stay awake)"
    fi
    
    print_color "$YELLOW" "\nTo stop: mac awake --stop"
}

# Function to parse duration string
parse_duration() {
    local duration_str="$1"
    local total_seconds=0
    
    # Check for hours
    if [[ "$duration_str" =~ ([0-9]+)h ]]; then
        total_seconds=$((${BASH_REMATCH[1]} * 3600))
    fi
    
    # Check for minutes
    if [[ "$duration_str" =~ ([0-9]+)m ]]; then
        total_seconds=$((total_seconds + ${BASH_REMATCH[1]} * 60))
    fi
    
    # Check for plain number (assume minutes)
    if [[ "$duration_str" =~ ^[0-9]+$ ]]; then
        total_seconds=$((duration_str * 60))
    fi
    
    echo "$total_seconds"
}

# Function to show examples
show_examples() {
    print_color "$BLUE" "═══════════════════════════════════════════"
    print_color "$BLUE" "Examples"
    print_color "$BLUE" "═══════════════════════════════════════════"
    
    cat << EOF
# Keep Mac awake indefinitely
mac awake

# Keep Mac awake with screensaver
mac awake --screensaver

# Keep Mac awake for 2 hours
mac awake -t 2h

# Keep Mac awake for 45 minutes with screensaver
mac awake -t 45m --screensaver

# Keep Mac awake while a process runs
mac awake -w "backup"

# Keep Mac awake but allow display to sleep
mac awake --allow-display-sleep

# Stop keeping Mac awake
mac awake --stop

# Check status
mac awake --status
EOF
}

# Show help
show_help() {
    cat << EOF
Mac Power Tools - Keep Awake / Caffeinate

USAGE:
    mac awake [OPTIONS]
    mac awake --screensaver

OPTIONS:
    -h, --help              Show this help message
    -s, --screensaver       Keep Mac awake but allow screensaver
    -t, --time DURATION     Keep awake for specific duration (e.g., 2h, 30m, 90m)
    -w, --wait PROCESS      Keep awake while process is running
    -d, --prevent-disk      Prevent disk from sleeping
    --allow-display-sleep   Allow display to sleep (system stays awake)
    --stop                  Stop keeping Mac awake
    --status                Show current awake status
    --examples              Show usage examples

DURATION FORMAT:
    2h                      2 hours
    30m                     30 minutes
    1h30m                   1 hour 30 minutes
    90                      90 minutes (plain number = minutes)

NOTES:
    • Uses macOS caffeinate command internally
    • Screensaver mode keeps Mac awake but shows screensaver
    • Default prevents both system and display sleep
    • Process continues running in background
    • Use --stop to end awake mode

EOF
}

# Main function
main() {
    # Check for no arguments
    if [[ $# -eq 0 ]]; then
        # Default behavior - keep awake indefinitely
        keep_awake
        return $?
    fi
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -s|--screensaver)
                USE_SCREENSAVER=true
                shift
                ;;
            -t|--time)
                DURATION=$(parse_duration "$2")
                if [[ $DURATION -eq 0 ]]; then
                    print_color "$RED" "Invalid duration: $2"
                    exit 1
                fi
                shift 2
                ;;
            -w|--wait)
                WAIT_FOR_PROCESS="$2"
                shift 2
                ;;
            -d|--prevent-disk)
                PREVENT_DISK_SLEEP=true
                shift
                ;;
            --allow-display-sleep)
                PREVENT_DISPLAY_SLEEP=false
                shift
                ;;
            --stop)
                stop_awake
                exit 0
                ;;
            --status)
                show_status
                exit 0
                ;;
            --examples)
                show_examples
                exit 0
                ;;
            *)
                print_color "$RED" "Unknown option: $1"
                echo "Use 'mac awake --help' for usage information"
                exit 1
                ;;
        esac
    done
    
    # Check if already running
    if is_running; then
        print_color "$YELLOW" "Mac awake mode is already running"
        print_color "$CYAN" "Use 'mac awake --stop' to stop it first"
        exit 1
    fi
    
    # Start keeping awake
    keep_awake
}

# Set trap for cleanup
trap cleanup EXIT INT TERM

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi