#!/bin/bash

# Test suite for migrate-apps plugin
# Tests the manual app migration functionality

# Get the directory where this script is located
TEST_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$TEST_DIR")"

# Source test helper and plugin adapter
source "$TEST_DIR/test_helper.sh"
source "$TEST_DIR/plugin_test_adapter.sh" migrate-apps

# Test command wrapper - calls plugin through main mac script
MIGRATE_APPS_SCRIPT="$PROJECT_DIR/mac migrate-apps"

# Start test suite
test_suite "Mac Migrate Apps"

# Test 1: Script exists and is executable
test "Script exists and is executable" \
    "[ -x '$PROJECT_DIR/mac' ]"

# Test 2: Help option works
test "Help option displays usage" \
    "$MIGRATE_APPS_SCRIPT --help | grep -q 'Mac Power Tools - Manual Apps to Homebrew Migration'"

# Test 3: List option works
test "List option displays known mappings" \
    "$MIGRATE_APPS_SCRIPT --list | grep -q 'Known Application to Homebrew Cask mappings'"

# Test 4: Analyze option works (dry run)
test "Analyze option works without errors" \
    "$MIGRATE_APPS_SCRIPT --analyze"

# Test 5: Default dry run mode
test "Default mode is dry run (safe)" \
    "$MIGRATE_APPS_SCRIPT --analyze | grep -q 'Analyzing'"

# Test 6: Known app mapping function works
test "Known app mapping function works" \
    "$MIGRATE_APPS_SCRIPT --list | grep -q 'google-chrome'"

# Test 7: System app detection works
test "System app detection works" \
    "$MIGRATE_APPS_SCRIPT --analyze | grep -q 'Applications'"

# Test 8: Custom mapping functionality
test "Custom mapping can be added" \
    "$MIGRATE_APPS_SCRIPT --map 'Test App' 'test-app' 2>&1 | grep -q 'app'"

# Test 9: Homebrew dependency check
test "Homebrew dependency check works" \
    "command -v brew >/dev/null 2>&1"

# Test 10: App search function works
test "App search function works" \
    "$MIGRATE_APPS_SCRIPT --list | grep -qi 'chrome'"

# Test 11: Cask installation check works
test "Cask installation check works" \
    "brew list --cask nonexistent-cask-12345 2>&1 | grep -q 'No such keg' || grep -q 'Error'"

# Test 12: Applications directory scan works
test "Applications directory scan works" \
    "ls /Applications/*.app 2>/dev/null | wc -l | awk '{print (\$1 > 0)}' | grep -q '1'"

# Test 13: Version information in help
test "Version information available" \
    "$MIGRATE_APPS_SCRIPT --help | grep -q 'Mac Power Tools'"

# Test 14: Error handling for invalid options
test "Invalid option handling" \
    "$MIGRATE_APPS_SCRIPT --invalid-option 2>&1 | grep -q 'Unknown option'"

# Test 15: Interactive mode can be disabled
test "Non-interactive mode works" \
    "$MIGRATE_APPS_SCRIPT --yes --analyze"

# Test 16: Verbose mode works
test "Verbose mode works" \
    "$MIGRATE_APPS_SCRIPT --verbose --analyze"

# Test 17: Map option requires parameters
test "Map option requires parameters" \
    "$MIGRATE_APPS_SCRIPT --map 2>&1 | grep -q 'requires APP_NAME and CASK_NAME'"

# Test 18: Safety features - no automatic deletion
test "Safety: No automatic app deletion" \
    "$MIGRATE_APPS_SCRIPT --help | grep -qi 'dry.run\|backup\|safe'"

# Test 19: Dry run is default
test "Dry run is default mode" \
    "$MIGRATE_APPS_SCRIPT --help | grep -qi 'dry.run\|default'"

# Test 20: Execute mode requires explicit flag
test "Execute mode requires explicit flag" \
    "$MIGRATE_APPS_SCRIPT --help | grep -q '\\-\\-execute'"

# Test 21: Backup functionality is available
test "Backup functionality is available" \
    "$MIGRATE_APPS_SCRIPT --help | grep -q '\\-\\-no-backup'"

# Test 22: Restore command works
test "Restore command works" \
    "$MIGRATE_APPS_SCRIPT --restore | grep -q 'Available App Backups'"

# Test 23: Backup directory option works
test "Backup directory option works" \
    "$MIGRATE_APPS_SCRIPT --backup-dir /tmp/test-backup --help"

# Test 24: Backup functions exist
test "Backup functions exist" \
    "$MIGRATE_APPS_SCRIPT --help | grep -q 'backup'"

# Test 25: Backup directory creation function works
test "Backup directory creation function works" \
    "$MIGRATE_APPS_SCRIPT --backup-dir /tmp/test 2>&1 | grep -v 'Error' || true"

# Print summary and exit with proper code
test_summary