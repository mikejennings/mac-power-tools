#!/bin/bash

# Mac Power Tools - Memory Optimizer
# Monitor and optimize system memory usage

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Settings
CONTINUOUS=false
INTERVAL=5
THRESHOLD=80

# Function to print colored output
print_color() {
    local color=$1
    shift
    printf "${color}%s${NC}\n" "$*"
}

# Function to format bytes
format_bytes() {
    local bytes=$1
    
    if [[ $bytes -ge 1073741824 ]]; then
        printf "%.1f GB" $(echo "scale=1; $bytes / 1073741824" | bc)
    elif [[ $bytes -ge 1048576 ]]; then
        printf "%.1f MB" $(echo "scale=1; $bytes / 1048576" | bc)
    elif [[ $bytes -ge 1024 ]]; then
        printf "%.1f KB" $(echo "scale=1; $bytes / 1024" | bc)
    else
        echo "$bytes bytes"
    fi
}

# Function to get memory info
get_memory_info() {
    local vm_stat_output=$(vm_stat)
    local page_size=$(vm_stat | grep "page size" | awk '{print $8}')
    
    # Parse vm_stat output
    local pages_free=$(echo "$vm_stat_output" | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
    local pages_active=$(echo "$vm_stat_output" | grep "Pages active" | awk '{print $3}' | sed 's/\.//')
    local pages_inactive=$(echo "$vm_stat_output" | grep "Pages inactive" | awk '{print $3}' | sed 's/\.//')
    local pages_wired=$(echo "$vm_stat_output" | grep "Pages wired" | awk '{print $4}' | sed 's/\.//')
    local pages_compressed=$(echo "$vm_stat_output" | grep "Pages occupied by compressor" | awk '{print $5}' | sed 's/\.//')
    local pages_purgeable=$(echo "$vm_stat_output" | grep "Pages purgeable" | awk '{print $3}' | sed 's/\.//')
    local pages_cached=$(echo "$vm_stat_output" | grep "File-backed pages" | awk '{print $3}' | sed 's/\.//')
    
    # Calculate memory in bytes
    MEMORY_FREE=$((pages_free * page_size))
    MEMORY_ACTIVE=$((pages_active * page_size))
    MEMORY_INACTIVE=$((pages_inactive * page_size))
    MEMORY_WIRED=$((pages_wired * page_size))
    MEMORY_COMPRESSED=$((pages_compressed * page_size))
    MEMORY_PURGEABLE=$((pages_purgeable * page_size))
    MEMORY_CACHED=$((pages_cached * page_size))
    
    # Get total memory
    MEMORY_TOTAL=$(sysctl -n hw.memsize)
    
    # Calculate used memory
    MEMORY_USED=$((MEMORY_WIRED + MEMORY_ACTIVE + MEMORY_INACTIVE + MEMORY_COMPRESSED))
    
    # Calculate available memory (free + inactive + purgeable)
    MEMORY_AVAILABLE=$((MEMORY_FREE + MEMORY_INACTIVE + MEMORY_PURGEABLE))
    
    # Calculate memory pressure
    MEMORY_PRESSURE=$(echo "scale=1; 100 - ($MEMORY_AVAILABLE * 100 / $MEMORY_TOTAL)" | bc)
    
    # Get swap usage
    local swap_output=$(sysctl vm.swapusage)
    SWAP_TOTAL=$(echo "$swap_output" | awk '{print $4}' | sed 's/M//')
    SWAP_USED=$(echo "$swap_output" | awk '{print $7}' | sed 's/M//')
    SWAP_FREE=$(echo "$swap_output" | awk '{print $10}' | sed 's/M//')
}

# Function to display memory info
display_memory_info() {
    get_memory_info
    
    print_color "$BLUE" "═══════════════════════════════════════════"
    print_color "$BLUE" "Memory Status"
    print_color "$BLUE" "═══════════════════════════════════════════"
    
    # Total and available
    printf "Total Memory:     %s\n" "$(format_bytes $MEMORY_TOTAL)"
    printf "Available:        %s\n" "$(format_bytes $MEMORY_AVAILABLE)"
    printf "Used:             %s\n" "$(format_bytes $MEMORY_USED)"
    
    # Memory pressure with color coding
    printf "Memory Pressure:  "
    if (( $(echo "$MEMORY_PRESSURE < 50" | bc -l) )); then
        print_color "$GREEN" "${MEMORY_PRESSURE}% (Low)"
    elif (( $(echo "$MEMORY_PRESSURE < 75" | bc -l) )); then
        print_color "$YELLOW" "${MEMORY_PRESSURE}% (Medium)"
    else
        print_color "$RED" "${MEMORY_PRESSURE}% (High)"
    fi
    
    print_color "$BLUE" "\n━━━ Memory Breakdown ━━━"
    printf "Wired (locked):   %s\n" "$(format_bytes $MEMORY_WIRED)"
    printf "Active:           %s\n" "$(format_bytes $MEMORY_ACTIVE)"
    printf "Inactive:         %s\n" "$(format_bytes $MEMORY_INACTIVE)"
    printf "Compressed:       %s\n" "$(format_bytes $MEMORY_COMPRESSED)"
    printf "Purgeable:        %s\n" "$(format_bytes $MEMORY_PURGEABLE)"
    printf "Free:             %s\n" "$(format_bytes $MEMORY_FREE)"
    
    print_color "$BLUE" "\n━━━ Swap Usage ━━━"
    printf "Swap Total:       %s MB\n" "$SWAP_TOTAL"
    printf "Swap Used:        %s MB\n" "$SWAP_USED"
    printf "Swap Free:        %s MB\n" "$SWAP_FREE"
}

# Function to get top memory consumers
get_top_memory_apps() {
    local count=${1:-10}
    
    print_color "$BLUE" "\n━━━ Top $count Memory Consumers ━━━"
    
    ps aux | awk 'NR>1 {printf "%-8s %-6s %-6s %s\n", $1, $3, $4, $11}' | \
        sort -rnk 3 | head -n "$count" | \
        awk 'BEGIN {printf "%-15s %-8s %-8s %s\n", "USER", "CPU%", "MEM%", "COMMAND"} 
             {printf "%-15s %-8s %-8s %s\n", $1, $2, $3, $4}'
}

# Function to purge memory
purge_memory() {
    print_color "$YELLOW" "\n⚡ Purging inactive memory..."
    
    # Check current memory before purge
    get_memory_info
    local before_available=$MEMORY_AVAILABLE
    
    # Run purge command
    if sudo purge 2>/dev/null; then
        sleep 2
        
        # Check memory after purge
        get_memory_info
        local after_available=$MEMORY_AVAILABLE
        local freed=$((after_available - before_available))
        
        if [[ $freed -gt 0 ]]; then
            print_color "$GREEN" "✓ Successfully purged $(format_bytes $freed) of memory"
        else
            print_color "$GREEN" "✓ Memory purged (already optimized)"
        fi
    else
        print_color "$RED" "✗ Failed to purge memory (requires admin password)"
    fi
}

# Function to kill memory hogs
kill_memory_hogs() {
    local threshold=${1:-10}
    
    print_color "$YELLOW" "\n🎯 Finding processes using more than ${threshold}% memory..."
    
    local hogs=$(ps aux | awk -v threshold="$threshold" '$4 > threshold {print $2, $4, $11}' | \
                 grep -v "PID" | sort -rnk 2)
    
    if [[ -z "$hogs" ]]; then
        print_color "$GREEN" "✓ No processes using more than ${threshold}% memory"
        return
    fi
    
    print_color "$YELLOW" "Found memory-intensive processes:"
    echo "$hogs" | while read pid mem cmd; do
        printf "  PID: %-8s MEM: %5s%%  CMD: %s\n" "$pid" "$mem" "$cmd"
    done
    
    read -p "Kill these processes? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "$hogs" | while read pid mem cmd; do
            if kill -9 "$pid" 2>/dev/null; then
                print_color "$GREEN" "  ✓ Killed: $cmd (PID: $pid)"
            else
                print_color "$RED" "  ✗ Failed to kill: $cmd (PID: $pid)"
            fi
        done
    fi
}

# Function to optimize memory
optimize_memory() {
    print_color "$BLUE" "═══════════════════════════════════════════"
    print_color "$BLUE" "Memory Optimization"
    print_color "$BLUE" "═══════════════════════════════════════════"
    
    # Get current status
    get_memory_info
    
    print_color "$CYAN" "\nCurrent memory pressure: ${MEMORY_PRESSURE}%"
    
    # Optimization steps
    print_color "$YELLOW" "\n1. Closing unused applications..."
    
    # Close apps that haven't been used recently
    local inactive_apps=$(osascript -e 'tell application "System Events" to get name of every process whose background only is true' 2>/dev/null)
    
    if [[ -n "$inactive_apps" ]]; then
        echo "$inactive_apps" | tr ',' '\n' | while read -r app; do
            app=$(echo "$app" | xargs)
            if [[ -n "$app" ]]; then
                osascript -e "tell application \"$app\" to quit" 2>/dev/null && \
                    print_color "$GREEN" "  ✓ Closed: $app"
            fi
        done
    fi
    
    print_color "$YELLOW" "\n2. Purging inactive memory..."
    purge_memory
    
    print_color "$YELLOW" "\n3. Clearing caches..."
    # Clear user cache safely
    rm -rf "$HOME/Library/Caches/"* 2>/dev/null
    print_color "$GREEN" "  ✓ Cleared user caches"
    
    # Final status
    get_memory_info
    print_color "$GREEN" "\n✓ Optimization complete!"
    print_color "$CYAN" "New memory pressure: ${MEMORY_PRESSURE}%"
    
    local freed=$((before_available - MEMORY_AVAILABLE))
    if [[ $freed -gt 0 ]]; then
        print_color "$GREEN" "Total memory freed: $(format_bytes $freed)"
    fi
}

# Function to monitor memory continuously
monitor_memory() {
    local interval=${1:-5}
    
    print_color "$BLUE" "Memory Monitor (updating every ${interval}s, Ctrl+C to stop)"
    print_color "$BLUE" "═══════════════════════════════════════════"
    
    while true; do
        clear
        display_memory_info
        get_top_memory_apps 5
        
        # Alert if memory pressure is high
        if (( $(echo "$MEMORY_PRESSURE > $THRESHOLD" | bc -l) )); then
            print_color "$RED" "\n⚠️  HIGH MEMORY PRESSURE DETECTED!"
            print_color "$YELLOW" "Run 'mac memory --optimize' to free up memory"
        fi
        
        sleep "$interval"
    done
}

# Function to show memory-related system info
show_system_memory_info() {
    print_color "$BLUE" "═══════════════════════════════════════════"
    print_color "$BLUE" "System Memory Information"
    print_color "$BLUE" "═══════════════════════════════════════════"
    
    # Hardware info
    local hw_memsize=$(sysctl -n hw.memsize)
    local hw_pagesize=$(sysctl -n hw.pagesize)
    local vm_page_free_target=$(sysctl -n vm.page_free_target)
    
    printf "Physical Memory:  %s\n" "$(format_bytes $hw_memsize)"
    printf "Page Size:        %s bytes\n" "$hw_pagesize"
    printf "Free Target:      %s pages\n" "$vm_page_free_target"
    
    # Memory limits
    print_color "$BLUE" "\n━━━ Process Limits ━━━"
    ulimit -a | grep -E "memory|data|stack"
}

# Show help
show_help() {
    cat << EOF
Mac Power Tools - Memory Optimizer

USAGE:
    mac memory [OPTIONS]
    mac memory --optimize

OPTIONS:
    -h, --help          Show this help message
    -o, --optimize      Optimize memory usage
    -p, --purge         Purge inactive memory
    -m, --monitor       Monitor memory continuously
    -i, --interval SEC  Update interval for monitoring (default: 5)
    -t, --top [N]       Show top N memory consumers (default: 10)
    -k, --kill [N]      Kill processes using >N% memory (default: 10%)
    -s, --system        Show system memory information
    --threshold N       Alert threshold for monitor mode (default: 80%)

EXAMPLES:
    mac memory                  # Show current memory status
    mac memory --optimize       # Optimize memory usage
    mac memory --monitor        # Monitor memory in real-time
    mac memory --top 20         # Show top 20 memory consumers
    mac memory --kill 15        # Kill processes using >15% memory
    mac memory -m -i 2          # Monitor with 2-second updates

NOTES:
    • Purging memory requires administrator password
    • Optimization closes background apps and clears caches
    • Monitor mode shows real-time memory usage
    • High memory pressure triggers automatic alerts

EOF
}

# Main function
main() {
    local action="status"
    local top_count=10
    local kill_threshold=10
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -o|--optimize)
                action="optimize"
                shift
                ;;
            -p|--purge)
                action="purge"
                shift
                ;;
            -m|--monitor)
                action="monitor"
                CONTINUOUS=true
                shift
                ;;
            -i|--interval)
                INTERVAL="$2"
                shift 2
                ;;
            -t|--top)
                action="top"
                if [[ "$2" =~ ^[0-9]+$ ]]; then
                    top_count="$2"
                    shift
                fi
                shift
                ;;
            -k|--kill)
                action="kill"
                if [[ "$2" =~ ^[0-9]+$ ]]; then
                    kill_threshold="$2"
                    shift
                fi
                shift
                ;;
            -s|--system)
                action="system"
                shift
                ;;
            --threshold)
                THRESHOLD="$2"
                shift 2
                ;;
            *)
                print_color "$RED" "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Execute action
    case $action in
        status)
            display_memory_info
            get_top_memory_apps
            ;;
        optimize)
            optimize_memory
            ;;
        purge)
            purge_memory
            ;;
        monitor)
            monitor_memory "$INTERVAL"
            ;;
        top)
            get_top_memory_apps "$top_count"
            ;;
        kill)
            kill_memory_hogs "$kill_threshold"
            ;;
        system)
            show_system_memory_info
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi