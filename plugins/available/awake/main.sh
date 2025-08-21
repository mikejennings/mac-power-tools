#!/bin/bash

# Native plugin implementation
# Migrated from legacy script to use plugin API

# Source the plugin API
source "${MAC_POWER_TOOLS_HOME}/lib/plugin-api.sh"




# Default settings
DURATION=""
USE_SCREENSAVER=false
PREVENT_DISK_SLEEP=false
PREVENT_DISPLAY_SLEEP=true
WAIT_FOR_PROCESS=""
PID_FILE="/tmp/mac-awake.pid"
INFO_FILE="/tmp/mac-awake.info"

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
            print_warning "Stopped keeping Mac awake"
        fi
        rm -f "$PID_FILE"
        rm -f "$INFO_FILE"
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
        rm -f "$INFO_FILE"
        print_success "✓ Stopped keeping Mac awake"
    else
        print_warning "Mac awake mode is not currently running"
    fi
}

# Function to show status
show_status() {
    if is_running; then
        local pid=$(cat "$PID_FILE")
        print_success "✓ Mac is being kept awake (PID: $pid)"
        
        # Check for session info
        if [[ -f "$INFO_FILE" ]]; then
            source "$INFO_FILE"
            
            # Show session type
            if [[ -n "$AWAKE_DURATION" ]] && [[ "$AWAKE_DURATION" -gt 0 ]]; then
                local current_time=$(date +%s)
                local elapsed=$((current_time - AWAKE_START))
                local remaining=$((AWAKE_DURATION - elapsed))
                
                if [[ $remaining -gt 0 ]]; then
                    local hours=$((remaining / 3600))
                    local minutes=$(((remaining % 3600) / 60))
                    local seconds=$((remaining % 60))
                    
                    print_info "Time remaining: ${hours}h ${minutes}m ${seconds}s"
                    
                    # Show progress bar
                    local progress=$((elapsed * 100 / AWAKE_DURATION))
                    local bar_length=30
                    local filled=$((progress * bar_length / 100))
                    local empty=$((bar_length - filled))
                    
                    printf "${CYAN}Progress: ["
                    printf "%${filled}s" | tr ' ' '='
                    printf "%${empty}s" | tr ' ' '-'
                    printf "] %d%%${NC}\n" "$progress"
                else
                    print_warning "Session should have ended (may be extending)"
                fi
            else
                print_info "Running indefinitely"
            fi
            
            if [[ "$AWAKE_SCREENSAVER" == "true" ]]; then
                print_info "Screensaver mode enabled"
            fi
            
            if [[ -n "$AWAKE_PROCESS" ]]; then
                print_info "Waiting for process: $AWAKE_PROCESS"
            fi
        else
            # Show process details
            local cmd=$(ps -p "$pid" -o command= 2>/dev/null)
            if [[ -n "$cmd" ]]; then
                print_info "Command: $cmd"
            fi
        fi
    else
        print_warning "Mac awake mode is not currently running"
    fi
}

# Function to start screensaver
start_screensaver() {
    print_info "Starting screensaver..."
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
        caffeinate_args="dis"
    else
        if [[ "$PREVENT_DISPLAY_SLEEP" == true ]]; then
            caffeinate_args="${caffeinate_args}d"
        fi
        caffeinate_args="${caffeinate_args}i"
    fi
    
    # Add disk sleep prevention if requested
    if [[ "$PREVENT_DISK_SLEEP" == true ]]; then
        caffeinate_args="${caffeinate_args}m"
        print_info "Disk sleep prevention enabled"
    fi
    
    # Add process waiting if specified
    if [[ -n "$WAIT_FOR_PROCESS" ]]; then
        # Find process PID
        local process_pid=$(pgrep -f "$WAIT_FOR_PROCESS" | head -1)
        if [[ -n "$process_pid" ]]; then
            caffeinate_args="${caffeinate_args} -w $process_pid"
            print_info "Will stay awake while process '$WAIT_FOR_PROCESS' (PID: $process_pid) is running"
        else
            print_error "Process '$WAIT_FOR_PROCESS' not found"
            return 1
        fi
    fi
    
    # Add duration if specified
    local duration_msg=""
    if [[ -n "$DURATION" ]]; then
        caffeinate_args="${caffeinate_args} -t $DURATION"
        local hours=$((DURATION / 3600))
        local minutes=$(((DURATION % 3600) / 60))
        local seconds=$((DURATION % 60))
        
        # Format duration message
        if [[ $hours -gt 0 ]]; then
            duration_msg="${hours}h ${minutes}m"
        elif [[ $minutes -gt 0 ]]; then
            duration_msg="${minutes}m"
        else
            duration_msg="${seconds}s"
        fi
    else
        duration_msg="indefinitely"
    fi
    
    # Start caffeinate in background with nohup
    nohup caffeinate -${caffeinate_args} > /dev/null 2>&1 &
    local pid=$!
    
    # Disown the process so it continues after script exits
    disown $pid
    
    # Save PID
    echo "$pid" > "$PID_FILE"
    
    # Save session info
    {
        echo "AWAKE_START=$(date +%s)"
        echo "AWAKE_DURATION=${DURATION:-0}"
        echo "AWAKE_SCREENSAVER=$USE_SCREENSAVER"
        echo "AWAKE_PROCESS=\"$WAIT_FOR_PROCESS\""
    } > "$INFO_FILE"
    
    # Display status message
    if [[ "$USE_SCREENSAVER" == true ]]; then
        print_success "✓ Mac will stay awake for $duration_msg"
        print_info "Mode: Screensaver allowed"
    else
        print_success "✓ Mac will stay awake for $duration_msg"
        if [[ "$PREVENT_DISPLAY_SLEEP" == true ]]; then
            print_info "Mode: Display sleep prevented"
        else
            print_info "Mode: Display sleep allowed"
        fi
    fi
    print_info "PID: $pid"
    
    # Start screensaver if requested
    if [[ "$USE_SCREENSAVER" == true ]]; then
        sleep 2
        start_screensaver
        print_success "✓ Screensaver started"
        print_warning "Note: Move mouse or press a key to exit screensaver (Mac will stay awake)"
    fi
    
    echo
    print_warning "To stop: mac awake --stop"
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
    print_info "═══════════════════════════════════════════"
    print_info "Examples"
    print_info "═══════════════════════════════════════════"
    
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
                    print_error "Invalid duration: $2"
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
                print_error "Unknown option: $1"
                echo "Use 'mac awake --help' for usage information"
                exit 1
                ;;
        esac
    done
    
    # Check if already running
    if is_running; then
        print_warning "Mac awake mode is already running"
        print_info "Use 'mac awake --stop' to stop it first"
        exit 1
    fi
    
    # Start keeping awake
    keep_awake
}

# Set trap for cleanup only on interrupt/term, not on normal exit
trap cleanup INT TERM

# Run main function if script is executed directly

# Plugin main entry point
plugin_main() {
    # Call the main function with all arguments
    main "$@"
}

# Initialize the plugin
plugin_init

# Call the main function if not sourced
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    plugin_main "$@"
fi
