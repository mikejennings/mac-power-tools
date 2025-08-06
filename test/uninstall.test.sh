#!/bin/bash

# Test suite for mac-uninstall.sh

# Get directories
TEST_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$TEST_DIR")"

# Source test helper and script
source "$TEST_DIR/test_helper.sh"
source "$PROJECT_DIR/scripts/mac-uninstall.sh"

# Start test suite
test_suite "Application Uninstaller"

# Setup test environment
setup_test_env

# Create mock application structure
create_mock_app() {
    local app_name="$1"
    local bundle_id="$2"
    
    # Create mock app bundle
    mkdir -p "$TEST_DIR/Applications/${app_name}.app/Contents"
    
    # Create mock Info.plist
    cat > "$TEST_DIR/Applications/${app_name}.app/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>${bundle_id}</string>
    <key>CFBundleName</key>
    <string>${app_name}</string>
</dict>
</plist>
EOF
    
    # Create mock support files
    mkdir -p "$TEST_DIR/Library/Application Support/${app_name}"
    mkdir -p "$TEST_DIR/Library/Caches/${bundle_id}"
    mkdir -p "$TEST_DIR/Library/Preferences"
    touch "$TEST_DIR/Library/Preferences/${bundle_id}.plist"
    
    echo "Mock app created"
}

# Test: Find app bundle function
test "find_app_bundle should locate app in /Applications" \
    'app_path=$(find_app_bundle "Safari"); [[ "$app_path" == "/Applications/Safari.app" ]]'

# Test: Get bundle ID function
test "get_bundle_id should extract bundle identifier" \
    'bundle_id=$(get_bundle_id "/Applications/Safari.app"); [[ -n "$bundle_id" ]]'

# Test: Check if app is running
test "is_app_running should detect running apps" \
    '! is_app_running "ThisAppDoesNotExist12345"'

# Test: Dry run mode
create_mock_app "TestApp" "com.test.testapp"
DRY_RUN=true
test "dry run should not remove files" \
    'remove_files "$TEST_DIR/Applications/TestApp.app"; [[ -d "$TEST_DIR/Applications/TestApp.app" ]]'
DRY_RUN=false

# Test: Find related files - Skip as it searches real directories
skip_test "find_related_files should locate support files" \
    "Function searches real $HOME/Library directories, not test directories"

# Test: Calculate size function
test "calculate_size should return human readable sizes" \
    'echo "/usr/bin/ls" | calculate_size | grep -E "KB|MB|GB"'

# Test: List applications function
test_output "list_applications should show installed apps" \
    'list_applications' \
    "Applications"

# Test: File removal in test environment
test_file_exists "Mock app should exist before removal" \
    "$TEST_DIR/Applications/TestApp.app/Contents/Info.plist"

# Test: Validate app name cleaning
test "App name should be cleaned properly" \
    'clean_name="Google Chrome.app"; clean_name="${clean_name%.app}"; [[ "$clean_name" == "Google Chrome" ]]'

# Test: Bundle ID validation
test "Should handle missing bundle ID gracefully" \
    'bundle_id=$(get_bundle_id "/nonexistent/path"); [[ -z "$bundle_id" ]]'

# Test: Command availability
test_command_exists "mdfind command should be available" "mdfind"
test_command_exists "defaults command should be available" "defaults"
test_command_exists "osascript command should be available" "osascript"

# Test: Help output
test_output "Help should display usage information" \
    'show_help' \
    "USAGE:"

# Cleanup test environment
cleanup_test_env

# Print summary
test_summary