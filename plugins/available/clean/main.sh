#!/bin/bash

# Native plugin implementation
# Migrated from legacy script to use plugin API

# Source the plugin API
source "${MAC_POWER_TOOLS_HOME}/lib/plugin-api.sh"




# Settings
DRY_RUN=false
VERBOSE=false
QUIET=false
TOTAL_FREED=0

# Categories to clean
CLEAN_XCODE=true
CLEAN_IOS_BACKUPS=true
CLEAN_MAIL=true
CLEAN_BREW=true
CLEAN_NPM=true
CLEAN_PIP=true
CLEAN_GEMS=true
CLEAN_DOCKER=true
CLEAN_SYSTEM_CACHE=true
CLEAN_USER_CACHE=true
CLEAN_LOGS=true
CLEAN_DOWNLOADS=true
CLEAN_TRASH=true

# Function to print colored output
print_color() {
    local color=$1
    shift
    [[ "$QUIET" != true ]] && printf "${color}%s${NC}\n" "$*"
}

# Function to format bytes
format_bytes() {
    local bytes=$1
    
    if [[ $bytes -ge 1073741824 ]]; then
        echo "$((bytes / 1073741824)) GB"
    elif [[ $bytes -ge 1048576 ]]; then
        echo "$((bytes / 1048576)) MB"
    elif [[ $bytes -ge 1024 ]]; then
        echo "$((bytes / 1024)) KB"
    else
        echo "$bytes bytes"
    fi
}

# Function to get directory size
get_size() {
    local path="$1"
    local size=0
    
    if [[ -e "$path" ]]; then
        size=$(du -sk "$path" 2>/dev/null | cut -f1)
        echo $((size * 1024))
    else
        echo 0
    fi
}

# Function to clean directory/file
clean_path() {
    local path="$1"
    local description="$2"
    local size_before=$(get_size "$path")
    
    if [[ $size_before -eq 0 ]]; then
        [[ "$VERBOSE" == true ]] && print_warning "  ⊘ $description - not found"
        return 0
    fi
    
    local human_size=$(format_bytes $size_before)
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "  [DRY RUN] Would clean: $description ($human_size)"
        ((TOTAL_FREED += size_before))
        return 0
    fi
    
    # Remove the path
    if [[ -d "$path" ]]; then
        if rm -rf "$path" 2>/dev/null; then
            print_success "  ✓ Cleaned $description ($human_size)"
            ((TOTAL_FREED += size_before))
        else
            print_error "  ✗ Failed to clean $description"
        fi
    elif [[ -f "$path" ]]; then
        if rm -f "$path" 2>/dev/null; then
            print_success "  ✓ Cleaned $description ($human_size)"
            ((TOTAL_FREED += size_before))
        else
            print_error "  ✗ Failed to clean $description"
        fi
    fi
}

# Function to clean with pattern
clean_pattern() {
    local pattern="$1"
    local description="$2"
    local total_size=0
    local count=0
    
    while IFS= read -r -d '' file; do
        local size=$(get_size "$file")
        ((total_size += size))
        ((count++))
        
        if [[ "$DRY_RUN" != true ]]; then
            rm -rf "$file" 2>/dev/null
        fi
    done < <(find . -name "$pattern" -print0 2>/dev/null)
    
    if [[ $count -gt 0 ]]; then
        local human_size=$(format_bytes $total_size)
        if [[ "$DRY_RUN" == true ]]; then
            print_info "  [DRY RUN] Would clean: $count $description files ($human_size)"
        else
            print_success "  ✓ Cleaned $count $description files ($human_size)"
        fi
        ((TOTAL_FREED += total_size))
    else
        [[ "$VERBOSE" == true ]] && print_warning "  ⊘ No $description files found"
    fi
}

# Clean Xcode derived data and junk
clean_xcode() {
    echo
    print_info "🔧 Cleaning Xcode junk..."
    
    # Derived Data
    clean_path "$HOME/Library/Developer/Xcode/DerivedData" "Xcode Derived Data"
    
    # Archives (old)
    local old_archives="$HOME/Library/Developer/Xcode/Archives"
    if [[ -d "$old_archives" ]]; then
        local count=$(find "$old_archives" -type d -mtime +30 2>/dev/null | wc -l)
        if [[ $count -gt 0 ]]; then
            local size=$(find "$old_archives" -type d -mtime +30 -exec du -sk {} \; 2>/dev/null | awk '{sum+=$1} END {print sum*1024}')
            if [[ "$DRY_RUN" == true ]]; then
                print_info "  [DRY RUN] Would clean: $count old Xcode archives (>30 days)"
            else
                find "$old_archives" -type d -mtime +30 -exec rm -rf {} \; 2>/dev/null
                print_success "  ✓ Cleaned $count old Xcode archives"
            fi
            ((TOTAL_FREED += size))
        fi
    fi
    
    # Device Support
    clean_path "$HOME/Library/Developer/Xcode/iOS DeviceSupport" "iOS Device Support"
    clean_path "$HOME/Library/Developer/Xcode/watchOS DeviceSupport" "watchOS Device Support"
    
    # CoreSimulator Caches
    clean_path "$HOME/Library/Developer/CoreSimulator/Caches" "Simulator Caches"
    
    # Old Simulators
    if command -v xcrun &> /dev/null; then
        if [[ "$DRY_RUN" != true ]]; then
            xcrun simctl delete unavailable 2>/dev/null
            print_success "  ✓ Removed unavailable simulators"
        else
            print_info "  [DRY RUN] Would remove unavailable simulators"
        fi
    fi
}

# Clean iOS backups
clean_ios_backups() {
    echo
    print_info "📱 Cleaning iOS backups..."
    
    local backup_dir="$HOME/Library/Application Support/MobileSync/Backup"
    
    if [[ -d "$backup_dir" ]]; then
        local total_size=0
        local count=0
        
        for backup in "$backup_dir"/*; do
            if [[ -d "$backup" ]]; then
                ((count++))
                local size=$(get_size "$backup")
                ((total_size += size))
                
                local backup_name=$(basename "$backup")
                local human_size=$(format_bytes $size)
                
                if [[ "$VERBOSE" == true ]]; then
                    print_warning "  Found backup: $backup_name ($human_size)"
                fi
            fi
        done
        
        if [[ $count -gt 0 ]]; then
            print_warning "  Found $count iOS backup(s) - Total: $(format_bytes $total_size)"
            print_warning "  iOS backups are kept for safety. Remove manually if needed."
        else
            print_success "  ✓ No iOS backups found"
        fi
    fi
}

# Clean Mail attachments and cache
clean_mail() {
    echo
    print_info "✉️  Cleaning Mail cache..."
    
    # Mail Downloads
    clean_path "$HOME/Library/Containers/com.apple.mail/Data/Library/Mail Downloads" "Mail Downloads"
    
    # Mail Data (envelope index)
    local mail_data="$HOME/Library/Mail/V*/MailData/Envelope*"
    for file in $mail_data; do
        if [[ -f "$file" ]]; then
            clean_path "$file" "Mail Envelope Index"
        fi
    done
}

# Clean Homebrew cache
clean_homebrew() {
    echo
    print_info "🍺 Cleaning Homebrew cache..."
    
    if command -v brew &> /dev/null; then
        local cache_size=$(get_size "$(brew --cache)")
        
        if [[ "$DRY_RUN" == true ]]; then
            print_info "  [DRY RUN] Would clean: Homebrew cache ($(format_bytes $cache_size))"
            ((TOTAL_FREED += cache_size))
        else
            brew cleanup -s 2>/dev/null
            brew cleanup --prune=all 2>/dev/null
            print_success "  ✓ Cleaned Homebrew cache ($(format_bytes $cache_size))"
            ((TOTAL_FREED += cache_size))
        fi
    else
        [[ "$VERBOSE" == true ]] && print_warning "  ⊘ Homebrew not installed"
    fi
}

# Clean npm cache
clean_npm() {
    echo
    print_info "📦 Cleaning npm cache..."
    
    if command -v npm &> /dev/null; then
        local cache_dir="$HOME/.npm"
        local cache_size=$(get_size "$cache_dir")
        
        if [[ "$DRY_RUN" == true ]]; then
            print_info "  [DRY RUN] Would clean: npm cache ($(format_bytes $cache_size))"
            ((TOTAL_FREED += cache_size))
        else
            npm cache clean --force 2>/dev/null
            print_success "  ✓ Cleaned npm cache ($(format_bytes $cache_size))"
            ((TOTAL_FREED += cache_size))
        fi
    else
        [[ "$VERBOSE" == true ]] && print_warning "  ⊘ npm not installed"
    fi
}

# Clean pip cache
clean_pip() {
    echo
    print_info "🐍 Cleaning pip cache..."
    
    if command -v pip3 &> /dev/null || command -v pip &> /dev/null; then
        local cache_dir="$HOME/Library/Caches/pip"
        local cache_size=$(get_size "$cache_dir")
        
        if [[ "$DRY_RUN" == true ]]; then
            print_info "  [DRY RUN] Would clean: pip cache ($(format_bytes $cache_size))"
            ((TOTAL_FREED += cache_size))
        else
            if command -v pip3 &> /dev/null; then
                pip3 cache purge 2>/dev/null
            elif command -v pip &> /dev/null; then
                pip cache purge 2>/dev/null
            fi
            print_success "  ✓ Cleaned pip cache ($(format_bytes $cache_size))"
            ((TOTAL_FREED += cache_size))
        fi
    else
        [[ "$VERBOSE" == true ]] && print_warning "  ⊘ pip not installed"
    fi
}

# Clean Ruby gems cache
clean_gems() {
    echo
    print_info "💎 Cleaning Ruby gems cache..."
    
    if command -v gem &> /dev/null; then
        local cache_size=$(get_size "$HOME/.gem")
        
        if [[ "$DRY_RUN" == true ]]; then
            print_info "  [DRY RUN] Would clean: gem cache ($(format_bytes $cache_size))"
            ((TOTAL_FREED += cache_size))
        else
            gem cleanup 2>/dev/null
            print_success "  ✓ Cleaned gem cache"
            ((TOTAL_FREED += cache_size))
        fi
    else
        [[ "$VERBOSE" == true ]] && print_warning "  ⊘ Ruby gems not installed"
    fi
}

# Clean Docker
clean_docker() {
    echo
    print_info "🐳 Cleaning Docker..."
    
    if command -v docker &> /dev/null; then
        if [[ "$DRY_RUN" == true ]]; then
            print_info "  [DRY RUN] Would clean: Docker system"
        else
            docker system prune -af --volumes 2>/dev/null
            print_success "  ✓ Cleaned Docker system"
        fi
    else
        [[ "$VERBOSE" == true ]] && print_warning "  ⊘ Docker not installed"
    fi
}

# Clean system caches
clean_system_cache() {
    echo
    print_info "🗑️  Cleaning system caches..."
    
    # System caches (requires sudo)
    local system_cache="/Library/Caches"
    if [[ -d "$system_cache" ]]; then
        local size=$(get_size "$system_cache")
        print_warning "  System cache: $(format_bytes $size) (requires admin password)"
        
        if [[ "$DRY_RUN" != true ]]; then
            read -p "  Clean system cache? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                sudo rm -rf /Library/Caches/* 2>/dev/null
                print_success "  ✓ Cleaned system cache"
                ((TOTAL_FREED += size))
            fi
        else
            print_info "  [DRY RUN] Would clean system cache"
            ((TOTAL_FREED += size))
        fi
    fi
}

# Clean user caches
clean_user_cache() {
    echo
    print_info "🏠 Cleaning user caches..."
    
    # User cache
    clean_path "$HOME/Library/Caches" "User cache"
    
    # Application specific caches
    clean_path "$HOME/Library/Caches/com.apple.Safari" "Safari cache"
    clean_path "$HOME/Library/Caches/Google/Chrome" "Chrome cache"
    clean_path "$HOME/Library/Caches/Firefox" "Firefox cache"
    clean_path "$HOME/Library/Caches/com.spotify.client" "Spotify cache"
    clean_path "$HOME/Library/Caches/com.apple.iTunes" "iTunes cache"
}

# Clean logs
clean_logs() {
    echo
    print_info "📝 Cleaning old logs..."
    
    # System logs older than 30 days
    if [[ "$DRY_RUN" != true ]]; then
        find /var/log -type f -mtime +30 -exec rm {} \; 2>/dev/null
        find "$HOME/Library/Logs" -type f -mtime +30 -exec rm {} \; 2>/dev/null
        print_success "  ✓ Cleaned logs older than 30 days"
    else
        print_info "  [DRY RUN] Would clean logs older than 30 days"
    fi
    
    # ASL logs
    clean_path "/var/log/asl/*.asl" "ASL logs"
}

# Clean downloads
clean_downloads() {
    echo
    print_info "⬇️  Cleaning old downloads..."
    
    local downloads="$HOME/Downloads"
    local old_count=$(find "$downloads" -type f -mtime +30 2>/dev/null | wc -l)
    
    if [[ $old_count -gt 0 ]]; then
        local old_size=$(find "$downloads" -type f -mtime +30 -exec du -sk {} \; 2>/dev/null | awk '{sum+=$1} END {print sum*1024}')
        print_warning "  Found $old_count files older than 30 days ($(format_bytes $old_size))"
        
        if [[ "$DRY_RUN" != true ]]; then
            read -p "  Move old downloads to trash? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                find "$downloads" -type f -mtime +30 -exec mv {} ~/.Trash/ \; 2>/dev/null
                print_success "  ✓ Moved old downloads to trash"
                ((TOTAL_FREED += old_size))
            fi
        else
            print_info "  [DRY RUN] Would move old downloads to trash"
            ((TOTAL_FREED += old_size))
        fi
    else
        print_success "  ✓ No old downloads found"
    fi
}

# Clean trash
clean_trash() {
    echo
    print_info "🗑️  Cleaning trash..."
    
    local trash_size=$(get_size "$HOME/.Trash")
    
    if [[ $trash_size -gt 0 ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            print_info "  [DRY RUN] Would empty trash ($(format_bytes $trash_size))"
            ((TOTAL_FREED += trash_size))
        else
            rm -rf "$HOME/.Trash/"* 2>/dev/null
            print_success "  ✓ Emptied trash ($(format_bytes $trash_size))"
            ((TOTAL_FREED += trash_size))
        fi
    else
        print_success "  ✓ Trash is already empty"
    fi
}

# Analyze what can be cleaned
analyze_junk() {
    print_info "═══════════════════════════════════════════"
    print_info "Analyzing System Junk..."
    print_info "═══════════════════════════════════════════"
    
    local total=0
    
    # Xcode
    local xcode_size=0
    ((xcode_size += $(get_size "$HOME/Library/Developer/Xcode/DerivedData")))
    ((xcode_size += $(get_size "$HOME/Library/Developer/Xcode/iOS DeviceSupport")))
    ((xcode_size += $(get_size "$HOME/Library/Developer/CoreSimulator/Caches")))
    [[ $xcode_size -gt 0 ]] && print_info "Xcode junk: $(format_bytes $xcode_size)"
    ((total += xcode_size))
    
    # iOS Backups
    local ios_size=$(get_size "$HOME/Library/Application Support/MobileSync/Backup")
    [[ $ios_size -gt 0 ]] && print_info "iOS backups: $(format_bytes $ios_size)"
    ((total += ios_size))
    
    # Caches
    local cache_size=0
    ((cache_size += $(get_size "$HOME/Library/Caches")))
    ((cache_size += $(get_size "$(brew --cache 2>/dev/null)")))
    ((cache_size += $(get_size "$HOME/.npm")))
    [[ $cache_size -gt 0 ]] && print_info "Cache files: $(format_bytes $cache_size)"
    ((total += cache_size))
    
    # Trash
    local trash_size=$(get_size "$HOME/.Trash")
    [[ $trash_size -gt 0 ]] && print_info "Trash: $(format_bytes $trash_size)"
    ((total += trash_size))
    
    print_info "═══════════════════════════════════════════"
    print_warning "Total junk found: $(format_bytes $total)"
    
    return $total
}

# Show help
show_help() {
    cat << EOF
Mac Power Tools - System Junk Cleaner

USAGE:
    mac clean [OPTIONS]
    mac clean --analyze

OPTIONS:
    -h, --help      Show this help message
    -a, --analyze   Analyze junk without cleaning
    -d, --dry-run   Show what would be cleaned
    -q, --quiet     Quiet mode (no output)
    -v, --verbose   Verbose output
    
    Category specific:
    --xcode         Clean only Xcode junk
    --ios           Clean only iOS backups
    --cache         Clean only caches
    --logs          Clean only logs
    --trash         Empty only trash
    
    Skip categories:
    --skip-xcode    Skip Xcode cleaning
    --skip-ios      Skip iOS backup cleaning
    --skip-cache    Skip cache cleaning
    --skip-logs     Skip log cleaning
    --skip-trash    Skip trash cleaning

EXAMPLES:
    mac clean                # Interactive cleaning
    mac clean --analyze      # See what can be cleaned
    mac clean --dry-run      # Preview cleaning
    mac clean --xcode        # Clean only Xcode
    mac clean --skip-ios     # Clean everything except iOS backups

CATEGORIES CLEANED:
    • Xcode derived data and device support
    • iOS device backups (with confirmation)
    • Mail attachments and cache
    • Homebrew, npm, pip, gem caches
    • Docker unused data
    • System and user caches
    • Old log files (>30 days)
    • Old downloads (>30 days, with confirmation)
    • Trash

EOF
}

# Main function
main() {
    local analyze_only=false
    local specific_category=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -a|--analyze)
                analyze_only=true
                shift
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -q|--quiet)
                QUIET=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            --xcode)
                specific_category="xcode"
                shift
                ;;
            --ios)
                specific_category="ios"
                shift
                ;;
            --cache)
                specific_category="cache"
                shift
                ;;
            --logs)
                specific_category="logs"
                shift
                ;;
            --trash)
                specific_category="trash"
                shift
                ;;
            --skip-xcode)
                CLEAN_XCODE=false
                shift
                ;;
            --skip-ios)
                CLEAN_IOS_BACKUPS=false
                shift
                ;;
            --skip-cache)
                CLEAN_SYSTEM_CACHE=false
                CLEAN_USER_CACHE=false
                shift
                ;;
            --skip-logs)
                CLEAN_LOGS=false
                shift
                ;;
            --skip-trash)
                CLEAN_TRASH=false
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Analyze only mode
    if [[ "$analyze_only" == true ]]; then
        analyze_junk
        exit 0
    fi
    
    print_info "═══════════════════════════════════════════"
    print_info "Mac Power Tools - System Junk Cleaner"
    [[ "$DRY_RUN" == true ]] && print_warning "DRY RUN MODE - No files will be deleted"
    print_info "═══════════════════════════════════════════"
    
    # Clean specific category or all
    if [[ -n "$specific_category" ]]; then
        case $specific_category in
            xcode) clean_xcode ;;
            ios) clean_ios_backups ;;
            cache) clean_user_cache; clean_system_cache ;;
            logs) clean_logs ;;
            trash) clean_trash ;;
        esac
    else
        # Clean all categories (respecting skip flags)
        [[ "$CLEAN_XCODE" == true ]] && clean_xcode
        [[ "$CLEAN_IOS_BACKUPS" == true ]] && clean_ios_backups
        [[ "$CLEAN_MAIL" == true ]] && clean_mail
        [[ "$CLEAN_BREW" == true ]] && clean_homebrew
        [[ "$CLEAN_NPM" == true ]] && clean_npm
        [[ "$CLEAN_PIP" == true ]] && clean_pip
        [[ "$CLEAN_GEMS" == true ]] && clean_gems
        [[ "$CLEAN_DOCKER" == true ]] && clean_docker
        [[ "$CLEAN_USER_CACHE" == true ]] && clean_user_cache
        [[ "$CLEAN_SYSTEM_CACHE" == true ]] && clean_system_cache
        [[ "$CLEAN_LOGS" == true ]] && clean_logs
        [[ "$CLEAN_DOWNLOADS" == true ]] && clean_downloads
        [[ "$CLEAN_TRASH" == true ]] && clean_trash
    fi
    
    # Summary
    echo
    print_info "═══════════════════════════════════════════"
    if [[ "$DRY_RUN" == true ]]; then
        print_info "Potential space to free: $(format_bytes $TOTAL_FREED)"
        print_warning "Run without --dry-run to actually clean"
    else
        print_success "✓ Total space freed: $(format_bytes $TOTAL_FREED)"
    fi
    print_info "═══════════════════════════════════════════"
}

# Run main function if script is executed directly

# Plugin main entry point
plugin_main() {
    # Call the main function with all arguments
    main "$@"
}

# Initialize the plugin
plugin_init

# Call the main function if not sourced
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    plugin_main "$@"
fi
