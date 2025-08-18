#!/bin/bash

# Test suite for battery management features

# Get directories
TEST_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$TEST_DIR")"

# Source test helper
source "$TEST_DIR/test_helper.sh"

# Test script location
BATTERY_SCRIPT="$PROJECT_DIR/scripts/mac-battery.sh"

# Start test suite
test_suite "Battery Management"

# Setup test environment
setup_test_env

# Test battery health command
test_step "Battery Health Command"
output=$($BATTERY_SCRIPT health 2>&1)
if [[ $? -eq 0 ]]; then
    pass "Health command executed successfully"
else
    fail "Health command failed"
fi

# Check output structure
if [[ "$output" == *"Battery Health Report"* ]]; then
    pass "Shows battery health report header"
else
    fail "Missing health report header"
fi

if [[ "$output" == *"Battery Condition"* ]] && [[ "$output" == *"Battery Capacity"* ]]; then
    pass "Shows battery condition and capacity"
else
    fail "Missing condition or capacity information"
fi

if [[ "$output" == *"Cycle Information"* ]]; then
    pass "Shows cycle count information"
else
    fail "Missing cycle information"
fi

# Test battery status command
test_step "Battery Status Command"
output=$($BATTERY_SCRIPT status 2>&1)
if [[ $? -eq 0 ]]; then
    pass "Status command executed successfully"
else
    fail "Status command failed"
fi

if [[ "$output" == *"Battery Status"* ]] && [[ "$output" == *"Power Settings"* ]]; then
    pass "Shows status and power settings"
else
    fail "Missing status information"
fi

# Test battery calibrate command (dry run)
test_step "Battery Calibration"
output=$(echo "n" | $BATTERY_SCRIPT calibrate 2>&1)
if [[ $? -eq 0 ]] && [[ "$output" == *"Battery Calibration Wizard"* ]]; then
    pass "Calibration wizard displays properly"
else
    fail "Calibration wizard failed"
fi

# Test battery history command
test_step "Battery History"
output=$($BATTERY_SCRIPT history 2>&1)
if [[ $? -eq 0 ]]; then
    pass "History command executed successfully"
else
    fail "History command failed"
fi

# Test battery optimize command
test_step "Battery Optimization"
output=$(echo "n" | $BATTERY_SCRIPT optimize 2>&1)
if [[ $? -eq 0 ]] && [[ "$output" == *"Battery Optimization Settings"* ]]; then
    pass "Optimization settings display properly"
else
    fail "Optimization settings failed"
fi

# Test battery apps command
test_step "Battery Apps Usage"
output=$($BATTERY_SCRIPT apps 2>&1)
if [[ $? -eq 0 ]]; then
    pass "Apps command executed successfully"
else
    fail "Apps command failed"
fi

# Check apps output structure
if [[ "$output" == *"Battery Usage by Application"* ]]; then
    pass "Shows apps usage header"
else
    fail "Missing apps usage header"
fi

if [[ "$output" == *"Energy Saving Tips"* ]]; then
    pass "Shows energy saving tips"
else
    fail "Missing energy saving tips"
fi

# Test battery monitor command (brief test)
test_step "Battery Monitor"
output=$(timeout 1 $BATTERY_SCRIPT monitor 2>&1 || true)
if [[ "$output" == *"Battery Monitor"* ]]; then
    pass "Monitor starts successfully"
else
    fail "Monitor failed to start"
fi

# Test battery tips command
test_step "Battery Tips"
output=$($BATTERY_SCRIPT tips 2>&1)
if [[ $? -eq 0 ]] && [[ "$output" == *"Battery Optimization Tips"* ]]; then
    pass "Tips display successfully"
else
    fail "Tips command failed"
fi

# Test help output
test_step "Battery Help"
output=$($BATTERY_SCRIPT 2>&1)
if [[ $? -eq 0 ]] && [[ "$output" == *"Usage:"* ]]; then
    pass "Help displays successfully"
else
    fail "Help display failed"
fi

# Test invalid command handling
test_step "Invalid Command Handling"
output=$($BATTERY_SCRIPT invalid_command 2>&1)
if [[ "$output" == *"Usage:"* ]]; then
    pass "Invalid command shows help"
else
    fail "Invalid command handling failed"
fi

# Performance test
test_step "Performance Test"
start_time=$(date +%s)
timeout 3 $BATTERY_SCRIPT health >/dev/null 2>&1
exit_code=$?
end_time=$(date +%s)
duration=$((end_time - start_time))

if [ $exit_code -eq 124 ]; then
    fail "Battery health timed out (>3 seconds)"
elif [ $duration -le 3 ]; then
    pass "Health command completed within 3 seconds"
else
    fail "Health command too slow ($duration seconds)"
fi

# Integration test
test_step "Integration Test"
all_passed=true

$BATTERY_SCRIPT health >/dev/null 2>&1
if [[ $? -ne 0 ]]; then all_passed=false; fi

$BATTERY_SCRIPT status >/dev/null 2>&1
if [[ $? -ne 0 ]]; then all_passed=false; fi

$BATTERY_SCRIPT tips >/dev/null 2>&1
if [[ $? -ne 0 ]]; then all_passed=false; fi

$BATTERY_SCRIPT apps >/dev/null 2>&1
if [[ $? -ne 0 ]]; then all_passed=false; fi

if $all_passed; then
    pass "All commands work in sequence"
else
    fail "Some commands failed in integration test"
fi

# Clean up test environment
cleanup_test_env

# Show summary
test_summary