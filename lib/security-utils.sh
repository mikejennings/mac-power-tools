#!/bin/bash

# Security Utilities Library for Mac Power Tools
# Provides secure input validation, path sanitization, and command execution

# Prevent multiple sourcing
if [ -n "${SECURITY_UTILS_LOADED:-}" ]; then
    return 0
fi
SECURITY_UTILS_LOADED=true

# Security configuration
readonly SECURITY_VERSION="1.0.0"
readonly MAX_PATH_LENGTH=4096
readonly MAX_INPUT_LENGTH=1024
readonly ALLOWED_CHARS_PATTERN='^[a-zA-Z0-9._/ -]+$'

# Logging configuration
readonly SECURITY_LOG="${MAC_POWER_TOOLS_HOME:-$HOME/.mac-power-tools}/logs/security.log"
readonly LOG_ERRORS=true
readonly LOG_WARNINGS=true

# Initialize security logging
init_security_logging() {
    local log_dir=$(dirname "$SECURITY_LOG")
    if [ ! -d "$log_dir" ]; then
        mkdir -p "$log_dir" 2>/dev/null
    fi
}

# Secure logging function
security_log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [ "$LOG_ERRORS" = true ] && [ "$level" = "ERROR" ]; then
        echo "[$timestamp] [$level] $message" >> "$SECURITY_LOG" 2>/dev/null
    elif [ "$LOG_WARNINGS" = true ] && [ "$level" = "WARNING" ]; then
        echo "[$timestamp] [$level] $message" >> "$SECURITY_LOG" 2>/dev/null
    fi
}

# Validate input length
validate_input_length() {
    local input=$1
    local max_length=${2:-$MAX_INPUT_LENGTH}
    
    if [ ${#input} -gt $max_length ]; then
        security_log "ERROR" "Input exceeds maximum length: ${#input} > $max_length"
        return 1
    fi
    return 0
}

# Validate alphanumeric input with safe characters
validate_safe_input() {
    local input=$1
    local pattern=${2:-$ALLOWED_CHARS_PATTERN}
    
    if ! [[ "$input" =~ $pattern ]]; then
        security_log "WARNING" "Invalid characters in input: $input"
        return 1
    fi
    return 0
}

# Sanitize shell metacharacters
sanitize_input() {
    local input=$1
    
    # Remove or escape dangerous characters
    # This is a restrictive approach - only allow safe characters
    local sanitized=$(echo "$input" | sed 's/[^a-zA-Z0-9._/ -]//g')
    
    # Truncate if too long
    if [ ${#sanitized} -gt $MAX_INPUT_LENGTH ]; then
        sanitized=${sanitized:0:$MAX_INPUT_LENGTH}
    fi
    
    echo "$sanitized"
}

# Validate and canonicalize file paths
validate_path() {
    local path=$1
    local base_dir=${2:-/}
    
    # Check path length
    if [ ${#path} -gt $MAX_PATH_LENGTH ]; then
        security_log "ERROR" "Path exceeds maximum length: $path"
        return 1
    fi
    
    # Reject paths with dangerous patterns
    if echo "$path" | grep -q '\.\./\|\.\.\\'; then
        security_log "ERROR" "Path traversal attempt detected: $path"
        return 1
    fi
    
    # Get canonical path (resolve symlinks and ..)
    local canonical_path
    if [ -e "$path" ]; then
        canonical_path=$(cd "$(dirname "$path")" 2>/dev/null && pwd)/$(basename "$path")
    else
        # For non-existent paths, validate parent directory
        local parent_dir=$(dirname "$path")
        if [ -d "$parent_dir" ]; then
            canonical_path=$(cd "$parent_dir" 2>/dev/null && pwd)/$(basename "$path")
        else
            security_log "ERROR" "Invalid path: $path"
            return 1
        fi
    fi
    
    # Ensure path is within allowed base directory
    if [[ "$canonical_path" != "$base_dir"* ]]; then
        security_log "ERROR" "Path outside allowed directory: $canonical_path not in $base_dir"
        return 1
    fi
    
    echo "$canonical_path"
    return 0
}

# Validate URL format and scheme
validate_url() {
    local url=$1
    local allowed_schemes=${2:-"https"}
    
    # Basic URL validation
    local url_pattern='^(https?|git)://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(/[a-zA-Z0-9._~:/?#@!$&()*+,;=-]*)?$'
    
    if ! [[ "$url" =~ $url_pattern ]]; then
        security_log "ERROR" "Invalid URL format: $url"
        return 1
    fi
    
    # Check allowed schemes
    local scheme=$(echo "$url" | cut -d: -f1)
    if ! echo "$allowed_schemes" | grep -q "$scheme"; then
        security_log "ERROR" "Disallowed URL scheme: $scheme"
        return 1
    fi
    
    # Check for localhost/internal IPs (prevent SSRF)
    if echo "$url" | grep -qE '(localhost|127\.0\.0\.1|0\.0\.0\.0|::1|169\.254\.|10\.|172\.(1[6-9]|2[0-9]|3[01])\.|192\.168\.)'; then
        security_log "WARNING" "Internal URL detected: $url"
        return 1
    fi
    
    return 0
}

# Safe command execution wrapper
safe_exec() {
    local command=$1
    shift
    local args=("$@")
    
    # Validate command exists and is not a shell builtin
    if ! command -v "$command" &> /dev/null; then
        security_log "ERROR" "Command not found: $command"
        return 1
    fi
    
    # Get full path to command
    local cmd_path=$(command -v "$command")
    
    # Check if command is in safe paths
    local safe_paths="/usr/bin /bin /usr/sbin /sbin /usr/local/bin /opt/homebrew/bin"
    local is_safe=false
    for safe_path in $safe_paths; do
        if [[ "$cmd_path" == "$safe_path"/* ]]; then
            is_safe=true
            break
        fi
    done
    
    if [ "$is_safe" != true ]; then
        security_log "WARNING" "Command not in safe path: $cmd_path"
    fi
    
    # Execute with timeout and resource limits
    (
        # Set resource limits
        ulimit -t 300  # CPU time limit (5 minutes)
        ulimit -m 524288  # Memory limit (512MB)
        ulimit -f 1048576  # File size limit (1GB)
        
        # Execute command
        "$cmd_path" "${args[@]}"
    )
}

# Validate sudo usage
validate_sudo() {
    local operation=$1
    
    # Define operations that are allowed to use sudo
    local allowed_sudo_ops=(
        "system_update"
        "package_install"
        "service_restart"
        "cache_clear"
    )
    
    local is_allowed=false
    for allowed_op in "${allowed_sudo_ops[@]}"; do
        if [ "$operation" = "$allowed_op" ]; then
            is_allowed=true
            break
        fi
    done
    
    if [ "$is_allowed" != true ]; then
        security_log "ERROR" "Unauthorized sudo operation: $operation"
        return 1
    fi
    
    # Check if user has sudo privileges without password
    if ! sudo -n true 2>/dev/null; then
        echo "This operation requires administrator privileges."
        return 1
    fi
    
    return 0
}

# Create secure temporary file
secure_temp_file() {
    local prefix=${1:-mac_power_tools}
    local temp_file
    
    # Use mktemp with secure template
    temp_file=$(mktemp -t "${prefix}.XXXXXXXXXX") || {
        security_log "ERROR" "Failed to create temporary file"
        return 1
    }
    
    # Set restrictive permissions
    chmod 600 "$temp_file"
    
    echo "$temp_file"
    return 0
}

# Create secure temporary directory
secure_temp_dir() {
    local prefix=${1:-mac_power_tools}
    local temp_dir
    
    # Use mktemp with secure template
    temp_dir=$(mktemp -d -t "${prefix}.XXXXXXXXXX") || {
        security_log "ERROR" "Failed to create temporary directory"
        return 1
    }
    
    # Set restrictive permissions
    chmod 700 "$temp_dir"
    
    echo "$temp_dir"
    return 0
}

# Validate JSON input
validate_json() {
    local json_input=$1
    
    # Check if jq is available
    if command -v jq &> /dev/null; then
        if ! echo "$json_input" | jq empty 2>/dev/null; then
            security_log "ERROR" "Invalid JSON input"
            return 1
        fi
    else
        # Basic validation without jq
        if ! echo "$json_input" | grep -q '^{.*}$\|^\[.*\]$'; then
            security_log "ERROR" "Invalid JSON format"
            return 1
        fi
    fi
    
    return 0
}

# Sanitize output for display
sanitize_output() {
    local output=$1
    
    # Remove ANSI escape codes
    local clean_output=$(echo "$output" | sed 's/\x1b\[[0-9;]*m//g')
    
    # Truncate if too long
    if [ ${#clean_output} -gt 10000 ]; then
        clean_output="${clean_output:0:10000}...[truncated]"
    fi
    
    # Mask potential sensitive data
    clean_output=$(echo "$clean_output" | sed -E 's/([A-Za-z0-9+/]{40,}|[A-Fa-f0-9]{40,})/[REDACTED]/g')
    clean_output=$(echo "$clean_output" | sed -E 's/(password|token|key|secret)=[^ ]*/\1=[REDACTED]/gi')
    
    echo "$clean_output"
}

# Check file permissions
check_file_permissions() {
    local file=$1
    local expected_perms=${2:-644}
    
    if [ ! -e "$file" ]; then
        security_log "ERROR" "File not found: $file"
        return 1
    fi
    
    # Get current permissions
    local current_perms=$(stat -f "%p" "$file" 2>/dev/null | tail -c 4)
    
    if [ "$current_perms" != "$expected_perms" ]; then
        security_log "WARNING" "Incorrect permissions on $file: $current_perms (expected $expected_perms)"
        return 1
    fi
    
    # Check for world-writable
    if [ -w "$file" ] && [ ! -O "$file" ]; then
        security_log "ERROR" "World-writable file detected: $file"
        return 1
    fi
    
    return 0
}

# Validate plugin source
validate_plugin_source() {
    local source=$1
    
    # Check against trusted sources
    local trusted_sources=(
        "https://github.com/mac-power-tools/"
        "https://github.com/mikejennings/"
    )
    
    local is_trusted=false
    for trusted in "${trusted_sources[@]}"; do
        if [[ "$source" == "$trusted"* ]]; then
            is_trusted=true
            break
        fi
    done
    
    if [ "$is_trusted" != true ]; then
        security_log "WARNING" "Untrusted plugin source: $source"
        echo "Warning: Installing plugin from untrusted source"
        return 1
    fi
    
    return 0
}

# Rate limiting function
check_rate_limit() {
    local operation=$1
    local limit=${2:-10}  # Default 10 operations per minute
    local rate_file="${MAC_POWER_TOOLS_HOME:-$HOME/.mac-power-tools}/.rate_limits/$operation"
    
    mkdir -p "$(dirname "$rate_file")" 2>/dev/null
    
    # Clean old entries (older than 1 minute)
    if [ -f "$rate_file" ]; then
        local current_time=$(date +%s)
        local temp_file=$(mktemp)
        while IFS= read -r timestamp; do
            if [ $((current_time - timestamp)) -lt 60 ]; then
                echo "$timestamp" >> "$temp_file"
            fi
        done < "$rate_file"
        mv "$temp_file" "$rate_file"
    fi
    
    # Count recent operations
    local count=0
    if [ -f "$rate_file" ]; then
        count=$(wc -l < "$rate_file")
    fi
    
    if [ "$count" -ge "$limit" ]; then
        security_log "WARNING" "Rate limit exceeded for operation: $operation"
        return 1
    fi
    
    # Record this operation
    date +%s >> "$rate_file"
    return 0
}

# Initialize security
init_security_logging

# Export functions for use by other scripts
export -f validate_input_length
export -f validate_safe_input
export -f sanitize_input
export -f validate_path
export -f validate_url
export -f safe_exec
export -f validate_sudo
export -f secure_temp_file
export -f secure_temp_dir
export -f validate_json
export -f sanitize_output
export -f check_file_permissions
export -f validate_plugin_source
export -f check_rate_limit
export -f security_log