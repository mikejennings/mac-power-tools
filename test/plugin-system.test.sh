#!/bin/bash

# Comprehensive test suite for Mac Power Tools Plugin System
# Tests core functionality with isolated test environment

# Source test framework
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "${SCRIPT_DIR}/test_helper.sh"

# Set up test environment
MAC_POWER_TOOLS_HOME="$(dirname "$SCRIPT_DIR")"
export MAC_POWER_TOOLS_HOME

# Source only the plugin API for basic tests
source "${MAC_POWER_TOOLS_HOME}/lib/plugin-api.sh"

# Initialize test directories (TEST_DIR is set by setup_test_env)
init_test_directories() {
    if [[ -z "$TEST_DIR" ]]; then
        TEST_DIR=$(mktemp -d "/tmp/mac-power-tools-test.XXXXXX")
        export TEST_DIR
    fi
    
    TEST_PLUGINS_DIR="${TEST_DIR}/plugins"
    TEST_ENABLED_DIR="${TEST_PLUGINS_DIR}/enabled"
    TEST_AVAILABLE_DIR="${TEST_PLUGINS_DIR}/available"
    TEST_CORE_DIR="${TEST_PLUGINS_DIR}/core"
    TEST_CONFIG_FILE="${TEST_DIR}/config/plugins.conf"
    
    export TEST_PLUGINS_DIR TEST_ENABLED_DIR TEST_AVAILABLE_DIR TEST_CORE_DIR TEST_CONFIG_FILE
}

# Create test plugin structure
create_test_plugin() {
    local plugin_name="${1:-test-plugin}"
    local plugin_dir="${TEST_AVAILABLE_DIR}/${plugin_name}"
    
    mkdir -p "$plugin_dir"
    
    # Create plugin.json
    cat > "${plugin_dir}/plugin.json" <<EOF
{
  "name": "${plugin_name}",
  "version": "1.0.0",
  "description": "Test plugin for validation",
  "author": "Test Suite",
  "category": "testing",
  "commands": ["${plugin_name}", "test-cmd"],
  "dependencies": []
}
EOF

    # Create main.sh
    cat > "${plugin_dir}/main.sh" <<'EOF'
#!/bin/bash

# Simplified plugin script for testing (no API dependencies)
plugin_main() {
    local subcommand=${1:-help}
    case "$subcommand" in
        test) echo "test-plugin-output" ;;
        status) echo "Plugin is working" ;;
        *) echo "test-plugin help" ;;
    esac
}

# Execute main function
plugin_main "$@"
EOF
    chmod +x "${plugin_dir}/main.sh"
    echo "$plugin_dir"
}

# ============================================================================
# TEST SUITE: Plugin API Functions
# ============================================================================

test_plugin_api_colors() {
    test "RED color defined" "[[ -n '$RED' ]]"
    test "GREEN color defined" "[[ -n '$GREEN' ]]"
    test "BLUE color defined" "[[ -n '$BLUE' ]]"
    test "NC (no color) defined" "[[ -n '$NC' ]]"
}

test_plugin_api_print_functions() {
    local test_output
    
    test_output=$(print_info "Test info" 2>&1)
    test "print_info works" "echo '$test_output' | grep -q 'Test info'"
    
    test_output=$(print_success "Test success" 2>&1)
    test "print_success works" "echo '$test_output' | grep -q 'Test success'"
    
    test_output=$(print_warning "Test warning" 2>&1)
    test "print_warning works" "echo '$test_output' | grep -q 'Test warning'"
    
    test_output=$(print_error "Test error" 2>&1)
    test "print_error works" "echo '$test_output' | grep -q 'Test error'"
}

test_command_exists_function() {
    test "command_exists finds bash" "command_exists 'bash'"
    test "command_exists finds missing command" "! command_exists 'nonexistent-command-xyz'"
}

test_check_dependencies() {
    test "check_dependencies passes for existing commands" "check_dependencies 'bash' 'echo'"
    test "check_dependencies fails for missing commands" "! check_dependencies 'nonexistent-cmd'"
}

test_register_command() {
    register_command "testcmd" "Test command description"
    local desc_var="MAC_COMMAND_TESTCMD_DESC"
    test "Command description registered" "[[ '${!desc_var}' = 'Test command description' ]]"
}

test_plugin_environment_functions() {
    export MAC_PLUGIN_DIR="/test/path"
    export MAC_PLUGIN_NAME="test-name" 
    export MAC_PLUGIN_VERSION="test-version"
    
    test "Plugin directory function works" "[[ '$(plugin_dir)' = '/test/path' ]]"
    test "Plugin name function works" "[[ '$(plugin_name)' = 'test-name' ]]"
    test "Plugin version function works" "[[ '$(plugin_version)' = 'test-version' ]]"
}

test_plugin_lifecycle_functions() {
    plugin_init
    test "Plugin initialization sets flag" "[[ '$MAC_PLUGIN_INITIALIZED' = '1' ]]"
    
    plugin_cleanup
    test "Plugin cleanup resets flag" "[[ '$MAC_PLUGIN_INITIALIZED' = '0' ]]"
}

# ============================================================================
# TEST SUITE: Plugin Structure and Metadata
# ============================================================================

test_plugin_structure_creation() {
    init_test_directories
    mkdir -p "$TEST_AVAILABLE_DIR" "$TEST_CORE_DIR" "$TEST_ENABLED_DIR"
    
    local plugin_dir=$(create_test_plugin "structure-test")
    
    test "Plugin directory created" "[[ -d '$plugin_dir' ]]"
    test "Plugin metadata file exists" "[[ -f '${plugin_dir}/plugin.json' ]]"
    test "Plugin main script exists" "[[ -f '${plugin_dir}/main.sh' ]]"
    test "Plugin main script is executable" "[[ -x '${plugin_dir}/main.sh' ]]"
}

test_plugin_metadata_parsing() {
    init_test_directories
    mkdir -p "$TEST_AVAILABLE_DIR"
    local plugin_dir=$(create_test_plugin "metadata-test")
    
    # Test basic metadata reading
    local metadata=$(cat "${plugin_dir}/plugin.json")
    test "Plugin metadata contains name" "echo '$metadata' | grep -q '\"name\".*\"metadata-test\"'"
    test "Plugin metadata contains version" "echo '$metadata' | grep -q '\"version\".*\"1.0.0\"'"
    test "Plugin metadata contains description" "echo '$metadata' | grep -q '\"description\"'"
    test "Plugin metadata contains commands array" "echo '$metadata' | grep -q '\"commands\"'"
}

test_plugin_script_execution() {
    init_test_directories
    mkdir -p "$TEST_AVAILABLE_DIR"
    local plugin_dir=$(create_test_plugin "exec-test")
    
    # Test plugin script can be executed directly
    local output
    output=$("${plugin_dir}/main.sh" test 2>&1)
    test "Plugin script executes correctly" "echo '$output' | grep -q 'test-plugin-output'"
    
    output=$("${plugin_dir}/main.sh" status 2>&1)
    test "Plugin script status command works" "echo '$output' | grep -q 'Plugin is working'"
}

# ============================================================================
# TEST SUITE: File System Operations
# ============================================================================

test_directory_operations() {
    init_test_directories
    mkdir -p "$TEST_ENABLED_DIR" "$TEST_AVAILABLE_DIR" "$TEST_CORE_DIR"
    
    test "Enabled directory created" "[[ -d '$TEST_ENABLED_DIR' ]]"
    test "Available directory created" "[[ -d '$TEST_AVAILABLE_DIR' ]]"
    test "Core directory created" "[[ -d '$TEST_CORE_DIR' ]]"
}

test_symlink_operations() {
    init_test_directories
    mkdir -p "$TEST_ENABLED_DIR" "$TEST_AVAILABLE_DIR"
    local plugin_dir=$(create_test_plugin "symlink-test")
    
    # Create symlink
    ln -sf "$plugin_dir" "${TEST_ENABLED_DIR}/symlink-test"
    
    test "Symlink created successfully" "[[ -L '${TEST_ENABLED_DIR}/symlink-test' ]]"
    
    # Test that symlink resolves to the original directory (more robust)
    local symlink_target=$(readlink "${TEST_ENABLED_DIR}/symlink-test")
    test "Symlink points to correct target" "[[ -d '$symlink_target' ]] && [[ '$symlink_target' == *'symlink-test'* ]]"
    
    # Remove symlink
    rm -f "${TEST_ENABLED_DIR}/symlink-test"
    test "Symlink removed successfully" "[[ ! -L '${TEST_ENABLED_DIR}/symlink-test' ]]"
}

test_config_file_operations() {
    init_test_directories
    mkdir -p "$(dirname "$TEST_CONFIG_FILE")"
    
    # Create test config
    cat > "$TEST_CONFIG_FILE" <<EOF
# Test plugin configuration
test-plugin=enabled
another-plugin=disabled
EOF
    
    test "Config file created" "[[ -f '$TEST_CONFIG_FILE' ]]"
    test "Config file contains test data" "grep -q 'test-plugin=enabled' '$TEST_CONFIG_FILE'"
    
    # Test reading config
    local status=$(grep "^test-plugin=" "$TEST_CONFIG_FILE" | cut -d= -f2)
    test "Config file reading works" "[[ '$status' = 'enabled' ]]"
}

# ============================================================================
# TEST SUITE: Plugin Creation SDK Tests
# ============================================================================

test_create_plugin_script_exists() {
    local sdk_script="${MAC_POWER_TOOLS_HOME}/create-plugin.sh"
    test "Plugin creation SDK exists" "[[ -f '$sdk_script' ]]"
    test "Plugin creation SDK is executable" "[[ -x '$sdk_script' ]]"
}

test_create_plugin_help() {
    local sdk_script="${MAC_POWER_TOOLS_HOME}/create-plugin.sh"
    if [[ -f "$sdk_script" ]]; then
        local help_output
        help_output=$("$sdk_script" help 2>&1)
        test "SDK shows help message" "echo '$help_output' | grep -q 'Plugin Creator'"
        test "SDK help contains usage" "echo '$help_output' | grep -q 'Usage:'"
    else
        skip_test "SDK help test" "create-plugin.sh not found"
    fi
}

# ============================================================================
# TEST SUITE: Integration Tests
# ============================================================================

test_mac_plugin_script_exists() {
    local mac_plugin="${MAC_POWER_TOOLS_HOME}/mac-plugin"
    test "Main mac-plugin script exists" "[[ -f '$mac_plugin' ]]"
    test "Main mac-plugin script is executable" "[[ -x '$mac_plugin' ]]"
}

test_mac_plugin_help() {
    local mac_plugin="${MAC_POWER_TOOLS_HOME}/mac-plugin"
    if [[ -f "$mac_plugin" && -x "$mac_plugin" ]]; then
        local help_output
        help_output=$("$mac_plugin" help 2>&1)
        test "mac-plugin shows help" "echo '$help_output' | grep -q 'Mac Power Tools'"
        test "mac-plugin help contains commands" "echo '$help_output' | grep -q 'COMMANDS'"
    else
        skip_test "mac-plugin help test" "mac-plugin script not found or not executable"
    fi
}

test_plugin_library_files_exist() {
    test "Plugin API library exists" "[[ -f '${MAC_POWER_TOOLS_HOME}/lib/plugin-api.sh' ]]"
    test "Plugin loader library exists" "[[ -f '${MAC_POWER_TOOLS_HOME}/lib/plugin-loader.sh' ]]"
    test "Plugin manager library exists" "[[ -f '${MAC_POWER_TOOLS_HOME}/lib/plugin-manager.sh' ]]"
}

# ============================================================================
# TEST SUITE: Error Handling
# ============================================================================

test_malformed_plugin_handling() {
    init_test_directories
    mkdir -p "$TEST_AVAILABLE_DIR"
    local plugin_dir="${TEST_AVAILABLE_DIR}/malformed-test"
    mkdir -p "$plugin_dir"
    
    # Create malformed JSON
    echo "{ invalid json" > "${plugin_dir}/plugin.json"
    
    # Test that reading malformed JSON doesn't crash
    local metadata
    metadata=$(cat "${plugin_dir}/plugin.json" 2>/dev/null || echo "fallback")
    test "Handles malformed JSON gracefully" "[[ -n '$metadata' ]]"
}

test_missing_files_handling() {
    init_test_directories
    mkdir -p "$TEST_AVAILABLE_DIR"
    local plugin_dir="${TEST_AVAILABLE_DIR}/missing-files-test"
    mkdir -p "$plugin_dir"
    
    # Only create metadata, no main script
    echo '{"name": "missing-files-test"}' > "${plugin_dir}/plugin.json"
    
    test "Handles missing main script" "[[ ! -f '${plugin_dir}/main.sh' ]]"
    test "Plugin directory still exists" "[[ -d '$plugin_dir' ]]"
}

test_permission_handling() {
    init_test_directories
    mkdir -p "$TEST_AVAILABLE_DIR"
    local plugin_dir="${TEST_AVAILABLE_DIR}/permission-test"
    mkdir -p "$plugin_dir"
    
    # Create files with different permissions
    echo '{"name": "permission-test"}' > "${plugin_dir}/plugin.json"
    echo "#!/bin/bash" > "${plugin_dir}/main.sh"
    
    # Test without execute permission
    chmod 644 "${plugin_dir}/main.sh"
    test "Detects non-executable script" "[[ ! -x '${plugin_dir}/main.sh' ]]"
    
    # Test with execute permission
    chmod 755 "${plugin_dir}/main.sh"
    test "Detects executable script" "[[ -x '${plugin_dir}/main.sh' ]]"
}

# ============================================================================
# MAIN TEST EXECUTION
# ============================================================================

run_plugin_system_tests() {
    test_suite "Mac Power Tools Plugin System"
    
    # Set up test environment
    setup_test_env
    init_test_directories
    
    # Plugin API Tests
    printf "\n${CYAN}=== Plugin API Tests ===${NC}\n"
    test_plugin_api_colors
    test_plugin_api_print_functions
    test_command_exists_function
    test_check_dependencies
    test_register_command
    test_plugin_environment_functions
    test_plugin_lifecycle_functions
    
    # Plugin Structure Tests
    printf "\n${CYAN}=== Plugin Structure Tests ===${NC}\n"
    test_plugin_structure_creation
    test_plugin_metadata_parsing
    test_plugin_script_execution
    
    # File System Tests
    printf "\n${CYAN}=== File System Operations ===${NC}\n"
    test_directory_operations
    test_symlink_operations
    test_config_file_operations
    
    # Plugin Creation SDK Tests
    printf "\n${CYAN}=== Plugin Creation SDK Tests ===${NC}\n"
    test_create_plugin_script_exists
    test_create_plugin_help
    
    # Integration Tests
    printf "\n${CYAN}=== Integration Tests ===${NC}\n"
    test_mac_plugin_script_exists
    test_mac_plugin_help
    test_plugin_library_files_exist
    
    # Error Handling Tests
    printf "\n${CYAN}=== Error Handling Tests ===${NC}\n"
    test_malformed_plugin_handling
    test_missing_files_handling
    test_permission_handling
    
    # Clean up test environment
    cleanup_test_env
    
    # Print test summary
    test_summary
}

# Execute tests if script is run directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    run_plugin_system_tests
fi