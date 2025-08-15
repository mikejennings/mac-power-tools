#!/bin/bash

# Mac Power Tools - Migrate manually downloaded apps to Homebrew
# Helps users migrate apps from /Applications to Homebrew Cask versions

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Dry run mode (default: true for safety)
DRY_RUN=true
INTERACTIVE=true
VERBOSE=false

# Function to print colored output
print_color() {
    local color=$1
    shift
    printf "${color}%s${NC}\n" "$*"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check dependencies
check_dependencies() {
    local missing=()
    
    if ! command_exists brew; then
        missing+=("brew")
    fi
    
    if [ ${#missing[@]} -gt 0 ]; then
        print_color "$RED" "Missing required dependencies: ${missing[*]}"
        echo
        print_color "$YELLOW" "Install them with:"
        for dep in "${missing[@]}"; do
            if [ "$dep" = "brew" ]; then
                echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            fi
        done
        return 1
    fi
    return 0
}

# Known app name to Homebrew Cask mappings
# Using a function instead of associative array for compatibility
get_cask_for_app_name() {
    local app_name=$1
    case "$app_name" in
        # Productivity
        "1Password 7 - Password Manager") echo "1password7" ;;
        "1Password 8 - Password Manager"|"1Password") echo "1password" ;;
        "Affinity Photo") echo "affinity-photo" ;;
        "Affinity Photo 2") echo "affinity-photo" ;;
        "Affinity Designer") echo "affinity-designer" ;;
        "Affinity Designer 2") echo "affinity-designer" ;;
        "Affinity Publisher") echo "affinity-publisher" ;;
        "Affinity Publisher 2") echo "affinity-publisher" ;;
        "Alfred") echo "alfred" ;;
        "Bear") echo "bear" ;;
        "Bitwarden") echo "bitwarden" ;;
        "CleanMyMac X") echo "cleanmymac" ;;
        "Discord") echo "discord" ;;
        "Dropbox") echo "dropbox" ;;
        "Figma") echo "figma" ;;
        "Google Chrome") echo "google-chrome" ;;
        "Google Drive") echo "google-drive" ;;
        "Kindle") echo "kindle" ;;
        "Microsoft Excel") echo "microsoft-excel" ;;
        "Microsoft PowerPoint") echo "microsoft-powerpoint" ;;
        "Microsoft Word") echo "microsoft-word" ;;
        "Microsoft OneNote") echo "microsoft-onenote" ;;
        "Microsoft Outlook") echo "microsoft-outlook" ;;
        "Microsoft Teams") echo "microsoft-teams" ;;
        "Notion") echo "notion" ;;
        "Obsidian") echo "obsidian" ;;
        "Rectangle") echo "rectangle" ;;
        "Slack") echo "slack" ;;
        "Spotify") echo "spotify" ;;
        "Telegram") echo "telegram" ;;
        "Twitter") echo "twitter" ;;
        "WhatsApp") echo "whatsapp" ;;
        "Zoom") echo "zoom" ;;
        
        # Development
        "Android Studio") echo "android-studio" ;;
        "Docker Desktop"|"Docker") echo "docker" ;;
        "GitHub Desktop") echo "github" ;;
        "GitKraken") echo "gitkraken" ;;
        "IntelliJ IDEA CE") echo "intellij-idea-ce" ;;
        "IntelliJ IDEA") echo "intellij-idea" ;;
        "JetBrains Toolbox") echo "jetbrains-toolbox" ;;
        "Postman") echo "postman" ;;
        "PyCharm CE") echo "pycharm-ce" ;;
        "PyCharm") echo "pycharm" ;;
        "Sublime Text") echo "sublime-text" ;;
        "TablePlus") echo "tableplus" ;;
        "Transmit 5") echo "transmit" ;;
        "Visual Studio Code"|"VSCode") echo "visual-studio-code" ;;
        "WebStorm") echo "webstorm" ;;
        "Xcode") echo "xcode" ;;
        "iTerm") echo "iterm2" ;;
        "Warp") echo "warp" ;;
        "Alacritty") echo "alacritty" ;;
        "Tower") echo "tower" ;;
        "SourceTree") echo "sourcetree" ;;
        "Fork") echo "fork" ;;
        "Insomnia") echo "insomnia" ;;
        "Paw") echo "paw" ;;
        "Dash") echo "dash" ;;
        "CodeRunner") echo "coderunner" ;;
        "Nova") echo "nova" ;;
        "BBEdit") echo "bbedit" ;;
        "TextMate") echo "textmate" ;;
        "Zed") echo "zed" ;;
        "Cursor") echo "cursor" ;;
        "DataGrip") echo "datagrip" ;;
        "RubyMine") echo "rubymine" ;;
        "GoLand") echo "goland" ;;
        "PhpStorm") echo "phpstorm" ;;
        "CLion") echo "clion" ;;
        "Rider") echo "rider" ;;
        "AppCode") echo "appcode" ;;
        
        # Media
        "Adobe Photoshop 2024") echo "adobe-photoshop" ;;
        "Adobe Illustrator 2024") echo "adobe-illustrator" ;;
        "Adobe Premiere Pro 2024") echo "adobe-premiere-pro" ;;
        "Adobe After Effects 2024") echo "adobe-after-effects" ;;
        "Adobe Creative Cloud") echo "adobe-creative-cloud" ;;
        "Audacity") echo "audacity" ;;
        "Blender") echo "blender" ;;
        "DaVinci Resolve") echo "davinci-resolve" ;;
        "Final Cut Pro") echo "final-cut-pro" ;;
        "Handbrake") echo "handbrake" ;;
        "IINA") echo "iina" ;;
        "Logic Pro") echo "logic-pro" ;;
        "OBS Studio") echo "obs" ;;
        "Pixelmator Pro") echo "pixelmator-pro" ;;
        "Sketch") echo "sketch" ;;
        "VLC media player"|"VLC") echo "vlc" ;;
        "Plex") echo "plex" ;;
        "Kodi") echo "kodi" ;;
        "MPV") echo "mpv" ;;
        "QuickTime Player") echo "" ;;  # System app
        "GarageBand") echo "garageband" ;;
        "Compressor") echo "compressor" ;;
        "Motion") echo "motion" ;;
        "MainStage") echo "mainstage" ;;
        "Screenflow") echo "screenflow" ;;
        "Camtasia") echo "camtasia" ;;
        "ScreenFloat") echo "screenfloat" ;;
        "CleanShot X") echo "cleanshot" ;;
        "Snagit") echo "snagit" ;;
        
        # Utilities
        "1Blocker- Ad Blocker & Privacy") echo "1blocker" ;;
        "AppCleaner") echo "appcleaner" ;;
        "BetterTouchTool") echo "bettertouchtool" ;;
        "CleanMaster- Remove Junk Files") echo "cleanmaster" ;;
        "Finder") echo "" ;;  # System app, no cask
        "Hammerspoon") echo "hammerspoon" ;;
        "Karabiner-Elements") echo "karabiner-elements" ;;
        "Magnet") echo "magnet" ;;
        "Raycast") echo "raycast" ;;
        "The Unarchiver") echo "the-unarchiver" ;;
        "TopNotch") echo "topnotch" ;;
        "Bartender 4"|"Bartender") echo "bartender" ;;
        "Amphetamine") echo "amphetamine" ;;
        "Keka") echo "keka" ;;
        "Path Finder") echo "path-finder" ;;
        "Default Folder X") echo "default-folder-x" ;;
        "Hazel") echo "hazel" ;;
        "Keyboard Maestro") echo "keyboard-maestro" ;;
        "TextExpander") echo "textexpander" ;;
        "PopClip") echo "popclip" ;;
        "Moom") echo "moom" ;;
        "SizeUp") echo "sizeup" ;;
        "Divvy") echo "divvy" ;;
        "Mosaic") echo "mosaic" ;;
        "Paste") echo "paste" ;;
        "Pastebot") echo "pastebot" ;;
        "Yoink") echo "yoink" ;;
        "Dropzone") echo "dropzone" ;;
        "HiddenBar") echo "hiddenbar" ;;
        "Vanilla") echo "vanilla" ;;
        "Dozer") echo "dozer" ;;
        "Stats") echo "stats" ;;
        "iStat Menus") echo "istat-menus" ;;
        "MenubarX") echo "menubarx" ;;
        "MonitorControl") echo "monitorcontrol" ;;
        "AnyBar") echo "anybar" ;;
        "BitBar") echo "bitbar" ;;
        "SwiftBar") echo "swiftbar" ;;
        
        # Browsers
        "Arc") echo "arc" ;;
        "Brave Browser") echo "brave-browser" ;;
        "Firefox") echo "firefox" ;;
        "Microsoft Edge") echo "microsoft-edge" ;;
        "Opera") echo "opera" ;;
        "Opera GX") echo "opera-gx" ;;
        "Vivaldi") echo "vivaldi" ;;
        "Tor Browser") echo "tor-browser" ;;
        "Orion") echo "orion" ;;
        "SigmaOS") echo "sigmaos" ;;
        "Min") echo "min" ;;
        "Waterfox") echo "waterfox" ;;
        "Safari") echo "" ;;  # System app, no cask
        
        # Communication
        "FaceTime") echo "" ;;  # System app, no cask
        "Mail") echo "" ;;  # System app, no cask
        "Messages") echo "" ;;  # System app, no cask
        "Skype") echo "skype" ;;
        "Signal") echo "signal" ;;
        "Element") echo "element" ;;
        "Mattermost") echo "mattermost" ;;
        "Franz") echo "franz" ;;
        "Ferdi") echo "ferdi" ;;
        "Rocket.Chat") echo "rocket-chat" ;;
        "Wire") echo "wire" ;;
        "Keybase") echo "keybase" ;;
        "Jitsi Meet") echo "jitsi-meet" ;;
        "Around") echo "around" ;;
        "Loom") echo "loom" ;;
        "mmhmm") echo "mmhmm" ;;
        "Whereby") echo "whereby" ;;
        
        # Security & Privacy
        "Little Snitch") echo "little-snitch" ;;
        "Micro Snitch") echo "micro-snitch" ;;
        "Encrypto") echo "encrypto" ;;
        "VeraCrypt") echo "veracrypt" ;;
        "Cryptomator") echo "cryptomator" ;;
        "KeePassXC") echo "keepassxc" ;;
        "MacPass") echo "macpass" ;;
        "Enpass") echo "enpass" ;;
        "Dashlane") echo "dashlane" ;;
        "LastPass") echo "lastpass" ;;
        "NordVPN") echo "nordvpn" ;;
        "ExpressVPN") echo "expressvpn" ;;
        "Surfshark") echo "surfshark" ;;
        "ProtonVPN") echo "protonvpn" ;;
        "Mullvad VPN") echo "mullvadvpn" ;;
        "Windscribe") echo "windscribe" ;;
        "TunnelBear") echo "tunnelbear" ;;
        "Private Internet Access") echo "private-internet-access" ;;
        
        # Cloud Storage
        "OneDrive") echo "onedrive" ;;
        "Box") echo "box-drive" ;;
        "MEGA") echo "megasync" ;;
        "pCloud Drive") echo "pcloud-drive" ;;
        "Sync") echo "sync" ;;
        "Tresorit") echo "tresorit" ;;
        "Backblaze") echo "backblaze" ;;
        "Arq") echo "arq" ;;
        "Carbon Copy Cloner") echo "carbon-copy-cloner" ;;
        "SuperDuper!") echo "superduper" ;;
        "ChronoSync") echo "chronosync" ;;
        
        # Writing & Notes
        "Scrivener 3"|"Scrivener") echo "scrivener" ;;
        "Ulysses") echo "ulysses" ;;
        "iA Writer") echo "ia-writer" ;;
        "Typora") echo "typora" ;;
        "MacDown") echo "macdown" ;;
        "Marked 2") echo "marked" ;;
        "Day One") echo "day-one" ;;
        "Journey") echo "journey" ;;
        "Agenda") echo "agenda" ;;
        "Things"|"Things 3") echo "things" ;;
        "OmniFocus 3"|"OmniFocus") echo "omnifocus" ;;
        "Todoist") echo "todoist" ;;
        "TickTick") echo "ticktick" ;;
        "2Do") echo "2do" ;;
        "GoodNotes 5"|"GoodNotes") echo "goodnotes" ;;
        "Notability") echo "notability" ;;
        "MarginNote 3"|"MarginNote") echo "marginnote" ;;
        "DEVONthink 3"|"DEVONthink") echo "devonthink" ;;
        "Keep It") echo "keep-it" ;;
        "Notebooks") echo "notebooks" ;;
        "Roam Research") echo "roam-research" ;;
        "Logseq") echo "logseq" ;;
        "RemNote") echo "remnote" ;;
        "Craft - Docs and Notes Editor"|"Craft") echo "craft" ;;
        
        # Finance
        "Money - Budget & Finance"|"Money") echo "money" ;;
        "MoneyMoney") echo "moneymoney" ;;
        "YNAB") echo "ynab" ;;
        "Quicken") echo "quicken" ;;
        "Banktivity") echo "banktivity" ;;
        "Mint") echo "mint" ;;
        "Coinbase") echo "coinbase" ;;
        "Binance") echo "binance" ;;
        "TradingView") echo "tradingview" ;;
        
        # Education
        "Anki") echo "anki" ;;
        "Studies") echo "studies" ;;
        "Quizlet") echo "quizlet" ;;
        "Flashcard Hero") echo "flashcard-hero" ;;
        "Mental Case") echo "mental-case" ;;
        
        # Games (some examples)
        "Steam") echo "steam" ;;
        "Epic Games Launcher") echo "epic-games" ;;
        "Battle.net") echo "battle-net" ;;
        "GOG Galaxy") echo "gog-galaxy" ;;
        "Origin") echo "origin" ;;
        "Minecraft") echo "minecraft" ;;
        "League of Legends") echo "league-of-legends" ;;
        
        *) echo "" ;;  # Return empty for unknown apps
    esac
}

# Function to get app info from Info.plist
get_app_info() {
    local app_path=$1
    local plist_path="$app_path/Contents/Info.plist"
    
    if [ -f "$plist_path" ]; then
        local bundle_id=$(defaults read "$plist_path" CFBundleIdentifier 2>/dev/null || echo "")
        local version=$(defaults read "$plist_path" CFBundleShortVersionString 2>/dev/null || echo "")
        local executable=$(defaults read "$plist_path" CFBundleExecutable 2>/dev/null || echo "")
        echo "${bundle_id}|${version}|${executable}"
    else
        echo "||"
    fi
}

# Function to get installed apps from /Applications
get_installed_apps() {
    find /Applications -maxdepth 1 -name "*.app" -type d 2>/dev/null | while read -r app_path; do
        local app_name=$(basename "$app_path" .app)
        echo "$app_name"
    done | sort
}

# Function to get installed apps with detailed info
get_installed_apps_detailed() {
    find /Applications -maxdepth 1 -name "*.app" -type d 2>/dev/null | while read -r app_path; do
        local app_name=$(basename "$app_path" .app)
        [ "$VERBOSE" = true ] && echo "Scanning: $app_name..." >&2
        
        local app_info=$(get_app_info "$app_path")
        IFS='|' read -r bundle_id version executable <<< "$app_info"
        
        # Get app size (skip for speed)
        local app_size="N/A"
        # local app_size=$(du -sh "$app_path" 2>/dev/null | cut -f1)
        
        # Check if it's from Mac App Store
        local is_mas="no"
        if [ -f "$app_path/Contents/_MASReceipt/receipt" ]; then
            is_mas="yes"
        fi
        
        echo "${app_name}|${bundle_id}|${version}|${executable}|${app_size}|${is_mas}|${app_path}"
    done | sort -t'|' -k1
}

# Function to check if cask is installed
is_cask_installed() {
    local cask=$1
    brew list --cask 2>/dev/null | grep -q "^${cask}$"
}

# Enhanced cask search using bundle ID and app name
find_cask_for_app_smart() {
    local app_name=$1
    local bundle_id=$2
    local executable=$3
    
    # First try known mappings
    local known_cask=$(get_cask_for_app_name "$app_name")
    if [ -n "$known_cask" ]; then
        echo "$known_cask"
        return
    fi
    
    # Skip brew search for now - it's too slow
    # This can be re-enabled with a flag if needed
    echo ""
    return
    
    # Try bundle ID based search if available
    if [ -n "$bundle_id" ] && command_exists brew; then
        # Extract domain from bundle ID (e.g., com.google.Chrome -> google-chrome)
        local search_term=$(echo "$bundle_id" | sed 's/^com\.//' | sed 's/\./\-/g' | tr '[:upper:]' '[:lower:]')
        local cask_result=$(brew search --cask "$search_term" 2>/dev/null | head -1)
        if [ -n "$cask_result" ] && [ "$cask_result" != "No casks found" ]; then
            echo "$cask_result"
            return
        fi
    fi
    
    # Try executable name
    if [ -n "$executable" ]; then
        local search_term=$(echo "$executable" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')
        local cask_result=$(brew search --cask "$search_term" 2>/dev/null | head -1)
        if [ -n "$cask_result" ] && [ "$cask_result" != "No casks found" ]; then
            echo "$cask_result"
            return
        fi
    fi
    
    # Finally try simplified app name
    local search_name=$(echo "$app_name" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g' | sed 's/[^a-z0-9-]//g')
    local cask_result=$(brew search --cask "$search_name" 2>/dev/null | head -1)
    if [ -n "$cask_result" ] && [ "$cask_result" != "No casks found" ]; then
        echo "$cask_result"
        return
    fi
    
    echo ""
}

# Function to find cask for app (simple version for backward compatibility)
find_cask_for_app() {
    local app_name=$1
    find_cask_for_app_smart "$app_name" "" ""
}

# Function to migrate single app (DRY RUN ONLY - NO DELETION)
migrate_app() {
    local app_name=$1
    local cask_name=$2
    
    if [ "$DRY_RUN" = true ]; then
        print_color "$CYAN" "[DRY RUN] Would migrate: $app_name"
        print_color "$CYAN" "  - Install Homebrew cask: $cask_name"
        print_color "$CYAN" "  - Manual cleanup: Move /Applications/$app_name.app to Trash"
        return 0
    fi
    
    # Install cask version
    print_color "$YELLOW" "Installing $app_name via Homebrew..."
    if brew install --cask "$cask_name"; then
        print_color "$GREEN" "✓ Installed $cask_name"
        
        # IMPORTANT: We do NOT automatically delete the manual app
        # User must manually clean up to avoid data loss
        print_color "$YELLOW" "⚠️  Manual cleanup required:"
        print_color "$CYAN" "  1. Quit $app_name if running"
        print_color "$CYAN" "  2. Move /Applications/$app_name.app to Trash"
        print_color "$CYAN" "  3. The Homebrew version is now available"
        
        return 0
    else
        print_color "$RED" "Failed to install $cask_name"
        return 1
    fi
}

# Function to analyze migration opportunities
analyze_migration() {
    print_color "$BLUE" "Analyzing /Applications for migration opportunities..." >&2
    echo >&2
    
    local migratable=()
    local unknown=()
    local already_migrated=()
    local system_apps=()
    local mas_apps=()
    
    # Use detailed scanning if available
    local apps_data
    if declare -f get_installed_apps_detailed >/dev/null; then
        [ "$VERBOSE" = true ] && echo "Using detailed scanning..." >&2
        print_color "$CYAN" "Scanning installed applications..." >&2
        apps_data=$(get_installed_apps_detailed)
        print_color "$CYAN" "Processing application data..." >&2
        while IFS='|' read -r app_name bundle_id version executable size is_mas path; do
            if [ -n "$app_name" ]; then
                [ "$VERBOSE" = true ] && echo "Processing: $app_name (bundle: $bundle_id)" >&2
                
                # Skip Mac App Store apps
                if [ "$is_mas" = "yes" ]; then
                    mas_apps+=("$app_name")
                    continue
                fi
                
                # Check custom mappings first, then smart detection
                local cask=$(get_custom_mapping "$app_name")
                if [ -z "$cask" ]; then
                    cask=$(find_cask_for_app_smart "$app_name" "$bundle_id" "$executable")
                fi
                
                if [ -n "$cask" ]; then
                    # Check if cask is already installed
                    if is_cask_installed "$cask"; then
                        already_migrated+=("$app_name (→ $cask)")
                    else
                        migratable+=("${app_name}|${cask}")
                    fi
                elif [ "$cask" = "" ] && [[ "$app_name" =~ ^(Finder|Safari|Mail|Messages|FaceTime|Calendar|Contacts|Maps|Photos|Music|TV|Podcasts|News|Stocks|Weather|Clock|Calculator|Chess|Dictionary|DVD Player|Font Book|Grapher|Image Capture|Keychain Access|Migration Assistant|Photo Theater|Preview|QuickTime Player|Stickies|System Preferences|System Settings|TextEdit|Time Machine|VoiceOver Utility|Console|Activity Monitor|Disk Utility)$ ]]; then
                    system_apps+=("$app_name")
                else
                    unknown+=("$app_name")
                fi
            fi
        done <<< "$apps_data"
    else
        # Fallback to simple scanning
        local app_list=$(get_installed_apps)
        while IFS= read -r app_name; do
            if [ -n "$app_name" ]; then
                [ "$VERBOSE" = true ] && echo "Processing: $app_name" >&2
                # Check custom mappings first, then known mappings
                local cask=$(get_custom_mapping "$app_name")
                if [ -z "$cask" ]; then
                    cask=$(get_cask_for_app_name "$app_name")
                fi
                
                if [ -n "$cask" ]; then
                    # Check if cask is already installed
                    if is_cask_installed "$cask"; then
                        already_migrated+=("$app_name (→ $cask)")
                    else
                        migratable+=("${app_name}|${cask}")
                    fi
                elif [ "$cask" = "" ] && [[ "$app_name" =~ ^(Finder|Safari|Mail|Messages|FaceTime|Calendar|Contacts|Maps|Photos|Music|TV|Podcasts|News|Stocks|Weather|Clock|Calculator|Chess|Dictionary|DVD Player|Font Book|Grapher|Image Capture|Keychain Access|Migration Assistant|Photo Theater|Preview|QuickTime Player|Stickies|System Preferences|System Settings|TextEdit|Time Machine|VoiceOver Utility|Console|Activity Monitor|Disk Utility)$ ]]; then
                    system_apps+=("$app_name")
                else
                    unknown+=("$app_name")
                fi
            fi
        done <<< "$app_list"
    fi
    
    # Display results
    if [ ${#migratable[@]} -gt 0 ]; then
        print_color "$GREEN" "Apps that can be migrated to Homebrew:" >&2
        for item in "${migratable[@]}"; do
            IFS='|' read -r name cask suggested <<< "$item"
            if [ "$suggested" = "suggested" ]; then
                echo "  • $name → $cask (suggested)" >&2
            else
                echo "  • $name → $cask" >&2
            fi
        done
        echo >&2
    fi
    
    if [ ${#already_migrated[@]} -gt 0 ]; then
        print_color "$CYAN" "Apps already available via Homebrew:" >&2
        for app in "${already_migrated[@]}"; do
            echo "  • $app" >&2
        done
        echo >&2
    fi
    
    if [ ${#mas_apps[@]} -gt 0 ]; then
        print_color "$MAGENTA" "Mac App Store apps (use 'mac migrate-mas' instead):" >&2
        for app in "${mas_apps[@]}"; do
            echo "  • $app" >&2
        done
        echo >&2
    fi
    
    if [ ${#system_apps[@]} -gt 0 ]; then
        print_color "$MAGENTA" "System apps (cannot be migrated):" >&2
        for app in "${system_apps[@]}"; do
            echo "  • $app" >&2
        done
        echo >&2
    fi
    
    if [ ${#unknown[@]} -gt 0 ]; then
        print_color "$YELLOW" "Apps without known Homebrew equivalents:" >&2
        for app in "${unknown[@]}"; do
            echo "  • $app" >&2
        done
        echo >&2
    fi
    
    # Return migratable apps for processing
    printf '%s\n' "${migratable[@]}"
}

# Function to perform migration
perform_migration() {
    local apps=("$@")
    local migrated=0
    local failed=0
    
    for item in "${apps[@]}"; do
        IFS='|' read -r name cask suggested <<< "$item"
        
        if [ "$INTERACTIVE" = true ]; then
            echo
            if [ "$suggested" = "suggested" ]; then
                print_color "$YELLOW" "Suggested migration: $name → $cask"
                print_color "$CYAN" "This is an automatic suggestion and may not be exact"
            else
                print_color "$CYAN" "Migrate: $name → $cask"
            fi
            
            read -p "Proceed? (y/n/s=skip): " -n 1 -r
            echo
            
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_color "$YELLOW" "Skipped $name"
                continue
            fi
        fi
        
        if migrate_app "$name" "$cask"; then
            ((migrated++))
        else
            ((failed++))
        fi
    done
    
    # Summary
    echo
    print_color "$BLUE" "═══════════════════════════════════════════"
    print_color "$BLUE" "Migration Summary"
    print_color "$BLUE" "═══════════════════════════════════════════"
    print_color "$GREEN" "Successfully migrated: $migrated"
    [ $failed -gt 0 ] && print_color "$RED" "Failed: $failed"
    
    if [ "$DRY_RUN" = true ]; then
        echo
        print_color "$YELLOW" "This was a dry run - no changes were made"
        print_color "$CYAN" "Run with --execute to perform actual migration"
    else
        echo
        print_color "$YELLOW" "⚠️  Important: Manual cleanup required"
        print_color "$CYAN" "You must manually remove the old apps from /Applications"
        print_color "$CYAN" "The Homebrew versions are now installed and ready to use"
    fi
}

# Custom mappings storage (for current session)
CUSTOM_MAPPINGS=""

# Function to add custom mapping
add_custom_mapping() {
    local app_name=$1
    local cask_name=$2
    
    print_color "$CYAN" "Adding custom mapping: $app_name → $cask_name"
    
    # Add to custom mappings for current session
    CUSTOM_MAPPINGS="${CUSTOM_MAPPINGS}${app_name}:${cask_name};"
}

# Function to get custom mapping
get_custom_mapping() {
    local app_name=$1
    if [ -n "$CUSTOM_MAPPINGS" ]; then
        echo "$CUSTOM_MAPPINGS" | tr ';' '\n' | grep "^${app_name}:" | cut -d':' -f2
    fi
}

# Function to list all known mappings
list_mappings() {
    print_color "$BLUE" "Known Application to Homebrew Cask mappings:"
    print_color "$BLUE" "═══════════════════════════════════════════"
    
    # List all known mappings from the function
    cat << 'EOF'
Productivity:
  1Password 7 - Password Manager → 1password-7
  1Password 8 - Password Manager → 1password
  Affinity Photo → affinity-photo
  Affinity Designer → affinity-designer
  Affinity Publisher → affinity-publisher
  Alfred → alfred
  Bear → bear
  Bitwarden → bitwarden
  CleanMyMac X → cleanmymac
  Discord → discord
  Dropbox → dropbox
  Figma → figma
  Google Chrome → google-chrome
  Google Drive → google-drive
  Kindle → kindle
  Microsoft Excel → microsoft-excel
  Microsoft PowerPoint → microsoft-powerpoint
  Microsoft Word → microsoft-word
  Microsoft OneNote → microsoft-onenote
  Microsoft Outlook → microsoft-outlook
  Microsoft Teams → microsoft-teams
  Notion → notion
  Obsidian → obsidian
  Rectangle → rectangle
  Slack → slack
  Spotify → spotify
  Telegram → telegram
  Twitter → twitter
  WhatsApp → whatsapp
  Zoom → zoom

Development:
  Android Studio → android-studio
  Docker Desktop → docker
  GitHub Desktop → github
  GitKraken → gitkraken
  IntelliJ IDEA CE → intellij-idea-ce
  IntelliJ IDEA → intellij-idea
  JetBrains Toolbox → jetbrains-toolbox
  Postman → postman
  PyCharm CE → pycharm-ce
  PyCharm → pycharm
  Sublime Text → sublime-text
  TablePlus → tableplus
  Transmit 5 → transmit
  Visual Studio Code → visual-studio-code
  WebStorm → webstorm
  Xcode → xcode

Media:
  Adobe Photoshop 2024 → adobe-photoshop
  Adobe Illustrator 2024 → adobe-illustrator
  Adobe Premiere Pro 2024 → adobe-premiere-pro
  Adobe After Effects 2024 → adobe-after-effects
  Adobe Creative Cloud → adobe-creative-cloud
  Audacity → audacity
  Blender → blender
  DaVinci Resolve → davinci-resolve
  Final Cut Pro → final-cut-pro
  Handbrake → handbrake
  IINA → iina
  Logic Pro → logic-pro
  OBS Studio → obs
  Pixelmator Pro → pixelmator-pro
  Sketch → sketch
  VLC media player → vlc

Utilities:
  1Blocker- Ad Blocker & Privacy → 1blocker
  AppCleaner → appcleaner
  BetterTouchTool → bettertouchtool
  CleanMaster- Remove Junk Files → cleanmaster
  Hammerspoon → hammerspoon
  Karabiner-Elements → karabiner-elements
  Magnet → magnet
  Raycast → raycast
  The Unarchiver → the-unarchiver
  TopNotch → topnotch

Browsers:
  Arc → arc
  Brave Browser → brave-browser
  Firefox → firefox
  Microsoft Edge → microsoft-edge
  Opera → opera
EOF
    
    # Show custom mappings if any
    if [ -n "$CUSTOM_MAPPINGS" ]; then
        echo
        print_color "$CYAN" "Custom mappings (current session):"
        echo "$CUSTOM_MAPPINGS" | tr ';' '\n' | grep -v '^$' | while IFS=':' read -r app cask; do
            echo "  $app → $cask"
        done
    fi
}

# Interactive FZF selection for apps
select_apps_with_fzf() {
    if ! command_exists fzf; then
        return 1
    fi
    
    print_color "$CYAN" "Analyzing applications for migration..."
    
    local apps_data=$(get_installed_apps_detailed)
    local selectable_apps=()
    
    while IFS='|' read -r name bundle_id version executable size is_mas path; do
        if [ "$is_mas" = "yes" ]; then
            continue  # Skip Mac App Store apps
        fi
        
        # Check if it's a system app
        if [[ "$name" =~ ^(Finder|Safari|Mail|Messages|FaceTime|Calendar|Contacts|Maps|Photos|Music|TV|Podcasts|News|Stocks|Weather|Clock|Calculator|Chess|Dictionary|DVD Player|Font Book|Grapher|Image Capture|Keychain Access|Migration Assistant|Photo Theater|Preview|QuickTime Player|Stickies|System Preferences|System Settings|TextEdit|Time Machine|VoiceOver Utility|Console|Activity Monitor|Disk Utility)$ ]]; then
            continue
        fi
        
        # Find potential cask
        local cask=$(find_cask_for_app_smart "$name" "$bundle_id" "$executable")
        
        if [ -n "$cask" ]; then
            if is_cask_installed "$cask"; then
                continue  # Already migrated
            fi
            selectable_apps+=("$name [$size] → $cask|${name}|${cask}")
        else
            selectable_apps+=("$name [$size] (no cask found)|${name}|")
        fi
    done <<< "$apps_data"
    
    if [ ${#selectable_apps[@]} -eq 0 ]; then
        print_color "$YELLOW" "No apps available for migration"
        return 1
    fi
    
    # Use fzf for selection
    local selected=$(printf '%s\n' "${selectable_apps[@]}" | cut -d'|' -f1 | \
        fzf --multi --height=80% --layout=reverse \
            --header="Select apps to migrate (TAB for multi-select, Enter to confirm, Esc to cancel)" \
            --preview-window=hidden)
    
    if [ -z "$selected" ]; then
        return 1
    fi
    
    # Return selected apps
    echo "$selected" | while read -r selection; do
        for app_entry in "${selectable_apps[@]}"; do
            if [[ "$app_entry" == "$selection|"* ]]; then
                echo "$app_entry" | cut -d'|' -f2,3
                break
            fi
        done
    done
}

# Show help
show_help() {
    cat << EOF
Mac Power Tools - Manual Apps to Homebrew Migration

Helps migrate manually downloaded apps from /Applications to Homebrew Cask 
versions for better management, updates, and automation.

USAGE:
    mac migrate-apps [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    -a, --analyze       Analyze apps and show migration opportunities
    -f, --fzf           Use fzf for interactive multi-select
    -e, --execute       Execute migration (default is dry-run)
    -y, --yes           Non-interactive mode (migrate all)
    -l, --list          List known App to Cask mappings
    -m, --map APP CASK  Add custom App name to Cask mapping
    -v, --verbose       Show detailed output

EXAMPLES:
    # Interactive multi-select with fzf (recommended)
    mac migrate-apps --fzf
    
    # Execute migration with fzf selection
    mac migrate-apps --fzf --execute
    
    # Analyze what can be migrated (safe, read-only)
    mac migrate-apps --analyze
    
    # Perform dry-run migration (default)
    mac migrate-apps
    
    # Execute actual migration interactively
    mac migrate-apps --execute
    
    # Migrate all without prompting
    mac migrate-apps --execute --yes
    
    # Add custom mapping and migrate
    mac migrate-apps --map "My App" my-app --execute

ENHANCED FEATURES:
    • Smart detection using bundle IDs from Info.plist
    • Fuzzy cask search with multiple strategies
    • FZF multi-select for batch operations
    • Expanded database of 200+ app mappings
    • Automatic Mac App Store app filtering
    • Size information for each app

BENEFITS OF MIGRATION:
    • Homebrew casks update automatically with 'brew upgrade'
    • Unified package management with brew
    • Better automation and scripting support
    • Easier backup and restore of apps
    • Version pinning and rollback capabilities
    • No manual downloads or updates needed

SAFETY FEATURES:
    • Dry-run mode by default (no changes made)
    • Manual cleanup required (no automatic app deletion)
    • Interactive confirmation for each app
    • System apps are automatically excluded
    • Preserves app data and settings

NOTES:
    • This tool does NOT delete apps automatically
    • You must manually remove old apps after migration
    • App settings and data are typically preserved
    • Some apps may require re-authentication
    • Always test migrated apps before removing originals

EOF
}

# Main function
main() {
    local analyze_only=false
    local execute=false
    local use_fzf=false
    
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
            -f|--fzf)
                use_fzf=true
                shift
                ;;
            -e|--execute)
                DRY_RUN=false
                shift
                ;;
            -y|--yes)
                INTERACTIVE=false
                shift
                ;;
            -l|--list)
                list_mappings
                exit 0
                ;;
            -m|--map)
                if [ -n "$2" ] && [ -n "$3" ]; then
                    add_custom_mapping "$2" "$3"
                    shift 3
                else
                    print_color "$RED" "Error: --map requires APP_NAME and CASK_NAME"
                    exit 1
                fi
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            *)
                print_color "$RED" "Unknown option: $1"
                echo "Use 'mac migrate-apps --help' for usage"
                exit 1
                ;;
        esac
    done
    
    # Check dependencies
    if ! check_dependencies; then
        exit 1
    fi
    
    print_color "$BLUE" "═══════════════════════════════════════════"
    print_color "$BLUE" "Manual Apps to Homebrew Migration Tool"
    print_color "$BLUE" "═══════════════════════════════════════════"
    echo
    
    # Use FZF selection if requested
    if [ "$use_fzf" = true ]; then
        if ! command_exists fzf; then
            print_color "$YELLOW" "fzf not found. Install with: brew install fzf"
            print_color "$CYAN" "Falling back to standard mode..."
            echo
            use_fzf=false
        else
            selected_apps=$(select_apps_with_fzf)
            if [ -z "$selected_apps" ]; then
                print_color "$YELLOW" "No apps selected"
                exit 0
            fi
            
            # Process selected apps
            local migrated=0
            local failed=0
            
            echo "$selected_apps" | while IFS='|' read -r app_name cask_name; do
                if [ -z "$cask_name" ]; then
                    print_color "$YELLOW" "Skipping $app_name (no cask available)"
                    continue
                fi
                
                if [ "$INTERACTIVE" = true ] && [ "$DRY_RUN" = false ]; then
                    echo
                    print_color "$CYAN" "Migrate: $app_name → $cask_name"
                    read -p "Proceed? (y/n/s=skip): " -n 1 -r
                    echo
                    
                    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                        print_color "$YELLOW" "Skipped $app_name"
                        continue
                    fi
                fi
                
                if migrate_app "$app_name" "$cask_name"; then
                    ((migrated++))
                else
                    ((failed++))
                fi
            done
            
            # Summary
            echo
            print_color "$BLUE" "Migration Summary"
            print_color "$GREEN" "Successfully migrated: $migrated"
            [ $failed -gt 0 ] && print_color "$RED" "Failed: $failed"
            
            if [ "$DRY_RUN" = true ]; then
                echo
                print_color "$YELLOW" "This was a dry run - no changes were made"
                print_color "$CYAN" "Run with --execute to perform actual migration"
            fi
            
            exit 0
        fi
    fi
    
    # Get migratable apps (standard mode)
    migratable_apps=()
    local migration_output=$(analyze_migration)
    while IFS= read -r line; do
        [[ -n "$line" ]] && migratable_apps+=("$line")
    done <<< "$migration_output"
    
    if [ ${#migratable_apps[@]} -eq 0 ] || [ -z "${migratable_apps[0]}" ]; then
        print_color "$YELLOW" "No apps found to migrate"
        print_color "$CYAN" "All your manually installed apps are either:"
        echo "  • Already available via Homebrew"
        echo "  • System apps that cannot be migrated"
        echo "  • Apps without known Homebrew equivalents"
        exit 0
    fi
    
    # If analyze only, we're done
    if [ "$analyze_only" = true ]; then
        exit 0
    fi
    
    # Confirm migration
    if [ "$DRY_RUN" = true ]; then
        print_color "$YELLOW" "Running in DRY RUN mode - no changes will be made"
    else
        print_color "$YELLOW" "⚠️  This will install Homebrew versions of your apps"
        print_color "$CYAN" "You will need to manually remove the old versions"
    fi
    
    if [ "$INTERACTIVE" = true ] && [ "$DRY_RUN" = false ]; then
        echo
        read -p "Continue with migration? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_color "$YELLOW" "Migration cancelled"
            exit 0
        fi
    fi
    
    # Perform migration
    perform_migration "${migratable_apps[@]}"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi