#!/bin/bash

# Mac Update Plugin - Native implementation
# Comprehensive system update utility

# Source the plugin API
source "${MAC_POWER_TOOLS_HOME}/lib/plugin-api.sh"

# Function to update macOS
update_macos() {
    print_info "Checking for macOS updates..."
    
    # Check for updates
    if softwareupdate -l 2>&1 | grep -q "No new software available"; then
        print_success "macOS is up to date"
    else
        print_info "macOS updates available:"
        softwareupdate -l
        
        if confirm "Install macOS updates?"; then
            print_info "Installing macOS updates..."
            sudo softwareupdate -i -a
            print_success "macOS updates installed"
        else
            print_warning "Skipping macOS updates"
        fi
    fi
}

# Function to update Homebrew
update_homebrew() {
    print_info "Updating Homebrew..."
    
    if command_exists brew; then
        brew update
        print_success "Homebrew updated"
        
        print_info "Upgrading Homebrew packages..."
        brew upgrade
        print_success "Homebrew packages upgraded"
        
        print_info "Upgrading Homebrew casks..."
        brew upgrade --cask
        print_success "Homebrew casks upgraded"
        
        # Check and fix any broken symlinks after upgrades
        print_info "Running Homebrew diagnostics..."
        local doctor_output
        doctor_output=$(brew doctor 2>&1) || true  # Don't fail if brew doctor reports issues
        
        # Check for unlinked kegs (packages that are installed but not linked)
        if echo "$doctor_output" | grep -q "not linked\|isn't linked"; then
            print_warning "Found unlinked packages, checking for fixes..."
            
            # Build array of unlinked packages safely
            local -a unlinked_kegs=()
            while IFS= read -r formula; do
                # Validate package name format for security
                if [[ "$formula" =~ ^[a-zA-Z0-9._@+-]+$ ]]; then
                    if ! brew ls --verbose "$formula" >/dev/null 2>&1; then
                        unlinked_kegs+=("$formula")
                    fi
                fi
            done < <(brew list --formula)
            
            # Process each unlinked package with user confirmation
            for keg in "${unlinked_kegs[@]}"; do
                print_info "Package '$keg' is not linked"
                
                # Try safe linking first (without overwrite)
                if brew link "$keg" 2>/dev/null; then
                    print_success "$keg linked successfully"
                else
                    # Check what would be overwritten
                    local conflicts
                    conflicts=$(brew link --dry-run "$keg" 2>&1 | grep "Would remove" | head -5)
                    if [ -n "$conflicts" ]; then
                        print_warning "Linking $keg requires overwriting existing files:"
                        echo "$conflicts" | sed 's/^/  /'
                        
                        if confirm "Force overwrite these files for $keg?"; then
                            if brew link --overwrite "$keg" 2>/dev/null; then
                                print_success "$keg linked with overwrite"
                            else
                                print_error "Failed to link $keg even with overwrite"
                            fi
                        else
                            print_info "Skipped linking $keg"
                        fi
                    else
                        print_warning "Could not link $keg - unknown error"
                    fi
                fi
            done
        fi
        
        print_info "Cleaning up Homebrew..."
        brew cleanup -s
        brew autoremove
        print_success "Homebrew cleaned up"
        
        # Final check to ensure everything is healthy
        if brew doctor 2>&1 | grep -q "Your system is ready to brew"; then
            print_success "Homebrew is healthy and ready!"
        else
            print_info "Running final brew doctor check..."
            brew doctor 2>&1 | head -10
        fi
    else
        print_warning "Homebrew not installed"
    fi
}

# Function to update Mac App Store apps
update_mas() {
    print_info "Checking Mac App Store updates..."
    
    if command_exists mas; then
        local outdated=$(mas outdated)
        if [ -z "$outdated" ]; then
            print_success "Mac App Store apps are up to date"
        else
            print_info "Mac App Store updates available:"
            echo "$outdated"
            
            if confirm "Install Mac App Store updates?"; then
                print_info "Installing Mac App Store updates..."
                mas upgrade
                print_success "Mac App Store apps updated"
            else
                print_warning "Skipping Mac App Store updates"
            fi
        fi
    else
        print_warning "mas-cli not installed"
    fi
}

# Function to update npm packages
update_npm() {
    print_info "Updating npm packages..."
    
    if command_exists npm; then
        print_info "Updating npm itself..."
        npm install -g npm@latest
        print_success "npm updated"
        
        print_info "Updating global npm packages..."
        npm update -g
        print_success "Global npm packages updated"
    else
        print_warning "npm not installed"
    fi
}

# Function to update Ruby gems
update_ruby() {
    print_info "Updating Ruby gems..."
    
    if command_exists gem; then
        print_info "Updating RubyGems system..."
        gem update --system
        print_success "RubyGems system updated"
        
        print_info "Updating installed gems..."
        gem update
        print_success "Ruby gems updated"
        
        print_info "Cleaning up old gem versions..."
        # Use sudo for Homebrew-installed gems to avoid permission errors
        if [[ -d "/opt/homebrew/lib/ruby/gems" ]]; then
            sudo gem cleanup 2>/dev/null || gem cleanup
        else
            gem cleanup
        fi
        print_success "Old gem versions cleaned up"
    else
        print_warning "Ruby gems not available"
    fi
}

# Function to update pip packages
update_pip() {
    print_info "Updating Python packages..."
    
    if command_exists pip3; then
        # Check if we're in an externally-managed environment (PEP 668)
        local pip_flags=""
        if pip3 --version 2>&1 | grep -q "python3" && \
           python3 -c "import sys; sys.exit(0 if sys.prefix.startswith('/opt/homebrew') or sys.prefix.startswith('/usr/local') else 1)" 2>/dev/null; then
            # This is likely a Homebrew Python, use --user flag for safety
            pip_flags="--user"
            print_info "Using --user flag for Homebrew-managed Python"
        fi
        
        print_info "Updating pip..."
        # First check if pip needs updating
        if pip3 install --upgrade $pip_flags pip 2>&1 | grep -q "Requirement already satisfied"; then
            print_success "pip is already up to date"
        elif pip3 install --upgrade $pip_flags pip 2>/dev/null; then
            print_success "pip updated"
        else
            # Try with --break-system-packages as last resort
            pip3 install --upgrade --break-system-packages pip 2>&1 | grep -q "Requirement already satisfied" && \
                print_success "pip is already up to date" || \
                print_warning "Failed to update pip"
        fi
        
        print_info "Listing outdated packages..."
        local outdated=$(pip3 list --outdated $pip_flags --format=json 2>/dev/null | python3 -c "import sys, json; packages = json.load(sys.stdin); print(' '.join([p['name'] for p in packages]))" 2>/dev/null || echo "")
        
        if [ -n "$outdated" ]; then
            print_info "Outdated packages: $outdated"
            if confirm "Update all Python packages?"; then
                for package in $outdated; do
                    if ! pip3 install --upgrade $pip_flags "$package" 2>/dev/null; then
                        # Try with --break-system-packages as fallback
                        pip3 install --upgrade --break-system-packages "$package" 2>/dev/null || print_warning "Failed to update $package"
                    fi
                done
                print_success "Python packages updated"
            else
                print_warning "Skipping Python package updates"
            fi
        else
            print_success "Python packages are up to date"
        fi
    else
        print_warning "pip not installed"
    fi
}

# Run all updates
# fzf-enhanced update target selection
fzf_update_menu() {
    local targets=(
        "all:Update everything (recommended)"
        "macos:Check for macOS system updates"
        "brew:Update Homebrew packages"
        "mas:Update Mac App Store applications"
        "npm:Update Node.js packages globally"
        "ruby:Update Ruby gems"
        "pip:Update Python packages"
    )
    
    printf "\n${BLUE}📦 Select Update Target${NC}\n\n"
    
    local selected=$(printf '%s\n' "${targets[@]}" | fzf \
        --height=15 \
        --layout=reverse \
        --border \
        --prompt="Update target: " \
        --preview='echo {} | cut -d: -f2 | sed "s/^ *//"' \
        --preview-window=up:2:wrap \
        --header="Press Enter for 'all', ↑↓ to navigate, type to filter, Esc to exit" \
        --color="header:italic:blue,prompt:green")
    
    if [[ -n "$selected" ]]; then
        local target=$(echo "$selected" | cut -d: -f1)
        echo
        print_info "Updating: $target"
        echo
        
        case "$target" in
            all)
                update_all
                ;;
            macos|system)
                update_macos
                ;;
            brew|homebrew)
                update_homebrew
                ;;
            mas|appstore)
                update_mas
                ;;
            npm|node)
                update_npm
                ;;
            ruby|gem|gems)
                update_ruby
                ;;
            pip|python)
                update_pip
                ;;
        esac
    else
        print_warning "No target selected, defaulting to 'all'"
        echo
        update_all
    fi
}

update_all() {
    print_info "Running all system updates..."
    update_macos
    echo
    update_homebrew
    echo
    update_mas
    echo
    update_npm
    echo
    update_ruby
    echo
    update_pip
    print_success "All updates completed!"
}

# Plugin main entry point
plugin_main() {
    echo "==================================="
    echo "     Mac System Update Utility     "
    echo "==================================="
    echo
    
    # Check for 'all' argument first to bypass any menu
    if [ "$1" = "all" ]; then
        update_all
        echo
        print_success "Update process complete!"
        return 0
    fi
    
    # Parse arguments
    if [ $# -eq 0 ]; then
        # No arguments - check for fzf and show interactive menu if available
        if command_exists fzf; then
            fzf_update_menu
        else
            # Fallback to updating all if fzf is not available
            update_all
        fi
    elif [ "$1" = "--help" ] || [ "$1" = "-h" ] || [ "$1" = "help" ]; then
        echo "Usage: mac update [target]"
        echo ""
        echo "Available targets:"
        echo "  macos, system    Update macOS system updates"
        echo "  brew, homebrew   Update Homebrew packages"
        echo "  mas, appstore    Update Mac App Store apps"
        echo "  npm, node        Update npm packages globally"
        echo "  ruby, gem, gems  Update Ruby gems"
        echo "  pip, python      Update Python packages"
        echo "  all              Update everything (default)"
        echo ""
        echo "Examples:"
        echo "  mac update         # Interactive menu (if fzf installed) or update all"
        echo "  mac update brew    # Update only Homebrew"
        echo "  mac update all     # Update everything"
        return 0
    else
        # Run specific updates based on arguments
        for arg in "$@"; do
            case $arg in
                macos|system)
                    update_macos
                    ;;
                brew|homebrew)
                    update_homebrew
                    ;;
                mas|appstore)
                    update_mas
                    ;;
                npm|node)
                    update_npm
                    ;;
                ruby|gem|gems)
                    update_ruby
                    ;;
                pip|python)
                    update_pip
                    ;;
                all)
                    update_all
                    ;;
                *)
                    print_error "Unknown update target: $arg"
                    echo "Available targets: macos, brew, mas, npm, ruby, pip, all"
                    return 1
                    ;;
            esac
            echo
        done
    fi
    
    echo
    print_success "Update process complete!"
}

# Initialize the plugin
plugin_init

# Call the main function if not sourced
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    plugin_main "$@"
fi
