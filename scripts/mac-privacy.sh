#!/bin/bash

# Mac Power Tools - Privacy & Security Suite
# Comprehensive privacy protection and security auditing

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
LOG_FILE="$HOME/Library/Logs/mac-privacy.log"
DRY_RUN=false
VERBOSE=false

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

# Function to check if running with sudo when needed
check_sudo() {
    if [[ $EUID -ne 0 ]]; then
        print_color "$YELLOW" "Some operations may require administrator privileges"
        return 1
    fi
    return 0
}

# Function to clean Safari
clean_safari() {
    print_color "$BLUE" "Cleaning Safari..."
    
    local cleaned=0
    
    # Safari caches
    if [[ -d "$HOME/Library/Caches/com.apple.Safari" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            print_color "$CYAN" "[DRY RUN] Would remove Safari cache"
        else
            rm -rf "$HOME/Library/Caches/com.apple.Safari"/* 2>/dev/null && ((cleaned++))
        fi
    fi
    
    # Safari history
    if [[ -f "$HOME/Library/Safari/History.db" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            print_color "$CYAN" "[DRY RUN] Would clear Safari history"
        else
            rm -f "$HOME/Library/Safari/History.db"* 2>/dev/null && ((cleaned++))
        fi
    fi
    
    # Downloads history
    if [[ -f "$HOME/Library/Safari/Downloads.plist" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            print_color "$CYAN" "[DRY RUN] Would clear Safari downloads history"
        else
            rm -f "$HOME/Library/Safari/Downloads.plist" 2>/dev/null && ((cleaned++))
        fi
    fi
    
    # Website data
    if [[ -d "$HOME/Library/Safari/LocalStorage" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            print_color "$CYAN" "[DRY RUN] Would clear Safari website data"
        else
            rm -rf "$HOME/Library/Safari/LocalStorage"/* 2>/dev/null && ((cleaned++))
        fi
    fi
    
    # Top sites
    if [[ -f "$HOME/Library/Safari/TopSites.plist" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            print_color "$CYAN" "[DRY RUN] Would clear Safari top sites"
        else
            rm -f "$HOME/Library/Safari/TopSites.plist" 2>/dev/null && ((cleaned++))
        fi
    fi
    
    [[ $cleaned -gt 0 ]] && print_color "$GREEN" "✓ Safari cleaned ($cleaned items)"
    log_message "Safari cleaned: $cleaned items"
}

# Function to clean Chrome
clean_chrome() {
    print_color "$BLUE" "Cleaning Chrome..."
    
    local cleaned=0
    local chrome_dir="$HOME/Library/Application Support/Google/Chrome"
    
    if [[ ! -d "$chrome_dir" ]]; then
        print_color "$YELLOW" "Chrome not found"
        return
    fi
    
    # Chrome cache
    if [[ -d "$chrome_dir/Default/Cache" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            print_color "$CYAN" "[DRY RUN] Would remove Chrome cache"
        else
            rm -rf "$chrome_dir/Default/Cache"/* 2>/dev/null && ((cleaned++))
            rm -rf "$chrome_dir/Default/Code Cache"/* 2>/dev/null && ((cleaned++))
        fi
    fi
    
    # Chrome history
    if [[ -f "$chrome_dir/Default/History" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            print_color "$CYAN" "[DRY RUN] Would clear Chrome history"
        else
            rm -f "$chrome_dir/Default/History"* 2>/dev/null && ((cleaned++))
        fi
    fi
    
    # Downloads history
    if [[ -f "$chrome_dir/Default/Downloads" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            print_color "$CYAN" "[DRY RUN] Would clear Chrome downloads"
        else
            rm -f "$chrome_dir/Default/Downloads"* 2>/dev/null && ((cleaned++))
        fi
    fi
    
    # Cookies (optional)
    # Commented out by default as it logs you out of everything
    # rm -f "$chrome_dir/Default/Cookies"* 2>/dev/null
    
    [[ $cleaned -gt 0 ]] && print_color "$GREEN" "✓ Chrome cleaned ($cleaned items)"
    log_message "Chrome cleaned: $cleaned items"
}

# Function to clean Firefox
clean_firefox() {
    print_color "$BLUE" "Cleaning Firefox..."
    
    local cleaned=0
    local firefox_dir="$HOME/Library/Application Support/Firefox/Profiles"
    
    if [[ ! -d "$firefox_dir" ]]; then
        print_color "$YELLOW" "Firefox not found"
        return
    fi
    
    # Find default profile
    for profile in "$firefox_dir"/*.default*; do
        if [[ -d "$profile" ]]; then
            # Cache
            if [[ -d "$profile/cache2" ]]; then
                if [[ "$DRY_RUN" == true ]]; then
                    print_color "$CYAN" "[DRY RUN] Would remove Firefox cache"
                else
                    rm -rf "$profile/cache2"/* 2>/dev/null && ((cleaned++))
                fi
            fi
            
            # History
            if [[ -f "$profile/places.sqlite" ]]; then
                if [[ "$DRY_RUN" == true ]]; then
                    print_color "$CYAN" "[DRY RUN] Would clear Firefox history"
                else
                    rm -f "$profile/places.sqlite"* 2>/dev/null && ((cleaned++))
                fi
            fi
            
            # Downloads
            if [[ -f "$profile/downloads.sqlite" ]]; then
                if [[ "$DRY_RUN" == true ]]; then
                    print_color "$CYAN" "[DRY RUN] Would clear Firefox downloads"
                else
                    rm -f "$profile/downloads.sqlite"* 2>/dev/null && ((cleaned++))
                fi
            fi
        fi
    done
    
    [[ $cleaned -gt 0 ]] && print_color "$GREEN" "✓ Firefox cleaned ($cleaned items)"
    log_message "Firefox cleaned: $cleaned items"
}

# Function to clean system privacy data
clean_system_privacy() {
    print_color "$BLUE" "Cleaning system privacy data..."
    
    local cleaned=0
    
    # Recent documents
    print_color "$CYAN" "Clearing recent documents..."
    osascript -e 'tell application "System Events" to delete every recent document' 2>/dev/null && ((cleaned++))
    
    # Quick Look cache
    if [[ -d "$HOME/Library/Caches/com.apple.QuickLook.thumbnailcache" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            print_color "$CYAN" "[DRY RUN] Would clear Quick Look cache"
        else
            rm -rf "$HOME/Library/Caches/com.apple.QuickLook.thumbnailcache"/* 2>/dev/null && ((cleaned++))
            qlmanage -r cache 2>/dev/null
        fi
    fi
    
    # Spotlight suggestions
    if [[ "$DRY_RUN" == true ]]; then
        print_color "$CYAN" "[DRY RUN] Would disable Spotlight suggestions"
    else
        defaults write com.apple.lookup.shared LookupSuggestionsDisabled -bool true 2>/dev/null && ((cleaned++))
    fi
    
    # Siri suggestions
    if [[ "$DRY_RUN" == true ]]; then
        print_color "$CYAN" "[DRY RUN] Would clear Siri suggestions"
    else
        rm -rf "$HOME/Library/Assistant/SiriAnalytics.db"* 2>/dev/null && ((cleaned++))
    fi
    
    # Terminal history
    if [[ -f "$HOME/.zsh_history" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            print_color "$CYAN" "[DRY RUN] Would clear terminal history"
        else
            # Backup first
            cp "$HOME/.zsh_history" "$HOME/.zsh_history.backup.$(date +%Y%m%d)" 2>/dev/null
            echo "" > "$HOME/.zsh_history" && ((cleaned++))
        fi
    fi
    
    # DNS cache
    if [[ "$DRY_RUN" == true ]]; then
        print_color "$CYAN" "[DRY RUN] Would flush DNS cache"
    else
        sudo dscacheutil -flushcache 2>/dev/null && ((cleaned++))
        sudo killall -HUP mDNSResponder 2>/dev/null
    fi
    
    [[ $cleaned -gt 0 ]] && print_color "$GREEN" "✓ System privacy cleaned ($cleaned items)"
    log_message "System privacy cleaned: $cleaned items"
}

# Function to perform security audit
security_audit() {
    print_color "$BLUE" "═══════════════════════════════════════════"
    print_color "$BLUE" "Security Audit Report"
    print_color "$BLUE" "═══════════════════════════════════════════"
    
    local issues=0
    local warnings=0
    
    # System Integrity Protection (SIP)
    print_color "$CYAN" "System Integrity Protection (SIP):"
    local sip_status=$(csrutil status 2>/dev/null | grep -o "enabled\|disabled")
    if [[ "$sip_status" == "enabled" ]]; then
        print_color "$GREEN" "  ✓ SIP is enabled (recommended)"
    else
        print_color "$RED" "  ✗ SIP is disabled (security risk)"
        ((issues++))
    fi
    
    # FileVault
    print_color "$CYAN" "FileVault Encryption:"
    local filevault_status=$(fdesetup status 2>/dev/null | grep -o "On\|Off")
    if [[ "$filevault_status" == "On" ]]; then
        print_color "$GREEN" "  ✓ FileVault is enabled"
    else
        print_color "$YELLOW" "  ⚠ FileVault is disabled (consider enabling)"
        ((warnings++))
    fi
    
    # Firewall
    print_color "$CYAN" "Firewall:"
    local firewall_state=$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null | grep -o "enabled\|disabled")
    if [[ "$firewall_state" == "enabled" ]]; then
        print_color "$GREEN" "  ✓ Firewall is enabled"
    else
        print_color "$YELLOW" "  ⚠ Firewall is disabled"
        ((warnings++))
    fi
    
    # Gatekeeper
    print_color "$CYAN" "Gatekeeper:"
    local gatekeeper_status=$(spctl --status 2>/dev/null | grep -o "enabled\|disabled")
    if [[ "$gatekeeper_status" == "enabled" ]]; then
        print_color "$GREEN" "  ✓ Gatekeeper is enabled"
    else
        print_color "$RED" "  ✗ Gatekeeper is disabled (security risk)"
        ((issues++))
    fi
    
    # Automatic login
    print_color "$CYAN" "Automatic Login:"
    local autologin=$(defaults read /Library/Preferences/com.apple.loginwindow autoLoginUser 2>/dev/null)
    if [[ -z "$autologin" ]] || [[ "$autologin" == "0" ]]; then
        print_color "$GREEN" "  ✓ Automatic login is disabled"
    else
        print_color "$YELLOW" "  ⚠ Automatic login is enabled for: $autologin"
        ((warnings++))
    fi
    
    # Screen lock
    print_color "$CYAN" "Screen Lock:"
    local screenlock=$(defaults read com.apple.screensaver askForPassword 2>/dev/null)
    if [[ "$screenlock" == "1" ]]; then
        print_color "$GREEN" "  ✓ Password required after sleep/screensaver"
    else
        print_color "$YELLOW" "  ⚠ No password required after sleep"
        ((warnings++))
    fi
    
    # SSH status
    print_color "$CYAN" "Remote Access:"
    if launchctl list | grep -q "com.openssh.sshd"; then
        print_color "$YELLOW" "  ⚠ SSH is enabled"
        ((warnings++))
    else
        print_color "$GREEN" "  ✓ SSH is disabled"
    fi
    
    # Check for suspicious processes
    print_color "$CYAN" "Suspicious Processes:"
    local suspicious=$(ps aux | grep -E "(nc |netcat |/tmp/|curl.*\|.*sh)" | grep -v grep | wc -l | tr -d ' ')
    if [[ $suspicious -eq 0 ]]; then
        print_color "$GREEN" "  ✓ No suspicious processes detected"
    else
        print_color "$YELLOW" "  ⚠ $suspicious potentially suspicious processes found"
        ((warnings++))
    fi
    
    # Summary
    echo
    print_color "$BLUE" "═══════════════════════════════════════════"
    if [[ $issues -eq 0 ]] && [[ $warnings -eq 0 ]]; then
        print_color "$GREEN" "✓ No security issues found!"
    else
        [[ $issues -gt 0 ]] && print_color "$RED" "Critical issues: $issues"
        [[ $warnings -gt 0 ]] && print_color "$YELLOW" "Warnings: $warnings"
    fi
    
    log_message "Security audit: $issues issues, $warnings warnings"
}

# Function to scan for secrets
scan_secrets() {
    local path="${1:-$HOME}"
    print_color "$BLUE" "Scanning for exposed secrets in $path..."
    
    local found=0
    local patterns=(
        "AKIA[0-9A-Z]{16}"  # AWS Access Key
        "aws_secret_access_key"
        "api[_-]?key"
        "apikey"
        "access[_-]?token"
        "auth[_-]?token"
        "private[_-]?key"
        "client[_-]?secret"
        "password\s*=\s*['\"]"
        "pwd\s*=\s*['\"]"
        "token\s*=\s*['\"]"
        "ghp_[a-zA-Z0-9]{36}"  # GitHub personal access token
        "gho_[a-zA-Z0-9]{36}"  # GitHub OAuth token
        "github_token"
        "slack_token"
        "sq0atp-[0-9A-Za-z\-]{22}"  # Square access token
        "sk_live_[0-9a-zA-Z]{24}"  # Stripe API key
        "-----BEGIN RSA PRIVATE KEY-----"
        "-----BEGIN OPENSSH PRIVATE KEY-----"
        "-----BEGIN DSA PRIVATE KEY-----"
        "-----BEGIN EC PRIVATE KEY-----"
    )
    
    # Directories to skip
    local skip_dirs=".git,node_modules,.npm,Library,Applications,.Trash"
    
    print_color "$CYAN" "Scanning common locations..."
    
    # Check common files
    local common_files=(
        "$HOME/.zshrc"
        "$HOME/.bashrc"
        "$HOME/.bash_profile"
        "$HOME/.profile"
        "$HOME/.env"
        "$HOME/.aws/credentials"
        "$HOME/.ssh/config"
        "$HOME/.netrc"
        "$HOME/.git-credentials"
        "$HOME/.docker/config.json"
    )
    
    for file in "${common_files[@]}"; do
        if [[ -f "$file" ]]; then
            for pattern in "${patterns[@]}"; do
                if grep -qE "$pattern" "$file" 2>/dev/null; then
                    print_color "$YELLOW" "  ⚠ Potential secret in: $file"
                    ((found++))
                    break
                fi
            done
        fi
    done
    
    # Scan source code directories
    if [[ -d "$HOME/Documents" ]] || [[ -d "$HOME/src" ]] || [[ -d "$HOME/Projects" ]]; then
        print_color "$CYAN" "Scanning project directories..."
        
        # Look for .env files
        find "$HOME" -maxdepth 4 -name ".env*" -type f 2>/dev/null | while read -r envfile; do
            if grep -qE "(key|token|password|secret)" "$envfile" 2>/dev/null; then
                print_color "$YELLOW" "  ⚠ Environment file with secrets: $envfile"
                ((found++))
            fi
        done
    fi
    
    # Check git repositories for committed secrets
    print_color "$CYAN" "Checking git repositories..."
    find "$path" -maxdepth 3 -name ".git" -type d 2>/dev/null | while read -r gitdir; do
        local repo_dir=$(dirname "$gitdir")
        cd "$repo_dir" 2>/dev/null || continue
        
        # Check if secrets are in git history
        if git grep -qE "(api[_-]?key|password|token|secret)" 2>/dev/null; then
            print_color "$YELLOW" "  ⚠ Potential secrets in git repo: $repo_dir"
            ((found++))
        fi
    done
    
    # SSH key permissions
    print_color "$CYAN" "Checking SSH key permissions..."
    if [[ -d "$HOME/.ssh" ]]; then
        find "$HOME/.ssh" -type f -name "id_*" ! -name "*.pub" | while read -r key; do
            local perms=$(stat -f "%A" "$key")
            if [[ $perms -ne 600 ]]; then
                print_color "$RED" "  ✗ Insecure permissions on: $key (should be 600)"
                ((found++))
            fi
        done
    fi
    
    # Summary
    echo
    if [[ $found -eq 0 ]]; then
        print_color "$GREEN" "✓ No exposed secrets found"
    else
        print_color "$YELLOW" "⚠ Found $found potential security issues"
        print_color "$CYAN" "Recommendations:"
        echo "  1. Move secrets to secure storage (Keychain, 1Password)"
        echo "  2. Use environment variables from secure sources"
        echo "  3. Add sensitive files to .gitignore"
        echo "  4. Rotate any exposed credentials"
    fi
    
    log_message "Secret scan: $found potential issues"
}

# Function to check app permissions
check_permissions() {
    print_color "$BLUE" "Checking App Permissions..."
    
    # Camera
    print_color "$CYAN" "Camera Access:"
    local camera_apps=$(defaults read com.apple.TCC/TCC.db 2>/dev/null | grep -A1 "kTCCServiceCamera" | grep -o '"[^"]*"' | tr -d '"' | head -5)
    if [[ -n "$camera_apps" ]]; then
        echo "$camera_apps" | while read -r app; do
            echo "  • $app"
        done
    else
        echo "  No apps have camera access"
    fi
    
    # Microphone
    print_color "$CYAN" "Microphone Access:"
    local mic_apps=$(defaults read com.apple.TCC/TCC.db 2>/dev/null | grep -A1 "kTCCServiceMicrophone" | grep -o '"[^"]*"' | tr -d '"' | head -5)
    if [[ -n "$mic_apps" ]]; then
        echo "$mic_apps" | while read -r app; do
            echo "  • $app"
        done
    else
        echo "  No apps have microphone access"
    fi
    
    # Location Services
    print_color "$CYAN" "Location Services:"
    local location_enabled=$(defaults read com.apple.locationd LocationServicesEnabled 2>/dev/null)
    if [[ "$location_enabled" == "1" ]]; then
        print_color "$YELLOW" "  Location services are enabled"
    else
        print_color "$GREEN" "  Location services are disabled"
    fi
    
    # Full Disk Access
    print_color "$CYAN" "Full Disk Access:"
    echo "  Check System Preferences > Security & Privacy > Privacy > Full Disk Access"
    
    # Screen Recording
    print_color "$CYAN" "Screen Recording:"
    echo "  Check System Preferences > Security & Privacy > Privacy > Screen Recording"
}

# Function to enable privacy protection
enable_protection() {
    print_color "$BLUE" "Enabling privacy protection settings..."
    
    # Disable Spotlight suggestions
    defaults write com.apple.lookup.shared LookupSuggestionsDisabled -bool true
    
    # Disable Siri suggestions
    defaults write com.apple.assistant.support "Assistant Enabled" -bool false
    
    # Enable firewall
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on 2>/dev/null
    
    # Enable stealth mode
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on 2>/dev/null
    
    # Require password immediately after sleep
    defaults write com.apple.screensaver askForPassword -int 1
    defaults write com.apple.screensaver askForPasswordDelay -int 0
    
    # Disable automatic login
    sudo defaults delete /Library/Preferences/com.apple.loginwindow autoLoginUser 2>/dev/null
    
    # Disable guest account
    sudo defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool false
    
    print_color "$GREEN" "✓ Privacy protection settings enabled"
    log_message "Privacy protection enabled"
}

# Show help
show_help() {
    cat << EOF
Mac Power Tools - Privacy & Security Suite

USAGE:
    mac privacy [COMMAND] [OPTIONS]

COMMANDS:
    clean               Clean browser and system privacy data
    audit               Perform security audit
    scan [path]         Scan for exposed secrets
    permissions         Check app permissions
    protect             Enable privacy protection settings
    
CLEAN TARGETS:
    safari              Clean Safari data
    chrome              Clean Chrome data
    firefox             Clean Firefox data
    system              Clean system privacy data
    all                 Clean everything

OPTIONS:
    -h, --help          Show this help message
    -d, --dry-run       Preview changes without applying
    -v, --verbose       Show detailed output
    -q, --quiet         Suppress output

EXAMPLES:
    # Clean all browser data
    mac privacy clean all
    
    # Perform security audit
    mac privacy audit
    
    # Scan home directory for secrets
    mac privacy scan
    
    # Check app permissions
    mac privacy permissions
    
    # Enable privacy protection
    mac privacy protect
    
    # Dry run to see what would be cleaned
    mac privacy clean all --dry-run

FEATURES:
    • Browser data cleaning (Safari, Chrome, Firefox)
    • System privacy data removal
    • Security configuration audit
    • Exposed secrets detection
    • App permission review
    • Privacy protection hardening

SECURITY CHECKS:
    • System Integrity Protection (SIP)
    • FileVault encryption
    • Firewall status
    • Gatekeeper
    • Automatic login
    • Screen lock
    • SSH access
    • Suspicious processes

EOF
}

# Main function
main() {
    case "${1:-}" in
        clean)
            shift
            case "${1:-all}" in
                safari)
                    clean_safari
                    ;;
                chrome)
                    clean_chrome
                    ;;
                firefox)
                    clean_firefox
                    ;;
                system)
                    clean_system_privacy
                    ;;
                all)
                    clean_safari
                    clean_chrome
                    clean_firefox
                    clean_system_privacy
                    ;;
                *)
                    print_color "$RED" "Unknown target: $1"
                    echo "Valid targets: safari, chrome, firefox, system, all"
                    exit 1
                    ;;
            esac
            ;;
        audit)
            security_audit
            ;;
        scan)
            scan_secrets "${2:-$HOME}"
            ;;
        permissions)
            check_permissions
            ;;
        protect)
            print_color "$YELLOW" "This will modify system settings. Continue? (y/N)"
            read -r response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                enable_protection
            else
                print_color "$YELLOW" "Cancelled"
            fi
            ;;
        -h|--help|help)
            show_help
            ;;
        --dry-run|-d)
            DRY_RUN=true
            shift
            main "$@"
            ;;
        *)
            if [[ -z "${1:-}" ]]; then
                show_help
            else
                print_color "$RED" "Unknown command: $1"
                echo "Use 'mac privacy help' for usage"
                exit 1
            fi
            ;;
    esac
}

# Parse global options
while [[ $# -gt 0 ]] && [[ "$1" =~ ^- ]]; do
    case "$1" in
        --dry-run|-d)
            DRY_RUN=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        *)
            break
            ;;
    esac
done

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi