#!/bin/bash

# Native plugin implementation
# Migrated from legacy script to use plugin API

# Source the plugin API
source "${MAC_POWER_TOOLS_HOME}/lib/plugin-api.sh"




# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Battery history file
BATTERY_HISTORY_FILE="$HOME/.mac-power-tools/battery-history.csv"

show_battery_help() {
    echo "Usage: mac battery [command]"
    echo ""
    echo "Advanced battery management and monitoring"
    echo ""
    echo "Commands:"
    echo "  health          Show battery health, cycles, and capacity"
    echo "  status          Detailed battery status and power usage"
    echo "  calibrate       Battery calibration wizard"
    echo "  history         Show battery degradation over time"
    echo "  optimize        Set charging limits for battery longevity"
    echo "  apps            Show battery usage by application"
    echo "  monitor         Real-time battery monitoring"
    echo "  tips            Battery optimization tips"
    echo ""
}

battery_health() {
    print_info "🔋 Battery Health Report"
    echo ""
    
    # Get battery information using system_profiler
    battery_info=$(system_profiler SPPowerDataType 2>/dev/null)
    
    if [ -z "$battery_info" ]; then
        print_error "Unable to retrieve battery information"
        return 1
    fi
    
    # Extract key metrics
    cycle_count=$(echo "$battery_info" | grep "Cycle Count" | awk '{print $3}')
    condition=$(echo "$battery_info" | grep "Condition" | awk '{print $2}')
    max_capacity=$(echo "$battery_info" | grep "Maximum Capacity" | awk '{print $3}')
    full_charge=$(echo "$battery_info" | grep "Full Charge Capacity" | sed 's/.*: *//')
    design_capacity=$(echo "$battery_info" | grep "Design Capacity" | sed 's/.*: *//')
    
    # Get current charge
    current_charge=$(pmset -g batt | grep -o '[0-9]*%' | tr -d '%')
    charging_status=$(pmset -g batt | grep -o 'AC\|Battery\|charged')
    
    # Calculate health percentage if possible
    if [[ -n "$full_charge" ]] && [[ -n "$design_capacity" ]]; then
        # Remove mAh suffix and calculate
        full_num=${full_charge% *}
        design_num=${design_capacity% *}
        if [[ "$design_num" -gt 0 ]]; then
            health_percent=$((full_num * 100 / design_num))
        else
            health_percent="N/A"
        fi
    else
        health_percent="${max_capacity%\%}"
    fi
    
    # Display health status
    print_info "Battery Condition:"
    if [ "$condition" = "Normal" ]; then
        echo -e "  Status: ${GREEN}✓ $condition"
    elif [ "$condition" = "Service Battery" ]; then
        echo -e "  Status: ${RED}⚠ $condition"
    else
        echo -e "  Status: ${YELLOW}$condition"
    fi
    echo ""
    
    print_info "Battery Capacity:"
    if [ -n "$health_percent" ] && [ "$health_percent" != "N/A" ]; then
        if [ "$health_percent" -ge 80 ]; then
            echo -e "  Health: ${GREEN}${health_percent}%"
        elif [ "$health_percent" -ge 60 ]; then
            echo -e "  Health: ${YELLOW}${health_percent}%"
        else
            echo -e "  Health: ${RED}${health_percent}%"
        fi
    fi
    
    if [ -n "$full_charge" ]; then
        echo "  Current Max: $full_charge"
    fi
    if [ -n "$design_capacity" ]; then
        echo "  Original: $design_capacity"
    fi
    echo ""
    
    print_info "Cycle Information:"
    if [ -n "$cycle_count" ]; then
        echo -e "  Cycle Count: ${CYAN}$cycle_count"
        
        # Estimate based on typical MacBook battery (1000 cycles)
        if [ "$cycle_count" -lt 300 ]; then
            echo -e "  Cycle Status: ${GREEN}Low usage"
        elif [ "$cycle_count" -lt 700 ]; then
            echo -e "  Cycle Status: ${YELLOW}Moderate usage"
        elif [ "$cycle_count" -lt 1000 ]; then
            echo -e "  Cycle Status: ${YELLOW}High usage"
        else
            echo -e "  Cycle Status: ${RED}Very high usage"
        fi
    fi
    echo ""
    
    print_info "Current Status:"
    echo "  Charge Level: ${current_charge}%"
    echo "  Power Source: $charging_status"
    
    # Get time remaining if on battery
    if [[ "$charging_status" == "Battery" ]]; then
        time_remaining=$(pmset -g batt | grep -o '[0-9]*:[0-9]*' | head -1)
        if [ -n "$time_remaining" ]; then
            echo "  Time Remaining: $time_remaining"
        fi
    elif [[ "$charging_status" == "AC" ]]; then
        echo "  Status: Charging"
    fi
    
    # Save to history
    save_battery_history "$health_percent" "$cycle_count"
}

battery_status() {
    print_info "⚡ Battery Status & Power Usage"
    echo ""
    
    # Current battery status
    battery_status=$(pmset -g batt)
    print_info "Current Status:"
    echo "$battery_status" | tail -1
    echo ""
    
    # Power assertions (what's keeping the system awake)
    print_info "Power Assertions:"
    pmset -g assertions | grep -E "PreventUserIdleSystemSleep|PreventSystemSleep" | head -5 | while read -r line; do
        if [[ "$line" == *"1"* ]]; then
            echo "  • $line"
        fi
    done
    echo ""
    
    # Thermal state
    print_info "Thermal State:"
    thermal_state=$(pmset -g therm | tail -1)
    echo "  $thermal_state"
    echo ""
    
    # Power settings
    print_info "Power Settings:"
    echo "  Display sleep: $(pmset -g | grep displaysleep | awk '{print $2}') minutes"
    echo "  System sleep: $(pmset -g | grep "^[[:space:]]*sleep" | awk '{print $2}') minutes"
    echo "  Disk sleep: $(pmset -g | grep disksleep | awk '{print $2}') minutes"
    
    # Check if optimized charging is enabled
    optimized=$(pmset -g | grep "optimized" 2>/dev/null)
    if [ -n "$optimized" ]; then
        echo ""
        print_info "Optimized Charging:"
        echo "  $optimized"
    fi
}

battery_calibrate() {
    print_info "🔧 Battery Calibration Wizard"
    echo ""
    echo "Battery calibration helps maintain accurate battery readings."
    echo ""
    print_warning "⚠ This process will take several hours."
    echo ""
    echo "Steps to calibrate your battery:"
    echo ""
    print_info "1. Charge to 100%"
    echo "   • Plug in your charger"
    echo "   • Keep charging for 2 hours after reaching 100%"
    echo ""
    print_info "2. Drain the battery"
    echo "   • Unplug the charger"
    echo "   • Use your Mac normally until it shuts down"
    echo "   • Leave it off for at least 5 hours"
    echo ""
    print_info "3. Recharge fully"
    echo "   • Plug in and charge to 100% without interruption"
    echo "   • Keep plugged in for 2 more hours"
    echo ""
    
    read -p "Start calibration assistant? (y/N): " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        current_charge=$(pmset -g batt | grep -o '[0-9]*%' | tr -d '%')
        
        if [ "$current_charge" -lt 100 ]; then
            print_warning "Current charge: ${current_charge}%"
            echo "Please plug in your charger and charge to 100%."
            echo ""
            echo "Run 'mac battery calibrate' again when fully charged."
        else
            print_success "Battery is at ${current_charge}%"
            echo "Keep charging for 2 more hours, then unplug and use normally."
            echo ""
            echo "Calibration reminder has been set."
            
            # Set a reminder (using notification if possible)
            if command -v osascript &> /dev/null; then
                (sleep 7200 && osascript -e 'display notification "Time to unplug and drain battery" with title "Battery Calibration"') &
            fi
        fi
    fi
}

battery_history() {
    print_info "📈 Battery Health History"
    echo ""
    
    # Ensure history file exists
    mkdir -p "$(dirname "$BATTERY_HISTORY_FILE")"
    
    if [ ! -f "$BATTERY_HISTORY_FILE" ] || [ ! -s "$BATTERY_HISTORY_FILE" ]; then
        echo "No history data available yet."
        echo "History will be recorded with each health check."
        return
    fi
    
    print_info "Recent Battery Health:"
    echo ""
    echo "Date                 Health  Cycles"
    echo "------------------------------------"
    tail -20 "$BATTERY_HISTORY_FILE" | while IFS=',' read -r date health cycles; do
        if [ -n "$health" ] && [ "$health" != "N/A" ]; then
            if [ "$health" -ge 80 ]; then
                health_color=$GREEN
            elif [ "$health" -ge 60 ]; then
                health_color=$YELLOW
            else
                health_color=$RED
            fi
            printf "%-20s ${health_color}%3s%%${NC}   %s\n" "$date" "$health" "$cycles"
        else
            printf "%-20s %3s%%   %s\n" "$date" "$health" "$cycles"
        fi
    done
    
    echo ""
    
    # Calculate degradation rate if enough data
    line_count=$(wc -l < "$BATTERY_HISTORY_FILE")
    if [ "$line_count" -ge 2 ]; then
        first_entry=$(head -1 "$BATTERY_HISTORY_FILE")
        last_entry=$(tail -1 "$BATTERY_HISTORY_FILE")
        
        first_health=$(echo "$first_entry" | cut -d',' -f2)
        last_health=$(echo "$last_entry" | cut -d',' -f2)
        
        if [[ "$first_health" =~ ^[0-9]+$ ]] && [[ "$last_health" =~ ^[0-9]+$ ]]; then
            degradation=$((first_health - last_health))
            if [ "$degradation" -gt 0 ]; then
                print_warning "Total degradation: ${degradation}%"
            fi
        fi
    fi
}

battery_optimize() {
    print_info "⚙️  Battery Optimization Settings"
    echo ""
    
    echo "Current optimization settings:"
    echo ""
    
    # Check if optimized battery charging is available (macOS 10.15.5+)
    if pmset -g | grep -q "optimizedbatterycharging"; then
        current_setting=$(pmset -g | grep "optimizedbatterycharging" | awk '{print $2}')
        if [ "$current_setting" = "1" ]; then
            echo -e "  Optimized Charging: ${GREEN}✓ Enabled"
        else
            echo -e "  Optimized Charging: ${RED}✗ Disabled"
        fi
    else
        echo -e "  Optimized Charging: ${YELLOW}Not available (requires macOS 10.15.5+)"
    fi
    echo ""
    
    print_info "Recommended Settings:"
    echo ""
    echo "1. Enable Optimized Battery Charging:"
    echo "   System Preferences > Battery > Battery > Optimized battery charging"
    echo ""
    echo "2. Reduce Energy Usage:"
    echo "   • Enable automatic graphics switching"
    echo "   • Reduce screen brightness when possible"
    echo "   • Quit unused applications"
    echo ""
    echo "3. Power Adapter Settings:"
    echo "   • Avoid keeping plugged in 24/7"
    echo "   • Ideal charge range: 20% - 80%"
    echo ""
    
    read -p "Apply recommended power settings? (y/N): " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "Applying optimizations..."
        
        # Enable power nap on battery
        sudo pmset -b powernap 0
        echo "  • Disabled Power Nap on battery"
        
        # Reduce display sleep time on battery
        sudo pmset -b displaysleep 5
        echo "  • Set display sleep to 5 minutes on battery"
        
        # Enable automatic graphics switching if available
        if pmset -g | grep -q "gpuswitch"; then
            sudo pmset -a gpuswitch 2
            echo "  • Enabled automatic graphics switching"
        fi
        
        echo ""
        print_success "✓ Optimizations applied"
    fi
}

battery_apps() {
    print_info "📱 Battery Usage by Application"
    echo ""
    
    echo "Analyzing application energy impact..."
    echo ""
    
    # Get current energy impact from Activity Monitor data
    # Using top command to get CPU usage as proxy for energy
    print_info "High Energy Apps (by CPU usage):"
    echo ""
    echo "App                     CPU%    Status"
    echo "----------------------------------------"
    
    ps aux | head -20 | tail -19 | while read -r line; do
        user=$(echo "$line" | awk '{print $1}')
        cpu=$(echo "$line" | awk '{print $3}')
        app=$(echo "$line" | awk '{print $11}' | xargs basename)
        
        # Skip system processes
        if [[ "$user" != "root" ]] && [[ "$user" != "_"* ]]; then
            # Color code by CPU usage
            cpu_int=${cpu%.*}
            if [ "${cpu_int:-0}" -ge 50 ]; then
                color=$RED
                status="High Impact"
            elif [ "${cpu_int:-0}" -ge 20 ]; then
                color=$YELLOW
                status="Medium Impact"
            elif [ "${cpu_int:-0}" -ge 5 ]; then
                color=$NC
                status="Low Impact"
            else
                continue
            fi
            
            printf "%-24s ${color}%5s%%${NC}  %s\n" "${app:0:24}" "$cpu" "$status"
        fi
    done
    
    echo ""
    print_info "Energy Saving Tips:"
    echo "  • Quit apps with high CPU usage when not needed"
    echo "  • Use Safari instead of Chrome for better battery life"
    echo "  • Disable visual effects in accessibility settings"
    echo "  • Close unnecessary browser tabs"
}

battery_monitor() {
    print_info "📊 Real-time Battery Monitor"
    echo ""
    echo "Press Ctrl+C to stop monitoring"
    echo ""
    
    while true; do
        clear
        print_info "📊 Battery Monitor - $(date '+%H:%M:%S')"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        
        # Get current battery info
        battery_info=$(pmset -g batt)
        charge=$(echo "$battery_info" | grep -o '[0-9]*%' | head -1 | tr -d '%')
        status=$(echo "$battery_info" | grep -o 'AC\|Battery\|charged')
        time_remaining=$(echo "$battery_info" | grep -o '[0-9]*:[0-9]*' | head -1)
        
        # Create visual battery bar
        bar_length=30
        filled=$((charge * bar_length / 100))
        empty=$((bar_length - filled))
        
        # Color based on charge level
        if [ "$charge" -ge 60 ]; then
            bar_color=$GREEN
        elif [ "$charge" -ge 30 ]; then
            bar_color=$YELLOW
        else
            bar_color=$RED
        fi
        
        # Draw battery
        echo -n "  ["
        echo -n "${bar_color}"
        for ((i=0; i<filled; i++)); do echo -n "█"; done
        echo -n ""
        for ((i=0; i<empty; i++)); do echo -n "░"; done
        echo "] ${charge}%"
        echo ""
        
        echo "  Power Source: $status"
        if [ -n "$time_remaining" ] && [ "$status" = "Battery" ]; then
            echo "  Time Remaining: $time_remaining"
        elif [ "$status" = "AC" ] && [ "$charge" -lt 100 ]; then
            echo "  Status: Charging"
        elif [ "$charge" -eq 100 ]; then
            echo "  Status: Fully Charged"
        fi
        
        # Temperature if available
        if command -v osx-cpu-temp &> /dev/null; then
            echo ""
            echo "  CPU Temperature: $(osx-cpu-temp)"
        fi
        
        # Top energy app
        echo ""
        echo "  Top Energy App:"
        ps aux | sort -rn -k 3 | head -2 | tail -1 | awk '{printf "    %s (%.1f%% CPU)\n", $11, $3}'
        
        sleep 5
    done
}

battery_tips() {
    print_info "💡 Battery Optimization Tips"
    echo ""
    
    print_info "Daily Usage:"
    echo "  • Keep battery between 20% and 80% for daily use"
    echo "  • Avoid complete discharge (0%) when possible"
    echo "  • Unplug when fully charged if not using"
    echo ""
    
    print_info "Long-term Storage:"
    echo "  • Store at 50% charge if not using for weeks"
    echo "  • Keep in cool, dry place"
    echo "  • Check monthly and recharge if needed"
    echo ""
    
    print_info "Performance Tips:"
    echo "  • Use original Apple charger when possible"
    echo "  • Keep macOS updated for battery optimizations"
    echo "  • Reset SMC if experiencing battery issues"
    echo "  • Calibrate battery every few months"
    echo ""
    
    print_info "Energy Saving:"
    echo "  • Reduce screen brightness"
    echo "  • Turn off keyboard backlight when not needed"
    echo "  • Disable Bluetooth/WiFi when not in use"
    echo "  • Use Safari over Chrome (2-3x better battery)"
    echo "  • Quit unused apps and browser tabs"
    echo ""
    
    print_info "Warning Signs:"
    echo "  • Battery health below 80%"
    echo "  • Unexpected shutdowns"
    echo "  • Swollen battery (stop using immediately)"
    echo "  • Not holding charge"
    echo "  • Service Battery warning"
}

# Helper function to save battery history
save_battery_history() {
    local health="$1"
    local cycles="$2"
    
    mkdir -p "$(dirname "$BATTERY_HISTORY_FILE")"
    
    # Add header if file doesn't exist
    if [ ! -f "$BATTERY_HISTORY_FILE" ]; then
        echo "Date,Health%,Cycles" > "$BATTERY_HISTORY_FILE"
    fi
    
    # Append current data
    echo "$(date '+%Y-%m-%d %H:%M'),$health,$cycles" >> "$BATTERY_HISTORY_FILE"
}

# Main command handler
case "${1:-}" in
    health)
        battery_health
        ;;
    status)
        battery_status
        ;;
    calibrate)
        battery_calibrate
        ;;
    history)
        battery_history
        ;;
    optimize)
        battery_optimize
        ;;
    apps)
        battery_apps
        ;;
    monitor)
        battery_monitor
        ;;
    tips)
        battery_tips
        ;;
    *)
        show_battery_help
        ;;
esac

# Plugin main entry point
plugin_main() {
    # This plugin uses case statement structure - execute case directly
    local arg1="${1:-}"
    
    case "$arg1" in
        health)
            battery_health
            ;;
        status)
            battery_status
            ;;
        calibrate)
            battery_calibrate
            ;;
        history)
            battery_history
            ;;
        optimize)
            battery_optimize
            ;;
        apps)
            battery_apps
            ;;
        monitor)
            battery_monitor
            ;;
        tips)
            battery_tips
            ;;
        *)
            show_battery_help
            ;;
    esac
}

# Initialize the plugin
plugin_init

# Call the main function if not sourced
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    plugin_main "$@"
fi
