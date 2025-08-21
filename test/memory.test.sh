#!/bin/bash

# Test suite for memory plugin

# Get directories
TEST_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$TEST_DIR")"

# Source test helper and plugin adapter
source "$TEST_DIR/test_helper.sh"
source "$TEST_DIR/plugin_test_adapter.sh" memory

# Start test suite
test_suite "Memory Optimizer"

# Setup test environment
setup_test_env

# Test: Format bytes function
test "format_bytes should format 1024 as 1.0 KB" \
    '[[ $(format_bytes 1024) == "1.0 KB" ]]'

test "format_bytes should format 1048576 as 1.0 MB" \
    '[[ $(format_bytes 1048576) == "1.0 MB" ]]'

test "format_bytes should format 1073741824 as 1.0 GB" \
    '[[ $(format_bytes 1073741824) == "1.0 GB" ]]'

test "format_bytes should handle small values" \
    '[[ $(format_bytes 512) == "512 bytes" ]]'

# Test: Command availability
test_command_exists "vm_stat command should be available" "vm_stat"
test_command_exists "sysctl command should be available" "sysctl"
test_command_exists "ps command should be available" "ps"
test_command_exists "bc command should be available" "bc"

# Test: Memory info parsing
test "get_memory_info should set MEMORY_TOTAL" \
    'get_memory_info; [[ $MEMORY_TOTAL -gt 0 ]]'

test "get_memory_info should set MEMORY_FREE" \
    'get_memory_info; [[ -n $MEMORY_FREE ]]'

test "get_memory_info should calculate MEMORY_PRESSURE" \
    'get_memory_info; [[ -n $MEMORY_PRESSURE ]]'

# Test: System memory info
test "sysctl should return memory size" \
    'memsize=$(sysctl -n hw.memsize); [[ $memsize -gt 0 ]]'

test "sysctl should return page size" \
    'pagesize=$(sysctl -n hw.pagesize); [[ $pagesize -gt 0 ]]'

# Test: Process listing
test "ps aux should list processes" \
    'count=$(ps aux | wc -l); [[ $count -gt 1 ]]'

# Test: Memory pressure calculation
test "Memory pressure should be between 0 and 100" \
    'get_memory_info;
     pressure_valid=$(echo "$MEMORY_PRESSURE >= 0 && $MEMORY_PRESSURE <= 100" | bc);
     [[ $pressure_valid -eq 1 ]]'

# Test: Settings
test "CONTINUOUS flag should default to false" \
    '[[ "$CONTINUOUS" == false ]]'

test "INTERVAL should default to 5" \
    '[[ $INTERVAL -eq 5 ]]'

test "THRESHOLD should default to 80" \
    '[[ $THRESHOLD -eq 80 ]]'

# Test: Help output
test_output "Help should display usage information" \
    'show_help' \
    "USAGE:"

test_output "Help should list options" \
    'show_help' \
    "OPTIONS:"

test_output "Help should show examples" \
    'show_help' \
    "EXAMPLES:"

# Cleanup test environment
cleanup_test_env

# Print summary
test_summary