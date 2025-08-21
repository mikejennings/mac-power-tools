#!/bin/bash

# Plugin Cache - Metadata caching for performance

# Cache configuration
CACHE_DIR="${HOME}/.mac-power-tools/cache"
CACHE_FILE="${CACHE_DIR}/plugin-metadata.json"
CACHE_TTL=3600  # Cache TTL in seconds (1 hour)

# Initialize cache directory
init_cache() {
    mkdir -p "$CACHE_DIR"
    
    # Create empty cache file if it doesn't exist
    if [ ! -f "$CACHE_FILE" ]; then
        echo '{"plugins": {}, "commands": {}, "timestamp": 0}' > "$CACHE_FILE"
    fi
}

# Check if cache is valid
is_cache_valid() {
    if [ ! -f "$CACHE_FILE" ]; then
        return 1
    fi
    
    # Get cache timestamp
    local cache_timestamp
    if command -v jq &> /dev/null; then
        cache_timestamp=$(jq -r '.timestamp // 0' "$CACHE_FILE" 2>/dev/null || echo "0")
    else
        cache_timestamp=$(grep -o '"timestamp"[[:space:]]*:[[:space:]]*[0-9]*' "$CACHE_FILE" | grep -o '[0-9]*$' || echo "0")
    fi
    
    # Check if cache is expired
    local current_time=$(date +%s)
    local age=$((current_time - cache_timestamp))
    
    if [ "$age" -gt "$CACHE_TTL" ]; then
        return 1
    fi
    
    # Check if any plugin directories have been modified
    for plugin_dir in "$PLUGINS_DIR"/core/* "$PLUGINS_DIR"/available/* "$PLUGINS_DIR"/enabled/*; do
        if [ -d "$plugin_dir" ]; then
            # Check if plugin.json is newer than cache
            if [ -f "$plugin_dir/plugin.json" ]; then
                if [ "$plugin_dir/plugin.json" -nt "$CACHE_FILE" ]; then
                    return 1
                fi
            fi
        fi
    done
    
    return 0
}

# Build cache
build_cache() {
    init_cache
    
    local timestamp=$(date +%s)
    local cache_content='{"plugins": {}, "commands": {}, "timestamp": '$timestamp'}'
    
    if command -v jq &> /dev/null; then
        # Use jq for proper JSON building
        cache_content=$(echo '{}' | jq --arg ts "$timestamp" '.timestamp = ($ts | tonumber)')
        
        # Add plugin metadata
        for plugin_dir in "$PLUGINS_DIR"/core/* "$PLUGINS_DIR"/available/*; do
            if [ -d "$plugin_dir" ]; then
                local plugin_name=$(basename "$plugin_dir")
                local metadata_file="$plugin_dir/plugin.json"
                
                if [ -f "$metadata_file" ]; then
                    local metadata=$(cat "$metadata_file")
                    cache_content=$(echo "$cache_content" | jq --arg name "$plugin_name" --argjson meta "$metadata" '.plugins[$name] = $meta')
                    
                    # Map commands to plugins
                    local commands=$(echo "$metadata" | jq -r '.commands[]? // empty' 2>/dev/null)
                    for cmd in $commands; do
                        cache_content=$(echo "$cache_content" | jq --arg cmd "$cmd" --arg plugin "$plugin_name" '.commands[$cmd] = $plugin')
                    done
                fi
            fi
        done
        
        echo "$cache_content" > "$CACHE_FILE"
    else
        # Fallback: simple cache without jq
        {
            echo '{'
            echo '  "timestamp": '$timestamp','
            echo '  "plugins": {'
            
            local first=true
            for plugin_dir in "$PLUGINS_DIR"/core/* "$PLUGINS_DIR"/available/*; do
                if [ -d "$plugin_dir" ]; then
                    local plugin_name=$(basename "$plugin_dir")
                    local metadata_file="$plugin_dir/plugin.json"
                    
                    if [ -f "$metadata_file" ]; then
                        if ! $first; then
                            echo ','
                        fi
                        first=false
                        
                        echo -n '    "'$plugin_name'": '
                        cat "$metadata_file"
                    fi
                fi
            done
            
            echo ''
            echo '  },'
            echo '  "commands": {}'
            echo '}'
        } > "$CACHE_FILE"
    fi
}

# Get plugin metadata from cache
get_cached_plugin_metadata() {
    local plugin_name=$1
    
    if ! is_cache_valid; then
        build_cache
    fi
    
    if command -v jq &> /dev/null; then
        jq -r ".plugins[\"$plugin_name\"] // null" "$CACHE_FILE"
    else
        # Fallback: extract from cache file
        sed -n "/\"$plugin_name\":/,/^[[:space:]]*\"/p" "$CACHE_FILE" | head -n -1
    fi
}

# Get plugin for command from cache
get_plugin_for_command() {
    local command=$1
    
    if ! is_cache_valid; then
        build_cache
    fi
    
    if command -v jq &> /dev/null; then
        jq -r ".commands[\"$command\"] // null" "$CACHE_FILE"
    else
        # Fallback: search for command in metadata
        for plugin_dir in "$PLUGINS_DIR"/core/* "$PLUGINS_DIR"/available/*; do
            if [ -d "$plugin_dir" ]; then
                local metadata_file="$plugin_dir/plugin.json"
                if [ -f "$metadata_file" ] && grep -q "\"$command\"" "$metadata_file"; then
                    basename "$plugin_dir"
                    return 0
                fi
            fi
        done
        
        echo "null"
    fi
}

# Get all plugin commands from cache
get_all_commands_cached() {
    if ! is_cache_valid; then
        build_cache
    fi
    
    if command -v jq &> /dev/null; then
        jq -r '.commands | keys[]' "$CACHE_FILE" 2>/dev/null | sort -u
    else
        # Fallback: get commands from all plugins
        get_plugin_commands
    fi
}

# Invalidate cache
invalidate_cache() {
    rm -f "$CACHE_FILE"
}

# Clear entire cache
clear_cache() {
    rm -rf "$CACHE_DIR"
}

# Get cache statistics
cache_stats() {
    if [ ! -f "$CACHE_FILE" ]; then
        echo "Cache not initialized"
        return
    fi
    
    local size=$(du -h "$CACHE_FILE" | cut -f1)
    local age=0
    
    if command -v jq &> /dev/null; then
        local timestamp=$(jq -r '.timestamp // 0' "$CACHE_FILE")
        local plugin_count=$(jq -r '.plugins | length' "$CACHE_FILE")
        local command_count=$(jq -r '.commands | length' "$CACHE_FILE")
    else
        local timestamp=$(grep -o '"timestamp"[[:space:]]*:[[:space:]]*[0-9]*' "$CACHE_FILE" | grep -o '[0-9]*$' || echo "0")
        local plugin_count=$(grep -c '"name"' "$CACHE_FILE")
        local command_count=0
    fi
    
    if [ "$timestamp" -gt 0 ]; then
        age=$(($(date +%s) - timestamp))
    fi
    
    echo "Cache Statistics:"
    echo "  File: $CACHE_FILE"
    echo "  Size: $size"
    echo "  Age: ${age}s"
    echo "  Plugins: $plugin_count"
    echo "  Commands: $command_count"
    echo "  Valid: $(is_cache_valid && echo "yes" || echo "no")"
}