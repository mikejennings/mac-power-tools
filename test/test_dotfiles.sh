#!/bin/bash

# Test suite for mac dotfiles functionality

# Load test helper
source "$(dirname "$0")/test_helper.sh"

# Test dotfiles script exists
test_dotfiles_script_exists() {
    assert_file_exists "../scripts/mac-dotfiles.sh"
    assert_file_executable "../scripts/mac-dotfiles.sh"
}

# Test iCloud detection
test_icloud_detection() {
    local icloud_path="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
    if [[ -d "$icloud_path" ]]; then
        assert_success "iCloud Drive detected"
    else
        skip_test "iCloud Drive not available"
    fi
}

# Test initialization
test_dotfiles_init() {
    # Run init command
    output=$(../scripts/mac-dotfiles.sh init 2>&1)
    
    # Check for success messages
    if echo "$output" | grep -q "initialized"; then
        assert_success "Dotfiles initialized"
    else
        assert_fail "Initialization failed"
    fi
    
    # Check directories were created
    local dotfiles_dir="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Dotfiles"
    local prefs_dir="$HOME/Library/Mobile Documents/com~apple~CloudDocs/AppPreferences"
    
    if [[ -d "$dotfiles_dir" ]]; then
        assert_success "Dotfiles directory created"
    else
        assert_fail "Dotfiles directory not created"
    fi
    
    if [[ -d "$prefs_dir" ]]; then
        assert_success "Preferences directory created"
    else
        assert_fail "Preferences directory not created"
    fi
}

# Test adding a dotfile
test_add_dotfile() {
    # Create a test dotfile
    local test_file="$HOME/.test_dotfile_$$"
    echo "test content" > "$test_file"
    
    # Add it to sync
    output=$(echo ".test_dotfile_$$" | ../scripts/mac-dotfiles.sh add 2>&1)
    
    # Check if symlink was created
    if [[ -L "$test_file" ]]; then
        assert_success "Dotfile symlinked"
        
        # Check if it points to iCloud
        local link_target=$(readlink "$test_file")
        if [[ "$link_target" =~ "CloudDocs" ]]; then
            assert_success "Symlink points to iCloud"
        else
            assert_fail "Symlink doesn't point to iCloud"
        fi
    else
        assert_fail "Dotfile not symlinked"
    fi
    
    # Cleanup
    rm -f "$test_file"
    rm -f "$HOME/Library/Mobile Documents/com~apple~CloudDocs/Dotfiles/.test_dotfile_$$"
}

# Test listing tracked files
test_list_tracked() {
    output=$(../scripts/mac-dotfiles.sh list 2>&1)
    
    if echo "$output" | grep -q "Tracked Dotfiles"; then
        assert_success "List command works"
    else
        assert_fail "List command failed"
    fi
}

# Test help output
test_help_output() {
    output=$(../scripts/mac-dotfiles.sh help 2>&1)
    
    # Check for expected help sections
    if echo "$output" | grep -q "Mac Dotfiles"; then
        assert_success "Help header present"
    else
        assert_fail "Help header missing"
    fi
    
    if echo "$output" | grep -q "USAGE"; then
        assert_success "Usage section present"
    else
        assert_fail "Usage section missing"
    fi
    
    if echo "$output" | grep -q "COMMANDS"; then
        assert_success "Commands section present"
    else
        assert_fail "Commands section missing"
    fi
}

# Test backup functionality
test_backup_dotfiles() {
    # Create a test dotfile
    local test_file="$HOME/.test_backup_$$"
    echo "backup test" > "$test_file"
    
    # Run backup
    output=$(echo "n" | ../scripts/mac-dotfiles.sh backup 2>&1)
    
    # Check if backup ran
    if echo "$output" | grep -q "Backing Up Dotfiles"; then
        assert_success "Backup command executed"
    else
        assert_fail "Backup command failed"
    fi
    
    # Cleanup
    rm -f "$test_file"
}

# Test invalid command handling
test_invalid_command() {
    output=$(../scripts/mac-dotfiles.sh invalid_command 2>&1)
    
    if echo "$output" | grep -q "Unknown command"; then
        assert_success "Invalid command handled properly"
    else
        assert_fail "Invalid command not handled"
    fi
}

# Run all tests
run_test_suite "Dotfiles Tests" \
    test_dotfiles_script_exists \
    test_icloud_detection \
    test_dotfiles_init \
    test_add_dotfile \
    test_list_tracked \
    test_help_output \
    test_backup_dotfiles \
    test_invalid_command