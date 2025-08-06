#!/bin/bash

# Mac Power Tools - Duplicate File Finder
# Finds and manages duplicate files to free up disk space

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Default settings
SEARCH_PATH="${1:-$HOME}"
MIN_SIZE=1024  # Minimum file size in bytes (default 1KB)
USE_MD5=false
DRY_RUN=false
VERBOSE=false
INTERACTIVE=false
AUTO_DELETE=false
KEEP_NEWEST=false
KEEP_OLDEST=false

# Temporary files for processing
TEMP_DIR=$(mktemp -d "/tmp/mac-duplicates.XXXXXX")
HASH_FILE="$TEMP_DIR/hashes.txt"
DUPLICATES_FILE="$TEMP_DIR/duplicates.txt"
SUMMARY_FILE="$TEMP_DIR/summary.txt"

# Cleanup function
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Function to print colored output
print_color() {
    local color=$1
    shift
    printf "${color}%s${NC}\n" "$*"
}

# Function to format bytes to human readable
format_bytes() {
    local bytes=$1
    
    if [[ $bytes -ge 1073741824 ]]; then
        echo "$(( bytes / 1073741824 )) GB"
    elif [[ $bytes -ge 1048576 ]]; then
        echo "$(( bytes / 1048576 )) MB"
    elif [[ $bytes -ge 1024 ]]; then
        echo "$(( bytes / 1024 )) KB"
    else
        echo "$bytes bytes"
    fi
}

# Function to calculate file hash
calculate_hash() {
    local file="$1"
    local hash=""
    
    if [[ "$USE_MD5" == true ]]; then
        # Full MD5 hash (slower but more accurate)
        if command -v md5sum > /dev/null 2>&1; then
            hash=$(md5sum "$file" 2>/dev/null | cut -d' ' -f1)
        else
            hash=$(md5 -q "$file" 2>/dev/null)
        fi
    else
        # Quick hash using size and first/last bytes
        local size=$(stat -f%z "$file" 2>/dev/null)
        local first_bytes=$(head -c 1024 "$file" 2>/dev/null | md5 -q 2>/dev/null)
        local last_bytes=$(tail -c 1024 "$file" 2>/dev/null | md5 -q 2>/dev/null)
        hash="${size}_${first_bytes}_${last_bytes}"
    fi
    
    echo "$hash"
}

# Function to find duplicate files
find_duplicates() {
    local search_path="$1"
    local file_count=0
    local processed_count=0
    
    print_color "$BLUE" "═══════════════════════════════════════════"
    print_color "$BLUE" "Searching for duplicate files..."
    print_color "$BLUE" "Path: $search_path"
    print_color "$BLUE" "Minimum size: $(format_bytes $MIN_SIZE)"
    [[ "$USE_MD5" == true ]] && print_color "$BLUE" "Using full MD5 hash (accurate but slower)"
    print_color "$BLUE" "═══════════════════════════════════════════"
    
    # Count total files
    print_color "$CYAN" "\nCounting files..."
    file_count=$(find "$search_path" -type f -size +${MIN_SIZE}c 2>/dev/null | wc -l | tr -d ' ')
    print_color "$CYAN" "Found $file_count files to process"
    
    # Process files and calculate hashes
    print_color "$CYAN" "\nCalculating file hashes..."
    
    find "$search_path" -type f -size +${MIN_SIZE}c 2>/dev/null | while read -r file; do
        ((processed_count++))
        
        # Show progress
        if [[ $((processed_count % 100)) -eq 0 ]] || [[ "$VERBOSE" == true ]]; then
            printf "\rProcessing: %d/%d files" "$processed_count" "$file_count"
        fi
        
        # Calculate hash
        local hash=$(calculate_hash "$file")
        
        if [[ -n "$hash" ]]; then
            echo "${hash}|${file}" >> "$HASH_FILE"
        fi
    done
    
    printf "\n"
    
    # Find duplicates by grouping files with same hash
    print_color "$CYAN" "\nAnalyzing duplicates..."
    
    sort "$HASH_FILE" | awk -F'|' '
    {
        hash=$1
        file=$2
        if (hash == prev_hash) {
            if (!(hash in groups)) {
                groups[hash] = prev_file
            }
            groups[hash] = groups[hash] "|" file
        }
        prev_hash = hash
        prev_file = file
    }
    END {
        for (hash in groups) {
            print groups[hash]
        }
    }' > "$DUPLICATES_FILE"
    
    # Count duplicate groups
    local dup_groups=$(wc -l < "$DUPLICATES_FILE" | tr -d ' ')
    
    if [[ $dup_groups -eq 0 ]]; then
        print_color "$GREEN" "\n✓ No duplicate files found!"
        return 0
    fi
    
    print_color "$YELLOW" "\nFound $dup_groups groups of duplicate files"
}

# Function to display duplicates
display_duplicates() {
    local group_num=0
    local total_wasted=0
    local total_files=0
    
    print_color "$BLUE" "\n═══════════════════════════════════════════"
    print_color "$BLUE" "Duplicate Files Report"
    print_color "$BLUE" "═══════════════════════════════════════════"
    
    while IFS= read -r line; do
        ((group_num++))
        
        # Split files
        IFS='|' read -ra files <<< "$line"
        local file_count=${#files[@]}
        ((total_files += file_count - 1))  # Subtract 1 as we keep one copy
        
        # Get file info
        local first_file="${files[0]}"
        local file_size=$(stat -f%z "$first_file" 2>/dev/null || echo 0)
        local wasted_space=$((file_size * (file_count - 1)))
        ((total_wasted += wasted_space))
        
        print_color "$YELLOW" "\n━━━ Group $group_num ($file_count files, $(format_bytes $file_size) each) ━━━"
        print_color "$CYAN" "Potential savings: $(format_bytes $wasted_space)"
        
        # Display each file with modification time
        local newest_file=""
        local newest_time=0
        local oldest_file=""
        local oldest_time=9999999999
        
        for file in "${files[@]}"; do
            if [[ -f "$file" ]]; then
                local mod_time=$(stat -f%m "$file" 2>/dev/null)
                local mod_date=$(stat -f%Sm -t "%Y-%m-%d %H:%M" "$file" 2>/dev/null)
                
                # Track newest and oldest
                if [[ $mod_time -gt $newest_time ]]; then
                    newest_time=$mod_time
                    newest_file="$file"
                fi
                if [[ $mod_time -lt $oldest_time ]]; then
                    oldest_time=$mod_time
                    oldest_file="$file"
                fi
                
                # Mark special files
                local marker=""
                [[ "$file" == "$first_file" ]] && marker=" [FIRST]"
                
                echo "  • $file"
                echo "    Modified: $mod_date$marker"
            fi
        done
        
        # Show newest/oldest
        [[ -n "$newest_file" ]] && print_color "$GREEN" "    Newest: $(basename "$newest_file")"
        [[ -n "$oldest_file" ]] && print_color "$MAGENTA" "    Oldest: $(basename "$oldest_file")"
        
        # Save to summary
        echo "Group $group_num|$file_count|$file_size|$wasted_space|$line" >> "$SUMMARY_FILE"
        
    done < "$DUPLICATES_FILE"
    
    # Display summary
    print_color "$BLUE" "\n═══════════════════════════════════════════"
    print_color "$BLUE" "Summary"
    print_color "$BLUE" "═══════════════════════════════════════════"
    print_color "$YELLOW" "Duplicate groups: $group_num"
    print_color "$YELLOW" "Duplicate files: $total_files"
    print_color "$RED" "Wasted space: $(format_bytes $total_wasted)"
    
    return $total_wasted
}

# Function to interactively handle duplicates
handle_duplicates_interactive() {
    local group_num=0
    local total_deleted=0
    local space_freed=0
    
    print_color "$BLUE" "\n═══════════════════════════════════════════"
    print_color "$BLUE" "Interactive Duplicate Removal"
    print_color "$BLUE" "═══════════════════════════════════════════"
    
    while IFS= read -r line; do
        ((group_num++))
        
        # Parse group info
        IFS='|' read -r group_id file_count file_size wasted_space files <<< "$line"
        IFS='|' read -ra file_array <<< "$files"
        
        print_color "$YELLOW" "\n━━━ Group $group_num ━━━"
        print_color "$CYAN" "Files: $file_count | Size each: $(format_bytes $file_size)"
        
        # Display files with numbers
        local i=0
        for file in "${file_array[@]}"; do
            ((i++))
            echo "  $i) $file"
        done
        
        # Ask user what to do
        echo ""
        echo "Options:"
        echo "  k) Keep all files"
        echo "  n) Keep newest only"
        echo "  o) Keep oldest only"
        echo "  1-$i) Keep only this file (delete others)"
        echo "  s) Skip to next group"
        echo "  q) Quit"
        
        read -p "Your choice: " -n 1 -r choice
        echo ""
        
        case $choice in
            k|K)
                print_color "$GREEN" "Keeping all files"
                ;;
            n|N)
                # Find and keep newest
                local newest_file=""
                local newest_time=0
                
                for file in "${file_array[@]}"; do
                    local mod_time=$(stat -f%m "$file" 2>/dev/null)
                    if [[ $mod_time -gt $newest_time ]]; then
                        newest_time=$mod_time
                        newest_file="$file"
                    fi
                done
                
                for file in "${file_array[@]}"; do
                    if [[ "$file" != "$newest_file" ]]; then
                        delete_file "$file"
                        ((total_deleted++))
                        ((space_freed += file_size))
                    fi
                done
                print_color "$GREEN" "Kept newest: $newest_file"
                ;;
            o|O)
                # Find and keep oldest
                local oldest_file=""
                local oldest_time=9999999999
                
                for file in "${file_array[@]}"; do
                    local mod_time=$(stat -f%m "$file" 2>/dev/null)
                    if [[ $mod_time -lt $oldest_time ]]; then
                        oldest_time=$mod_time
                        oldest_file="$file"
                    fi
                done
                
                for file in "${file_array[@]}"; do
                    if [[ "$file" != "$oldest_file" ]]; then
                        delete_file "$file"
                        ((total_deleted++))
                        ((space_freed += file_size))
                    fi
                done
                print_color "$GREEN" "Kept oldest: $oldest_file"
                ;;
            [1-9])
                # Keep specific file
                if [[ $choice -le $i ]]; then
                    local keep_file="${file_array[$((choice-1))]}"
                    for file in "${file_array[@]}"; do
                        if [[ "$file" != "$keep_file" ]]; then
                            delete_file "$file"
                            ((total_deleted++))
                            ((space_freed += file_size))
                        fi
                    done
                    print_color "$GREEN" "Kept: $keep_file"
                fi
                ;;
            q|Q)
                print_color "$YELLOW" "Quitting..."
                break
                ;;
            *)
                print_color "$YELLOW" "Skipping group"
                ;;
        esac
        
    done < "$SUMMARY_FILE"
    
    # Final summary
    if [[ $total_deleted -gt 0 ]]; then
        print_color "$GREEN" "\n✓ Cleanup complete!"
        print_color "$GREEN" "Files deleted: $total_deleted"
        print_color "$GREEN" "Space freed: $(format_bytes $space_freed)"
    fi
}

# Function to delete file
delete_file() {
    local file="$1"
    
    if [[ "$DRY_RUN" == true ]]; then
        print_color "$CYAN" "[DRY RUN] Would delete: $file"
        return 0
    fi
    
    if [[ -f "$file" ]]; then
        if rm -f "$file" 2>/dev/null; then
            [[ "$VERBOSE" == true ]] && print_color "$GREEN" "Deleted: $file"
            return 0
        else
            print_color "$RED" "Failed to delete: $file"
            return 1
        fi
    fi
}

# Function to auto-delete duplicates
auto_delete_duplicates() {
    local total_deleted=0
    local space_freed=0
    local strategy="$1"
    
    print_color "$BLUE" "\n═══════════════════════════════════════════"
    print_color "$BLUE" "Auto-Deleting Duplicates"
    print_color "$BLUE" "Strategy: Keep $strategy"
    print_color "$BLUE" "═══════════════════════════════════════════"
    
    while IFS= read -r line; do
        IFS='|' read -r group_id file_count file_size wasted_space files <<< "$line"
        IFS='|' read -ra file_array <<< "$files"
        
        local keep_file=""
        
        if [[ "$strategy" == "newest" ]]; then
            # Find newest file
            local newest_time=0
            for file in "${file_array[@]}"; do
                local mod_time=$(stat -f%m "$file" 2>/dev/null)
                if [[ $mod_time -gt $newest_time ]]; then
                    newest_time=$mod_time
                    keep_file="$file"
                fi
            done
        elif [[ "$strategy" == "oldest" ]]; then
            # Find oldest file
            local oldest_time=9999999999
            for file in "${file_array[@]}"; do
                local mod_time=$(stat -f%m "$file" 2>/dev/null)
                if [[ $mod_time -lt $oldest_time ]]; then
                    oldest_time=$mod_time
                    keep_file="$file"
                fi
            done
        else
            # Keep first file by default
            keep_file="${file_array[0]}"
        fi
        
        # Delete all except keep_file
        for file in "${file_array[@]}"; do
            if [[ "$file" != "$keep_file" ]]; then
                if delete_file "$file"; then
                    ((total_deleted++))
                    ((space_freed += file_size))
                fi
            fi
        done
        
    done < "$SUMMARY_FILE"
    
    print_color "$GREEN" "\n✓ Auto-cleanup complete!"
    print_color "$GREEN" "Files deleted: $total_deleted"
    print_color "$GREEN" "Space freed: $(format_bytes $space_freed)"
}

# Show help
show_help() {
    cat << EOF
Mac Power Tools - Duplicate File Finder

USAGE:
    mac duplicates [OPTIONS] [path]

OPTIONS:
    -h, --help          Show this help message
    -m, --md5           Use full MD5 hash (slower but more accurate)
    -s, --min-size SIZE Minimum file size to check (default: 1KB)
    -i, --interactive   Interactive mode - choose which files to keep
    -a, --auto-delete   Automatically delete duplicates (keeps first)
    -n, --keep-newest   Auto-delete keeping newest files
    -o, --keep-oldest   Auto-delete keeping oldest files
    -d, --dry-run       Show what would be deleted without deleting
    -v, --verbose       Show detailed output

ARGUMENTS:
    path               Directory to search (default: home directory)

EXAMPLES:
    mac duplicates                    # Find duplicates in home directory
    mac duplicates ~/Downloads        # Find duplicates in Downloads
    mac duplicates -i ~/Documents     # Interactive removal
    mac duplicates -n ~/Pictures      # Auto-delete keeping newest
    mac duplicates --md5 /Volumes/Backup  # Use full MD5 hash

NOTES:
    • By default, uses quick hash (size + partial content)
    • Use --md5 for 100% accuracy (slower)
    • Interactive mode lets you choose which files to keep
    • Auto-delete modes remove duplicates automatically

EOF
}

# Main function
main() {
    local search_paths=()
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -m|--md5)
                USE_MD5=true
                shift
                ;;
            -s|--min-size)
                MIN_SIZE="$2"
                shift 2
                ;;
            -i|--interactive)
                INTERACTIVE=true
                shift
                ;;
            -a|--auto-delete)
                AUTO_DELETE=true
                shift
                ;;
            -n|--keep-newest)
                AUTO_DELETE=true
                KEEP_NEWEST=true
                shift
                ;;
            -o|--keep-oldest)
                AUTO_DELETE=true
                KEEP_OLDEST=true
                shift
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            *)
                search_paths+=("$1")
                shift
                ;;
        esac
    done
    
    # Set default search path if none provided
    if [[ ${#search_paths[@]} -eq 0 ]]; then
        search_paths=("$HOME")
    fi
    
    # Process each search path
    for path in "${search_paths[@]}"; do
        if [[ ! -d "$path" ]]; then
            print_color "$RED" "Error: Directory not found: $path"
            continue
        fi
        
        # Find duplicates
        find_duplicates "$path"
        
        # Display results
        if [[ -s "$DUPLICATES_FILE" ]]; then
            display_duplicates
            
            # Handle duplicates based on mode
            if [[ "$INTERACTIVE" == true ]]; then
                handle_duplicates_interactive
            elif [[ "$AUTO_DELETE" == true ]]; then
                if [[ "$KEEP_NEWEST" == true ]]; then
                    auto_delete_duplicates "newest"
                elif [[ "$KEEP_OLDEST" == true ]]; then
                    auto_delete_duplicates "oldest"
                else
                    auto_delete_duplicates "first"
                fi
            fi
        fi
    done
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi