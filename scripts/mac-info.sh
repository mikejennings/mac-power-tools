#!/bin/bash

# Mac Info Script - System information and monitoring
# Replaces mac-cli system info functionality

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Function to print section headers
print_header() {
    echo
    echo -e "${BLUE}═══ $1 ═══${NC}"
}

# Function to print info line
print_info() {
    echo -e "${CYAN}$1:${NC} $2"
}

# System information
show_system_info() {
    print_header "System Information"
    
    # macOS version
    os_version=$(sw_vers -productVersion)
    os_build=$(sw_vers -buildVersion)
    print_info "macOS Version" "$os_version ($os_build)"
    
    # Computer name
    computer_name=$(scutil --get ComputerName)
    print_info "Computer Name" "$computer_name"
    
    # Model
    model=$(system_profiler SPHardwareDataType | grep "Model Name" | cut -d: -f2 | xargs)
    print_info "Model" "$model"
    
    # Processor
    processor=$(sysctl -n machdep.cpu.brand_string)
    print_info "Processor" "$processor"
    
    # Number of cores
    cores=$(sysctl -n hw.ncpu)
    print_info "CPU Cores" "$cores"
    
    # Uptime
    uptime_str=$(uptime | sed 's/.*up //' | sed 's/, [0-9]* users.*//')
    print_info "Uptime" "$uptime_str"
}

# Memory information
show_memory_info() {
    print_header "Memory Information"
    
    # Total memory
    total_mem=$(sysctl -n hw.memsize)
    total_gb=$((total_mem / 1073741824))
    print_info "Total Memory" "${total_gb} GB"
    
    # Memory pressure
    vm_stat=$(vm_stat)
    pages_free=$(echo "$vm_stat" | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
    pages_active=$(echo "$vm_stat" | grep "Pages active" | awk '{print $3}' | sed 's/\.//')
    pages_inactive=$(echo "$vm_stat" | grep "Pages inactive" | awk '{print $3}' | sed 's/\.//')
    pages_wired=$(echo "$vm_stat" | grep "Pages wired" | awk '{print $4}' | sed 's/\.//')
    pages_compressed=$(echo "$vm_stat" | grep "Pages occupied by compressor" | awk '{print $5}' | sed 's/\.//')
    
    # Calculate memory in MB (page size is 4096 bytes)
    free_mb=$((pages_free * 4096 / 1048576))
    active_mb=$((pages_active * 4096 / 1048576))
    inactive_mb=$((pages_inactive * 4096 / 1048576))
    wired_mb=$((pages_wired * 4096 / 1048576))
    compressed_mb=$((pages_compressed * 4096 / 1048576))
    
    used_mb=$((active_mb + wired_mb + compressed_mb))
    
    print_info "Memory Used" "$(printf "%.1f GB" $(echo "scale=1; $used_mb / 1024" | bc))"
    print_info "Memory Free" "$(printf "%.1f GB" $(echo "scale=1; $free_mb / 1024" | bc))"
    print_info "Memory Wired" "$(printf "%.1f GB" $(echo "scale=1; $wired_mb / 1024" | bc))"
    print_info "Memory Compressed" "$(printf "%.1f GB" $(echo "scale=1; $compressed_mb / 1024" | bc))"
    
    # Swap usage
    swap_usage=$(sysctl vm.swapusage | awk '{print $4, $7, $10}' | sed 's/M//g')
    print_info "Swap Usage" "$swap_usage"
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
    wifi_network=$(/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I | grep " SSID" | cut -d: -f2 | xargs)
    if [ -n "$wifi_network" ]; then
        print_info "Wi-Fi Network" "$wifi_network"
    fi
    
    # IP addresses
    print_info "Local IP" "$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo 'Not connected')"
    
    # Public IP (optional, requires internet)
    if ping -c 1 google.com &> /dev/null; then
        public_ip=$(curl -s ifconfig.me 2>/dev/null || echo "Unable to determine")
        print_info "Public IP" "$public_ip"
    fi
    
    # Active network interfaces
    echo
    echo -e "${YELLOW}Active Network Interfaces:${NC}"
    ifconfig | grep "^[a-z]" | cut -d: -f1 | while read interface; do
        status=$(ifconfig "$interface" | grep "status:" | awk '{print $2}')
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
        battery_percent=$(pmset -g batt | grep -o "[0-9]*%" | head -1)
        print_info "Battery Level" "$battery_percent"
        
        # Power source
        power_source=$(pmset -g batt | head -1 | cut -d"'" -f2)
        print_info "Power Source" "$power_source"
        
        # Battery condition
        condition=$(system_profiler SPPowerDataType | grep "Condition" | head -1 | cut -d: -f2 | xargs)
        print_info "Battery Condition" "$condition"
        
        # Cycle count
        cycle_count=$(system_profiler SPPowerDataType | grep "Cycle Count" | cut -d: -f2 | xargs)
        print_info "Cycle Count" "$cycle_count"
    fi
}

# Temperature sensors (requires osx-cpu-temp)
show_temperature_info() {
    if command -v osx-cpu-temp &> /dev/null; then
        print_header "Temperature Information"
        
        cpu_temp=$(osx-cpu-temp)
        print_info "CPU Temperature" "$cpu_temp"
    elif command -v istats &> /dev/null; then
        print_header "Temperature Information"
        istats
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

# Main function
main() {
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
                    echo -e "${RED}Unknown option: $arg${NC}"
                    echo "Available options: system, memory, disk, network, battery, temp, cpu"
                    exit 1
                    ;;
            esac
        done
    fi
    
    echo
}

# Run main function
main "$@"