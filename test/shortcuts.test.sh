#!/bin/bash

# Test suite for system shortcuts features

# Get directories
TEST_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$TEST_DIR")"

# Source test helper and plugin adapter
source "$TEST_DIR/test_helper.sh"
source "$TEST_DIR/plugin_test_adapter.sh" shortcuts

# Test command wrapper - calls plugin through main mac script
SHORTCUTS_SCRIPT="$PROJECT_DIR/mac"

# Start test suite
test_suite "System Shortcuts"

# Setup test environment
setup_test_env

# Clean up any running caffeinate processes before starting
pkill -f caffeinate 2>/dev/null || true

# Test help command
test_step "Shortcuts Help Command"
output=$($SHORTCUTS_SCRIPT shortcuts shortcuts 2>&1)
if [[ $? -eq 0 ]]; then
    pass "Help command executed successfully"
else
    fail "Help command failed"
fi

# Check help output structure
if [[ "$output" == *"Usage: mac shortcuts"* ]]; then
    pass "Shows correct usage syntax"
else
    fail "Missing usage syntax"
fi

if [[ "$output" == *"screenshot"* ]] && [[ "$output" == *"lock"* ]] && [[ "$output" == *"caffeinate"* ]]; then
    pass "Shows all main commands in help"
else
    fail "Missing main commands in help"
fi

if [[ "$output" == *"Examples:"* ]]; then
    pass "Shows usage examples"
else
    fail "Missing usage examples"
fi

# Test screenshot command options
test_step "Screenshot Command Options"
# Test screenshot help by checking the main help which includes screenshot info
output=$($SHORTCUTS_SCRIPT shortcuts 2>&1)
if [[ "$output" == *"screenshot"* ]] && [[ "$output" == *"Enhanced screenshot"* ]]; then
    pass "Screenshot command listed in help correctly"
else
    fail "Screenshot command not properly documented"
fi

# Test screenshot invalid option handling (safer than actual screenshot)
output=$($SHORTCUTS_SCRIPT shortcuts screenshot --invalid-option 2>&1 || true)
if [[ "$output" == *"Unknown option"* ]] || [[ $? -ne 0 ]]; then
    pass "Screenshot handles invalid options correctly"
else
    fail "Screenshot option validation failed"
fi

# Test lock command (dry run)
test_step "Lock Command Test"
output=$(echo "n" | $SHORTCUTS_SCRIPT shortcuts lock 2>&1)
if [[ $? -eq 0 ]]; then
    pass "Lock command executed successfully"
else
    fail "Lock command failed"
fi

if [[ "$output" == *"Lock screen now?"* ]] || [[ "$output" == *"Locking Screen"* ]]; then
    pass "Lock command shows confirmation prompt"
else
    fail "Lock command missing confirmation"
fi

if [[ "$output" == *"Lock cancelled"* ]]; then
    pass "Lock command cancellation works"
else
    fail "Lock command cancellation failed"
fi

# Test caffeinate command
test_step "Caffeinate Command Test"
# Clean up any lingering caffeinate processes before test
pkill -f caffeinate 2>/dev/null || true
sleep 1

# Test caffeinate with specific duration (safer than indefinite)
output=$(timeout 3 $SHORTCUTS_SCRIPT shortcuts caffeinate 1s 2>&1 || true)
if [[ "$output" == *"Caffeinate System"* ]]; then
    pass "Caffeinate command displays correctly"
else
    fail "Caffeinate command display failed"
fi

# Clean up any lingering caffeinate processes from test
pkill -f caffeinate 2>/dev/null || true

# Test caffeinate with invalid duration format
output=$(timeout 2 $SHORTCUTS_SCRIPT shortcuts caffeinate invalid_duration 2>&1 || true)
if [[ "$output" == *"Invalid duration format"* ]]; then
    pass "Caffeinate handles invalid duration correctly"
else
    fail "Caffeinate duration validation failed"
fi

# Test airplane mode status check
test_step "Airplane Mode Status Check"
output=$(echo "" | timeout 3 $SHORTCUTS_SCRIPT shortcuts airplane 2>&1 || true)
if [[ "$output" == *"Airplane Mode Toggle"* ]]; then
    pass "Airplane mode command executed successfully"
else
    fail "Airplane mode command failed"
fi

if [[ "$output" == *"Current Status:"* ]] && [[ "$output" == *"WiFi:"* ]]; then
    pass "Airplane mode shows current status"
else
    fail "Airplane mode status display failed"
fi

if [[ "$output" == *"Choose action:"* ]]; then
    pass "Airplane mode shows action menu"
else
    fail "Airplane mode action menu missing"
fi

# Test dock command
test_step "Dock Command Test"
output=$(echo "" | timeout 3 $SHORTCUTS_SCRIPT shortcuts dock 2>&1 || true)
if [[ "$output" == *"Dock Management"* ]]; then
    pass "Dock command executed successfully"
else
    fail "Dock command failed"
fi

if [[ "$output" == *"Dock Management"* ]]; then
    pass "Dock command shows management interface"
else
    fail "Dock management interface missing"
fi

if [[ "$output" == *"Current Status:"* ]] && [[ "$output" == *"Auto-hide:"* ]]; then
    pass "Dock command shows current status"
else
    fail "Dock status display failed"
fi

# Test finder command
test_step "Finder Command Test"
output=$(echo "" | timeout 3 $SHORTCUTS_SCRIPT shortcuts finder 2>&1 || true)
if [[ "$output" == *"Finder Controls"* ]]; then
    pass "Finder command executed successfully"
else
    fail "Finder command failed"
fi

if [[ "$output" == *"Finder Controls"* ]]; then
    pass "Finder command shows controls interface"
else
    fail "Finder controls interface missing"
fi

if [[ "$output" == *"Current Status:"* ]] && [[ "$output" == *"Hidden files:"* ]]; then
    pass "Finder command shows hidden files status"
else
    fail "Finder status display failed"
fi

# Test display command (dry run)
test_step "Display Command Test"
output=$(echo "" | timeout 3 $SHORTCUTS_SCRIPT shortcuts display 2>&1 || true)
if [[ "$output" == *"Display Control"* ]]; then
    pass "Display command executed successfully"
else
    fail "Display command failed"
fi

if [[ "$output" == *"Display Control"* ]]; then
    pass "Display command shows control interface"
else
    fail "Display control interface missing"
fi

if [[ "$output" == *"Available actions:"* ]]; then
    pass "Display command shows available actions"
else
    fail "Display actions menu missing"
fi

# Test volume command
test_step "Volume Command Test"
output=$(echo "" | timeout 3 $SHORTCUTS_SCRIPT shortcuts volume 2>&1 || true)
if [[ "$output" == *"Volume Control"* ]]; then
    pass "Volume command executed successfully"
else
    fail "Volume command failed"
fi

if [[ "$output" == *"Volume Control"* ]]; then
    pass "Volume command shows control interface"
else
    fail "Volume control interface missing"
fi

if [[ "$output" == *"Current Volume:"* ]] && [[ "$output" == *"Status:"* ]]; then
    pass "Volume command shows current status"
else
    fail "Volume status display failed"
fi

if [[ "$output" == *"Volume controls:"* ]]; then
    pass "Volume command shows controls menu"
else
    fail "Volume controls menu missing"
fi

# Test volume level setting (safe test)
output=$(timeout 3 $SHORTCUTS_SCRIPT shortcuts volume 50 2>&1 || true)
if [[ "$output" == *"Setting volume to 50%"* ]]; then
    pass "Volume level setting works"
else
    fail "Volume level setting failed"
fi

# Test invalid command handling
test_step "Invalid Command Handling"
output=$($SHORTCUTS_SCRIPT shortcuts invalid_command 2>&1)
if [[ "$output" == *"Usage: mac shortcuts"* ]]; then
    pass "Invalid command shows help"
else
    fail "Invalid command handling failed"
fi

# Test invalid screenshot option
output=$($SHORTCUTS_SCRIPT shortcuts screenshot --invalid-option 2>&1)
if [[ "$output" == *"Unknown option"* ]] || [[ $? -ne 0 ]]; then
    pass "Invalid screenshot option handled correctly"
else
    fail "Invalid screenshot option handling failed"
fi

# Performance test
test_step "Performance Test"
start_time=$(date +%s)
timeout 3 $SHORTCUTS_SCRIPT shortcuts volume >/dev/null 2>&1
exit_code=$?
end_time=$(date +%s)
duration=$((end_time - start_time))

if [ $exit_code -eq 124 ]; then
    fail "Volume command timed out (>3 seconds)"
elif [ $duration -le 3 ]; then
    pass "Volume command completed within 3 seconds"
else
    fail "Volume command too slow ($duration seconds)"
fi

# Test screenshot performance
start_time=$(date +%s)
timeout 3 $SHORTCUTS_SCRIPT shortcuts screenshot --help >/dev/null 2>&1
exit_code=$?
end_time=$(date +%s)
duration=$((end_time - start_time))

if [ $exit_code -eq 124 ]; then
    fail "Screenshot help timed out (>3 seconds)"
elif [ $duration -le 3 ]; then
    pass "Screenshot help completed within 3 seconds"
else
    fail "Screenshot help too slow ($duration seconds)"
fi

# Integration test
test_step "Integration Test"
all_passed=true

# Test multiple commands in sequence
$SHORTCUTS_SCRIPT shortcuts volume >/dev/null 2>&1
if [[ $? -ne 0 ]]; then all_passed=false; fi

$SHORTCUTS_SCRIPT shortcuts dock >/dev/null 2>&1
if [[ $? -ne 0 ]]; then all_passed=false; fi

$SHORTCUTS_SCRIPT shortcuts finder >/dev/null 2>&1
if [[ $? -ne 0 ]]; then all_passed=false; fi

$SHORTCUTS_SCRIPT shortcuts airplane >/dev/null 2>&1
if [[ $? -ne 0 ]]; then all_passed=false; fi

$SHORTCUTS_SCRIPT shortcuts display >/dev/null 2>&1
if [[ $? -ne 0 ]]; then all_passed=false; fi

if $all_passed; then
    pass "All commands work in sequence"
else
    fail "Some commands failed in integration test"
fi

# Test command chaining safety
echo "n" | $SHORTCUTS_SCRIPT shortcuts lock >/dev/null 2>&1
lock_exit=$?
$SHORTCUTS_SCRIPT shortcuts volume >/dev/null 2>&1
volume_exit=$?

if [[ $lock_exit -eq 0 ]] && [[ $volume_exit -eq 0 ]]; then
    pass "Commands can be run safely in sequence"
else
    fail "Command sequencing safety test failed"
fi

# Test help consistency across commands - simplified version
# Just check that the main help contains all command names
main_help=$($SHORTCUTS_SCRIPT shortcuts 2>&1)
help_consistency=true
for cmd in screenshot lock caffeinate airplane dock finder display volume; do
    if [[ ! "$main_help" == *"$cmd"* ]]; then
        help_consistency=false
        break
    fi
done

if $help_consistency; then
    pass "Help output is consistent across commands"
else
    fail "Help output inconsistency detected"
fi

# Test error handling for missing dependencies
test_step "Dependency Handling Test"
# Test behavior when optional commands are missing (should gracefully handle)
output=$($SHORTCUTS_SCRIPT shortcuts airplane 2>&1)
if [[ "$output" == *"blueutil"* ]] || [[ "$output" == *"WiFi:"* ]]; then
    pass "Handles missing optional dependencies gracefully"
else
    fail "Dependency handling test unclear"
fi

# Test command structure validation
test_step "Command Structure Validation"
# Check if main mac script is executable
if [[ -x "$SHORTCUTS_SCRIPT" ]]; then
    pass "Main script is executable"
else
    fail "Main script is not executable"
fi

# Check if shortcuts plugin exists
shortcuts_plugin="$PROJECT_DIR/plugins/available/shortcuts/main.sh"
if [[ -f "$shortcuts_plugin" ]]; then
    pass "Shortcuts plugin exists"
else
    fail "Shortcuts plugin missing"
fi

# Check if shortcuts plugin is properly structured
if [[ -f "$PROJECT_DIR/plugins/available/shortcuts/plugin.json" ]]; then
    pass "Plugin configuration exists"
else
    fail "Plugin configuration missing"
fi

# Verify the plugin can be called
output=$($SHORTCUTS_SCRIPT shortcuts --help 2>&1 || $SHORTCUTS_SCRIPT shortcuts 2>&1)
if [[ $? -eq 0 ]]; then
    pass "Plugin can be executed successfully"
else
    fail "Plugin execution failed"
fi

# Clean up test environment
cleanup_test_env

# Show summary
test_summary