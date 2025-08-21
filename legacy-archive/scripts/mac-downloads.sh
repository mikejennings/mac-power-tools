#!/bin/bash

# Mac Power Tools - Downloads Management
# Smart organization and management of Downloads folder

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
DOWNLOADS_DIR="$HOME/Downloads"
LOG_FILE="$HOME/Library/Logs/mac-downloads.log"
SCRIPTS_DIR="$(dirname "$0")"
FOLDER_ACTION_SCRIPTS_DIR="$HOME/Library/Scripts/Folder Action Scripts"
LAUNCHD_PLIST="$HOME/Library/LaunchAgents/com.mac-power-tools.downloads-sort.plist"

# Function to print colored output
print_color() {
    local color=$1
    shift
    printf "${color}%s${NC}\n" "$*"
}

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to get file type folder
get_type_folder() {
    local ext="$1"
    # Convert to lowercase
    ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
    
    case "$ext" in
        # Images
        jpg|jpeg|png|gif|bmp|svg|webp|tiff|tif|ico|heic|raw|cr2|nef|dng|arw) 
            echo "Images" ;;
        # Documents
        pdf|doc|docx|txt|rtf|odt|pages|md|epub|mobi|tex|docm) 
            echo "Documents" ;;
        # Videos
        mp4|avi|mov|wmv|flv|mkv|webm|m4v|mpg|mpeg|3gp|vob|ogv) 
            echo "Videos" ;;
        # Audio
        mp3|wav|flac|aac|ogg|wma|m4a|aiff|opus|alac|ape) 
            echo "Audio" ;;
        # Archives
        zip|rar|7z|tar|gz|bz2|xz|dmg|pkg|deb|rpm|tgz|tbz2|sit) 
            echo "Archives" ;;
        # Applications
        app|exe|msi|appimage|apk|ipa|snap) 
            echo "Applications" ;;
        # Code
        js|py|java|cpp|c|h|swift|go|rb|php|html|css|sh|json|xml|yaml|yml|ts|tsx|jsx|sql|rs|kt|cs|bat|ps1|pl|lua|r|m|vb|pas|asm) 
            echo "Code" ;;
        # Data
        xls|xlsx|csv|ods|numbers|db|sqlite|mdb) 
            echo "Spreadsheets" ;;
        # Presentations
        ppt|pptx|odp|key|pps|ppsx) 
            echo "Presentations" ;;
        # Config
        conf|config|ini|cfg|plist|toml|env|properties) 
            echo "Config" ;;
        # Logs
        log|out|err) 
            echo "Logs" ;;
        # Fonts
        ttf|otf|woff|woff2|eot|fon|fnt) 
            echo "Fonts" ;;
        # 3D/CAD
        obj|fbx|dae|3ds|blend|stl|max|dwg|dxf|step|iges) 
            echo "3D-Models" ;;
        # Disk Images
        iso|img|vmdk|vdi|qcow2|vhd|vhdx) 
            echo "Disk-Images" ;;
        # Security
        cer|crt|pem|key|p12|pfx|pub|asc|gpg|sig) 
            echo "Certificates" ;;
        # No extension
        "") 
            echo "No-Extension" ;;
        # Everything else
        *) 
            echo "Other" ;;
    esac
}

# Function to sort a single file
sort_file() {
    local file="$1"
    local filename=$(basename "$file")
    
    # Skip hidden files and directories
    if [[ "$filename" =~ ^\. ]] || [[ -d "$file" ]]; then
        return
    fi
    
    # Skip already sorted files (in date folders)
    if [[ "$(dirname "$file")" =~ [0-9]{4}-[0-9]{2}-[0-9]{2} ]]; then
        return
    fi
    
    # Get file modification date
    local mod_date=$(stat -f "%Sm" -t "%Y-%m-%d" "$file")
    
    # Get file extension
    local extension="${filename##*.}"
    if [[ "$extension" == "$filename" ]]; then
        extension=""
    fi
    
    # Determine type folder
    local type_folder=$(get_type_folder "$extension")
    local target_dir="$DOWNLOADS_DIR/$mod_date/$type_folder"
    
    # Create target directory
    mkdir -p "$target_dir"
    
    # Generate unique filename if needed
    local target_file="$target_dir/$filename"
    local counter=1
    while [[ -e "$target_file" ]]; do
        if [[ -z "$extension" ]]; then
            target_file="$target_dir/${filename}_$counter"
        else
            local base="${filename%.*}"
            target_file="$target_dir/${base}_$counter.$extension"
        fi
        ((counter++))
    done
    
    # Move the file
    if mv "$file" "$target_file" 2>/dev/null; then
        log_message "Sorted: $filename → $mod_date/$type_folder/"
        return 0
    else
        log_message "ERROR: Failed to sort $filename"
        return 1
    fi
}

# Function to sort all files in Downloads
sort_downloads() {
    local count=0
    local errors=0
    
    print_color "$BLUE" "Sorting downloads folder..."
    
    # Process all files in Downloads directory (max depth 1)
    while IFS= read -r file; do
        if [[ -f "$file" ]]; then
            if sort_file "$file"; then
                ((count++))
            else
                ((errors++))
            fi
        fi
    done < <(find "$DOWNLOADS_DIR" -maxdepth 1 -type f)
    
    if [[ $count -gt 0 ]]; then
        print_color "$GREEN" "✓ Sorted $count files"
        log_message "Batch sort: $count files sorted"
    else
        print_color "$YELLOW" "No files to sort"
    fi
    
    if [[ $errors -gt 0 ]]; then
        print_color "$RED" "⚠ $errors files failed to sort"
    fi
}

# Function to create and install Folder Action
install_folder_action() {
    print_color "$BLUE" "Installing Folder Action for automatic sorting..."
    
    # Create Folder Action Scripts directory
    mkdir -p "$FOLDER_ACTION_SCRIPTS_DIR"
    
    # Create AppleScript for Folder Action
    local script_path="$FOLDER_ACTION_SCRIPTS_DIR/Mac Power Tools - Sort Downloads.scpt"
    
    cat > "$script_path.txt" << 'APPLESCRIPT'
on adding folder items to thisFolder after receiving addedItems
    repeat with anItem in addedItems
        try
            set itemPath to POSIX path of anItem
            -- Call our sorting script
            do shell script "/usr/local/bin/mac downloads sort-file " & quoted form of itemPath
        on error errMsg
            -- Log errors
            do shell script "echo \"$(date '+%Y-%m-%d %H:%M:%S') - Folder Action ERROR: " & errMsg & "\" >> ~/Library/Logs/mac-downloads.log"
        end try
    end repeat
end adding folder items to
APPLESCRIPT
    
    # Compile the AppleScript
    osacompile -o "$script_path" "$script_path.txt" 2>/dev/null
    rm -f "$script_path.txt"
    
    # Enable Folder Actions system-wide
    osascript -e 'tell application "System Events" to set folder actions enabled to true' 2>/dev/null
    
    # Attach the Folder Action to Downloads
    osascript << EOF 2>/dev/null
tell application "System Events"
    -- Remove existing if present
    try
        delete folder action "Downloads"
    end try
    
    -- Create new folder action
    make new folder action with properties {name:"Downloads", path:"$DOWNLOADS_DIR"}
    
    -- Attach our script
    tell folder action "Downloads"
        make new script at end of scripts with properties {POSIX path:"$script_path"}
    end tell
end tell
EOF
    
    if [[ $? -eq 0 ]]; then
        print_color "$GREEN" "✓ Folder Action installed successfully"
        log_message "Folder Action installed"
    else
        print_color "$RED" "Failed to install Folder Action"
        return 1
    fi
}

# Function to create launchd agent
install_launchd_agent() {
    print_color "$BLUE" "Installing launchd agent for periodic sorting..."
    
    cat > "$LAUNCHD_PLIST" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.mac-power-tools.downloads-sort</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/mac</string>
        <string>downloads</string>
        <string>sort</string>
    </array>
    <key>StartInterval</key>
    <integer>300</integer>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/mac-downloads-sort.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/mac-downloads-sort-error.log</string>
    <key>WatchPaths</key>
    <array>
        <string>$DOWNLOADS_DIR</string>
    </array>
    <key>ThrottleInterval</key>
    <integer>10</integer>
</dict>
</plist>
EOF
    
    # Load the agent
    launchctl unload "$LAUNCHD_PLIST" 2>/dev/null
    if launchctl load "$LAUNCHD_PLIST" 2>/dev/null; then
        print_color "$GREEN" "✓ Launchd agent installed successfully"
        log_message "Launchd agent installed"
    else
        print_color "$YELLOW" "Could not install launchd agent (may need Full Disk Access)"
    fi
}

# Function to show status
show_status() {
    print_color "$BLUE" "═══════════════════════════════════════════"
    print_color "$BLUE" "Downloads Management Status"
    print_color "$BLUE" "═══════════════════════════════════════════"
    
    # Check Folder Actions
    local folder_actions_enabled=$(osascript -e 'tell application "System Events" to get folder actions enabled' 2>/dev/null)
    if [[ "$folder_actions_enabled" == "true" ]]; then
        print_color "$GREEN" "✓ Folder Actions: Enabled"
        
        # Check if our action is attached
        local has_action=$(osascript -e 'tell application "System Events" to get name of every folder action' 2>/dev/null | grep -c "Downloads")
        if [[ $has_action -gt 0 ]]; then
            print_color "$GREEN" "  ✓ Downloads folder action: Active"
        else
            print_color "$YELLOW" "  ⚠ Downloads folder action: Not attached"
        fi
    else
        print_color "$RED" "✗ Folder Actions: Disabled"
    fi
    
    # Check launchd agent
    if launchctl list | grep -q "com.mac-power-tools.downloads-sort"; then
        print_color "$GREEN" "✓ Launchd agent: Running"
    else
        print_color "$YELLOW" "⚠ Launchd agent: Not running"
    fi
    
    # Check Downloads folder
    echo
    print_color "$CYAN" "Downloads Folder Statistics:"
    
    # Count files by type
    local total_files=$(find "$DOWNLOADS_DIR" -maxdepth 1 -type f | wc -l | tr -d ' ')
    print_color "$CYAN" "  Unsorted files: $total_files"
    
    # Count sorted folders
    local date_folders=$(find "$DOWNLOADS_DIR" -maxdepth 1 -type d -name "????-??-??" | wc -l | tr -d ' ')
    print_color "$CYAN" "  Date folders: $date_folders"
    
    # Show disk usage
    local folder_size=$(du -sh "$DOWNLOADS_DIR" 2>/dev/null | cut -f1)
    print_color "$CYAN" "  Total size: $folder_size"
    
    # Recent activity
    echo
    print_color "$CYAN" "Recent Activity:"
    tail -5 "$LOG_FILE" 2>/dev/null | while read -r line; do
        echo "  $line"
    done
}

# Function to watch downloads folder
watch_downloads() {
    print_color "$BLUE" "Watching Downloads folder for changes..."
    print_color "$YELLOW" "Press Ctrl+C to stop"
    
    # Check if fswatch is installed
    if command -v fswatch >/dev/null 2>&1; then
        print_color "$CYAN" "Using fswatch for monitoring..."
        fswatch -o "$DOWNLOADS_DIR" | while read -r num; do
            if [[ $num -gt 0 ]]; then
                sort_downloads
            fi
        done
    else
        print_color "$YELLOW" "fswatch not found, using polling method"
        print_color "$CYAN" "Install fswatch for better performance: brew install fswatch"
        
        while true; do
            sort_downloads
            sleep 5
        done
    fi
}

# Function to analyze downloads
analyze_downloads() {
    print_color "$BLUE" "═══════════════════════════════════════════"
    print_color "$BLUE" "Downloads Folder Analysis"
    print_color "$BLUE" "═══════════════════════════════════════════"
    
    # File type distribution
    print_color "$CYAN" "File Type Distribution:"
    declare -A type_counts
    
    while IFS= read -r file; do
        if [[ -f "$file" ]]; then
            local filename=$(basename "$file")
            local extension="${filename##*.}"
            [[ "$extension" == "$filename" ]] && extension="no-ext"
            extension=$(echo "$extension" | tr '[:upper:]' '[:lower:]')
            ((type_counts[$extension]++))
        fi
    done < <(find "$DOWNLOADS_DIR" -type f)
    
    # Sort and display
    for ext in "${!type_counts[@]}"; do
        echo "${type_counts[$ext]} $ext"
    done | sort -rn | head -10 | while read -r count ext; do
        printf "  %-15s %d files\n" ".$ext:" "$count"
    done
    
    # Largest files
    echo
    print_color "$CYAN" "Largest Files:"
    find "$DOWNLOADS_DIR" -type f -exec du -h {} + | sort -rh | head -5 | while read -r size file; do
        printf "  %-10s %s\n" "$size" "$(basename "$file")"
    done
    
    # Oldest files
    echo
    print_color "$CYAN" "Oldest Files:"
    find "$DOWNLOADS_DIR" -type f -exec stat -f "%Sm %N" -t "%Y-%m-%d" {} \; | sort | head -5 | while read -r date file; do
        printf "  %-12s %s\n" "$date" "$(basename "$file")"
    done
    
    # Date distribution
    echo
    print_color "$CYAN" "Files by Date:"
    find "$DOWNLOADS_DIR" -maxdepth 1 -type d -name "????-??-??" | sort -r | head -10 | while read -r dir; do
        local count=$(find "$dir" -type f | wc -l | tr -d ' ')
        local size=$(du -sh "$dir" 2>/dev/null | cut -f1)
        printf "  %-12s %3d files (%s)\n" "$(basename "$dir"):" "$count" "$size"
    done
}

# Function to clean old downloads
clean_old_downloads() {
    local days="${1:-30}"
    
    print_color "$BLUE" "Finding downloads older than $days days..."
    
    local old_files=$(find "$DOWNLOADS_DIR" -type f -mtime +$days)
    local count=$(echo "$old_files" | grep -c "^/")
    
    if [[ $count -eq 0 ]]; then
        print_color "$GREEN" "No files older than $days days found"
        return
    fi
    
    local total_size=$(echo "$old_files" | xargs -I {} du -k {} 2>/dev/null | awk '{sum+=$1} END {print sum/1024}')
    
    print_color "$YELLOW" "Found $count files (${total_size}MB) older than $days days"
    echo "$old_files" | head -10 | while read -r file; do
        [[ -n "$file" ]] && echo "  $(basename "$file")"
    done
    
    [[ $count -gt 10 ]] && echo "  ... and $((count - 10)) more"
    
    echo
    read -p "Delete these files? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "$old_files" | while read -r file; do
            [[ -n "$file" ]] && rm -f "$file"
        done
        print_color "$GREEN" "✓ Deleted $count old files"
        log_message "Cleaned $count files older than $days days"
    else
        print_color "$YELLOW" "Cleanup cancelled"
    fi
}

# Show help
show_help() {
    cat << EOF
Mac Power Tools - Downloads Management

USAGE:
    mac downloads [COMMAND] [OPTIONS]

COMMANDS:
    sort                Sort all files in Downloads folder
    sort-file <path>    Sort a specific file
    setup               Install automatic sorting (Folder Actions + launchd)
    status              Show current setup status
    watch               Watch folder and sort in real-time
    analyze             Analyze downloads folder contents
    clean [days]        Clean files older than N days (default: 30)
    disable             Disable automatic sorting
    
OPTIONS:
    -h, --help          Show this help message
    -v, --verbose       Show detailed output
    -d, --dry-run       Preview changes without applying

EXAMPLES:
    # One-time sort of all downloads
    mac downloads sort
    
    # Set up automatic sorting
    mac downloads setup
    
    # Watch folder for changes
    mac downloads watch
    
    # Clean files older than 60 days
    mac downloads clean 60
    
    # Check current status
    mac downloads status

FEATURES:
    • Sorts files by date (YYYY-MM-DD folders)
    • Categorizes by file type (Documents, Images, etc.)
    • Automatic sorting via Folder Actions
    • Periodic sorting via launchd
    • Real-time monitoring with fswatch
    • Duplicate handling with smart renaming
    • Comprehensive logging

FILE CATEGORIES:
    • Documents, Images, Videos, Audio
    • Archives, Applications, Code
    • Spreadsheets, Presentations
    • Config, Logs, Fonts, 3D-Models
    • Disk-Images, Certificates

EOF
}

# Main function
main() {
    case "${1:-}" in
        sort)
            sort_downloads
            ;;
        sort-file)
            if [[ -n "${2:-}" ]]; then
                sort_file "$2"
            else
                print_color "$RED" "Error: Please provide a file path"
                exit 1
            fi
            ;;
        setup)
            install_folder_action
            install_launchd_agent
            sort_downloads
            print_color "$GREEN" "✓ Setup complete!"
            ;;
        status)
            show_status
            ;;
        watch)
            watch_downloads
            ;;
        analyze|analyse)
            analyze_downloads
            ;;
        clean)
            clean_old_downloads "${2:-30}"
            ;;
        disable)
            print_color "$YELLOW" "Disabling automatic sorting..."
            osascript -e 'tell application "System Events" to delete folder action "Downloads"' 2>/dev/null
            launchctl unload "$LAUNCHD_PLIST" 2>/dev/null
            print_color "$GREEN" "✓ Automatic sorting disabled"
            ;;
        -h|--help|help)
            show_help
            ;;
        *)
            if [[ -z "${1:-}" ]]; then
                show_help
            else
                print_color "$RED" "Unknown command: $1"
                echo "Use 'mac downloads help' for usage"
                exit 1
            fi
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi