#!/bin/bash

# Mac Info Plugin - Native implementation
# System information and monitoring

# Source the plugin API
source "${MAC_POWER_TOOLS_HOME}/lib/plugin-api.sh"

# Function to print section headers
print_header() {
    echo
    echo -e "${BLUE}═══ $1 ═══${NC}"
}

# Function to print info line with custom formatting
print_info_line() {
    echo -e "${CYAN}$1:${NC} $2"
}

# Function to print info using plugin API
print_info_item() {
    printf "${CYAN}%-20s${NC} %s\n" "$1:" "$2"
}

# System information
show_system_info() {
    print_header "System Information"
    
    # macOS version
    local os_version=$(sw_vers -productVersion)
    local os_build=$(sw_vers -buildVersion)
    print_info_line "macOS Version" "$os_version ($os_build)"
    
    # Computer name
    local computer_name=$(scutil --get ComputerName)
    print_info_line "Computer Name" "$computer_name"
    
    # Model
    local model=$(system_profiler SPHardwareDataType | grep "Model Name" | cut -d: -f2 | xargs)
    print_info_line "Model" "$model"
    
    # Processor
    local processor=$(sysctl -n machdep.cpu.brand_string)
    print_info_line "Processor" "$processor"
    
    # Number of cores
    local cores=$(sysctl -n hw.ncpu)
    print_info_line "CPU Cores" "$cores"
    
    # Uptime
    local uptime_str=$(uptime | sed 's/.*up //' | sed 's/, [0-9]* users.*//')
    print_info_line "Uptime" "$uptime_str"
}

# Memory information
show_memory_info() {
    print_header "Memory Information"
    
    # Total memory
    local total_mem=$(sysctl -n hw.memsize)
    local total_gb=$((total_mem / 1073741824))
    print_info_line "Total Memory" "${total_gb} GB"
    
    # Memory pressure
    local vm_stat=$(vm_stat)
    local pages_free=$(echo "$vm_stat" | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
    local pages_active=$(echo "$vm_stat" | grep "Pages active" | awk '{print $3}' | sed 's/\.//')
    local pages_inactive=$(echo "$vm_stat" | grep "Pages inactive" | awk '{print $3}' | sed 's/\.//')
    local pages_wired=$(echo "$vm_stat" | grep "Pages wired" | awk '{print $4}' | sed 's/\.//')
    local pages_compressed=$(echo "$vm_stat" | grep "Pages occupied by compressor" | awk '{print $5}' | sed 's/\.//')
    
    # Calculate memory in MB (page size is 4096 bytes)
    local free_mb=$((pages_free * 4096 / 1048576))
    local active_mb=$((pages_active * 4096 / 1048576))
    local inactive_mb=$((pages_inactive * 4096 / 1048576))
    local wired_mb=$((pages_wired * 4096 / 1048576))
    local compressed_mb=$((pages_compressed * 4096 / 1048576))
    
    local used_mb=$((active_mb + wired_mb + compressed_mb))
    
    # Use awk for decimal calculations to avoid bc dependency
    print_info_line "Memory Used" "$(awk -v mem="$used_mb" 'BEGIN {printf "%.1f GB", mem / 1024}')"
    print_info_line "Memory Free" "$(awk -v mem="$free_mb" 'BEGIN {printf "%.1f GB", mem / 1024}')"
    print_info_line "Memory Wired" "$(awk -v mem="$wired_mb" 'BEGIN {printf "%.1f GB", mem / 1024}')"
    print_info_line "Memory Compressed" "$(awk -v mem="$compressed_mb" 'BEGIN {printf "%.1f GB", mem / 1024}')"
    
    # Swap usage
    local swap_usage=$(sysctl vm.swapusage | awk '{print $4, $7, $10}' | sed 's/M//g')
    print_info_line "Swap Usage" "$swap_usage"
}

# Disk information
show_disk_info() {
    print_header "Disk Information"
    
    # Main disk usage
    df -h / | tail -1 | awk '{print "Disk Total: " $2 ", Used: " $3 " (" $5 "), Available: " $4}' | while read line; do
        echo -e "${CYAN}$line${NC}"
    done
    
    echo
    echo -e "${YELLOW}All Mounted Volumes:${NC}"
    df -h | grep -v "^devfs\|^map" | awk 'NR==1 {print $1, $2, $3, $4, $5, $9} NR>1 {print $1, $2, $3, $4, $5, $9}' | column -t
}

# Network information
show_network_info() {
    print_header "Network Information"
    
    # Current Wi-Fi network
    local wifi_network=$(/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I | grep " SSID" | cut -d: -f2 | xargs)
    if [ -n "$wifi_network" ]; then
        print_info_line "Wi-Fi Network" "$wifi_network"
    fi
    
    # IP addresses
    local local_ip=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo 'Not connected')
    print_info_line "Local IP" "$local_ip"
    
    # Public IP (optional, requires internet)
    if ping -c 1 google.com &> /dev/null; then
        local public_ip=$(curl -s ifconfig.me 2>/dev/null || echo "Unable to determine")
        print_info_line "Public IP" "$public_ip"
    fi
    
    # Active network interfaces
    echo
    echo -e "${YELLOW}Active Network Interfaces:${NC}"
    ifconfig | grep "^[a-z]" | cut -d: -f1 | while read interface; do
        local status=$(ifconfig "$interface" | grep "status:" | awk '{print $2}')
        if [ "$status" = "active" ]; then
            echo -e "  ${GREEN}✓${NC} $interface"
        fi
    done
}

# Battery information (for laptops)
show_battery_info() {
    if system_profiler SPPowerDataType | grep -q "Battery Information"; then
        print_header "Battery Information"
        
        # Battery percentage
        local battery_percent=$(pmset -g batt | grep -o "[0-9]*%" | head -1)
        print_info_line "Battery Level" "$battery_percent"
        
        # Power source
        local power_source=$(pmset -g batt | head -1 | cut -d"'" -f2)
        print_info_line "Power Source" "$power_source"
        
        # Battery condition
        local condition=$(system_profiler SPPowerDataType | grep "Condition" | head -1 | cut -d: -f2 | xargs)
        print_info_line "Battery Condition" "$condition"
        
        # Cycle count
        local cycle_count=$(system_profiler SPPowerDataType | grep "Cycle Count" | cut -d: -f2 | xargs)
        print_info_line "Cycle Count" "$cycle_count"
    fi
}

# Temperature sensors (requires osx-cpu-temp or istats)
show_temperature_info() {
    if command_exists osx-cpu-temp; then
        print_header "Temperature Information"
        
        local cpu_temp=$(osx-cpu-temp)
        print_info_line "CPU Temperature" "$cpu_temp"
    elif command_exists istats; then
        print_header "Temperature Information"
        istats
    else
        print_warning "Temperature monitoring requires 'osx-cpu-temp' or 'istats' to be installed"
        echo "Install with: brew install osx-cpu-temp  # or brew install iStats"
    fi
}

# Top processes by CPU
show_top_processes_cpu() {
    print_header "Top Processes by CPU"
    ps aux | head -1
    ps aux | sort -nrk 3,3 | head -6 | tail -5
}

# Top processes by Memory
show_top_processes_memory() {
    print_header "Top Processes by Memory"
    ps aux | head -1
    ps aux | sort -nrk 4,4 | head -6 | tail -5
}

# Plugin main entry point
plugin_main() {
    echo "==================================="
    echo "      Mac System Information       "
    echo "==================================="
    
    if [ $# -eq 0 ]; then
        # Show all information
        show_system_info
        show_memory_info
        show_disk_info
        show_network_info
        show_battery_info
        show_temperature_info
        show_top_processes_cpu
        show_top_processes_memory
    else
        # Show specific information based on arguments
        for arg in "$@"; do
            case $arg in
                system)
                    show_system_info
                    ;;
                memory|mem)
                    show_memory_info
                    show_top_processes_memory
                    ;;
                disk)
                    show_disk_info
                    ;;
                network|net)
                    show_network_info
                    ;;
                battery|power)
                    show_battery_info
                    ;;
                temp|temperature)
                    show_temperature_info
                    ;;
                cpu)
                    show_top_processes_cpu
                    ;;
                *)
                    print_error "Unknown option: $arg"
                    echo "Available options: system, memory, disk, network, battery, temp, cpu"
                    echo "Usage: mac info [option1] [option2] ..."
                    echo "       mac info           # Show all information"
                    ;;  # Don't return 1 here, just show help and continue
            esac
        done
    fi
    
    echo
}

# Initialize the plugin
plugin_init

# Call the main function if not sourced
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    plugin_main "$@"
fi
