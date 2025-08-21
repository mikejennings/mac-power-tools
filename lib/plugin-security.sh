#!/bin/bash

# Plugin Security - Validation and sandboxing for plugins

# Security configuration
PLUGIN_SECURITY_ENABLED=${PLUGIN_SECURITY_ENABLED:-true}
PLUGIN_ALLOW_UNSIGNED=${PLUGIN_ALLOW_UNSIGNED:-false}
PLUGIN_TRUSTED_SOURCES=(
    "https://github.com/mac-power-tools/"
    "https://github.com/mikejennings/"
)

# Dangerous patterns to check for
DANGEROUS_PATTERNS=(
    "rm -rf /"
    "rm -rf ~"
    ":(){ :|:& };:"  # Fork bomb
    "> /dev/sda"
    "dd if=/dev/zero"
    "mkfs."
    "chmod -R 777 /"
    "curl.*\|.*sh"   # Curl pipe to shell
    "wget.*\|.*sh"   # Wget pipe to shell
)

# Safe commands whitelist (for strict mode)
SAFE_COMMANDS=(
    "echo" "printf" "print"
    "grep" "sed" "awk" "cut"
    "find" "ls" "cat" "head" "tail"
    "sort" "uniq" "wc"
    "date" "basename" "dirname"
    "test" "[" "[[" 
)

# Validate plugin before loading
validate_plugin() {
    local plugin_path=$1
    
    if [ "$PLUGIN_SECURITY_ENABLED" != "true" ]; then
        return 0
    fi
    
    # Check if plugin directory exists
    if [ ! -d "$plugin_path" ]; then
        print_error "Plugin directory not found: $plugin_path"
        return 1
    fi
    
    # Validate plugin structure
    if ! validate_plugin_structure "$plugin_path"; then
        return 1
    fi
    
    # Check for dangerous patterns
    if ! scan_for_dangerous_patterns "$plugin_path"; then
        return 1
    fi
    
    # Verify plugin signature if required
    if [ "$PLUGIN_ALLOW_UNSIGNED" != "true" ]; then
        if ! verify_plugin_signature "$plugin_path"; then
            print_warning "Plugin is unsigned: $(basename "$plugin_path")"
            if ! confirm "Load unsigned plugin?"; then
                return 1
            fi
        fi
    fi
    
    # Check plugin permissions
    if ! check_plugin_permissions "$plugin_path"; then
        return 1
    fi
    
    return 0
}

# Validate plugin structure
validate_plugin_structure() {
    local plugin_path=$1
    local errors=0
    
    # Check for required files
    if [ ! -f "$plugin_path/plugin.json" ]; then
        print_error "Missing plugin.json in $plugin_path"
        ((errors++))
    fi
    
    if [ ! -f "$plugin_path/main.sh" ]; then
        print_error "Missing main.sh in $plugin_path"
        ((errors++))
    fi
    
    if [ ! -f "$plugin_path/README.md" ]; then
        print_error "Missing README.md in $plugin_path - documentation is required"
        ((errors++))
    fi
    
    # Validate plugin.json
    if [ -f "$plugin_path/plugin.json" ]; then
        if ! validate_plugin_json "$plugin_path/plugin.json"; then
            ((errors++))
        fi
    fi
    
    return $errors
}

# Validate plugin.json format
validate_plugin_json() {
    local json_file=$1
    
    # Check if jq is available for proper JSON parsing
    if command -v jq &> /dev/null; then
        if ! jq empty "$json_file" 2>/dev/null; then
            print_error "Invalid JSON in $json_file"
            return 1
        fi
        
        # Check required fields
        local name=$(jq -r '.name // empty' "$json_file")
        local version=$(jq -r '.version // empty' "$json_file")
        
        if [ -z "$name" ]; then
            print_error "Missing 'name' field in plugin.json"
            return 1
        fi
        
        if [ -z "$version" ]; then
            print_error "Missing 'version' field in plugin.json"
            return 1
        fi
    else
        # Fallback to basic validation
        if ! grep -q '"name"' "$json_file"; then
            print_error "Missing 'name' field in plugin.json"
            return 1
        fi
        
        if ! grep -q '"version"' "$json_file"; then
            print_error "Missing 'version' field in plugin.json"
            return 1
        fi
    fi
    
    return 0
}

# Scan for dangerous patterns in plugin code
scan_for_dangerous_patterns() {
    local plugin_path=$1
    local found_dangerous=false
    
    # Find all shell scripts in the plugin
    local scripts=$(find "$plugin_path" -type f \( -name "*.sh" -o -name "*.bash" \) 2>/dev/null)
    
    for script in $scripts; do
        for pattern in "${DANGEROUS_PATTERNS[@]}"; do
            if grep -q "$pattern" "$script" 2>/dev/null; then
                print_error "Dangerous pattern found in $script: $pattern"
                found_dangerous=true
            fi
        done
        
        # Check for suspicious network operations
        if grep -E "(curl|wget|nc|telnet).*[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" "$script" 2>/dev/null; then
            print_warning "Suspicious network operation in $script"
        fi
        
        # Check for base64 encoded content (could hide malicious code)
        if grep -E "base64.*-d|base64.*--decode" "$script" 2>/dev/null; then
            print_warning "Base64 decoding found in $script"
        fi
    done
    
    if $found_dangerous; then
        return 1
    fi
    
    return 0
}

# Verify plugin signature
verify_plugin_signature() {
    local plugin_path=$1
    local signature_file="$plugin_path/.signature"
    local checksum_file="$plugin_path/.checksum"
    
    # For now, use simple checksum verification
    # In production, implement GPG signing
    
    if [ ! -f "$checksum_file" ]; then
        # No signature file means unsigned
        return 1
    fi
    
    # Verify checksum
    local current_checksum=$(calculate_plugin_checksum "$plugin_path")
    local stored_checksum=$(cat "$checksum_file" 2>/dev/null)
    
    if [ "$current_checksum" != "$stored_checksum" ]; then
        print_error "Plugin checksum mismatch - possible tampering"
        return 1
    fi
    
    return 0
}

# Calculate plugin checksum
calculate_plugin_checksum() {
    local plugin_path=$1
    
    # Calculate checksum of all .sh and .json files
    if command -v sha256sum &> /dev/null; then
        find "$plugin_path" -type f \( -name "*.sh" -o -name "*.json" \) \
            -not -path "*/.git/*" -not -name ".checksum" -not -name ".signature" \
            -exec sha256sum {} \; | sort | sha256sum | cut -d' ' -f1
    elif command -v shasum &> /dev/null; then
        find "$plugin_path" -type f \( -name "*.sh" -o -name "*.json" \) \
            -not -path "*/.git/*" -not -name ".checksum" -not -name ".signature" \
            -exec shasum -a 256 {} \; | sort | shasum -a 256 | cut -d' ' -f1
    else
        echo "no-checksum-tool-available"
    fi
}

# Check plugin file permissions
check_plugin_permissions() {
    local plugin_path=$1
    local errors=0
    
    # Check that plugin files are not world-writable
    local world_writable=$(find "$plugin_path" -type f -perm -002 2>/dev/null)
    if [ -n "$world_writable" ]; then
        print_error "World-writable files found in plugin:"
        echo "$world_writable"
        ((errors++))
    fi
    
    # Check that main.sh is executable
    if [ -f "$plugin_path/main.sh" ] && [ ! -x "$plugin_path/main.sh" ]; then
        print_warning "main.sh is not executable, fixing..."
        chmod +x "$plugin_path/main.sh"
    fi
    
    return $errors
}

# Sign a plugin (for plugin developers)
sign_plugin() {
    local plugin_path=$1
    
    if [ ! -d "$plugin_path" ]; then
        print_error "Plugin directory not found: $plugin_path"
        return 1
    fi
    
    print_info "Signing plugin: $(basename "$plugin_path")"
    
    # Calculate and store checksum
    local checksum=$(calculate_plugin_checksum "$plugin_path")
    echo "$checksum" > "$plugin_path/.checksum"
    
    # In production, also create GPG signature
    # gpg --sign --armor --output "$plugin_path/.signature" "$plugin_path/.checksum"
    
    print_success "Plugin signed successfully"
    return 0
}

# Check if source is trusted
is_trusted_source() {
    local source=$1
    
    for trusted in "${PLUGIN_TRUSTED_SOURCES[@]}"; do
        if [[ "$source" == ${trusted}* ]]; then
            return 0
        fi
    done
    
    return 1
}

# Sandbox plugin execution (basic isolation)
sandbox_plugin() {
    local plugin_path=$1
    shift
    local args="$@"
    
    # Create temporary directory for plugin execution
    local sandbox_dir=$(mktemp -d)
    trap "rm -rf $sandbox_dir" EXIT
    
    # Set restricted environment
    (
        # Limit PATH to safe directories
        export PATH="/usr/bin:/bin"
        
        # Set home to sandbox
        export HOME="$sandbox_dir"
        
        # Disable potentially dangerous variables
        unset LD_PRELOAD
        unset LD_LIBRARY_PATH
        unset DYLD_INSERT_LIBRARIES
        
        # Change to sandbox directory
        cd "$sandbox_dir"
        
        # Execute plugin with limited permissions
        # In production, use additional sandboxing like firejail or docker
        "$plugin_path/main.sh" "$args"
    )
    
    local exit_code=$?
    rm -rf "$sandbox_dir"
    return $exit_code
}

# Export functions for use by other scripts
export -f validate_plugin
export -f verify_plugin_signature
export -f sign_plugin
export -f is_trusted_source