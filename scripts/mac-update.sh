#!/bin/bash

# Mac Update Script - Comprehensive system update utility
# Replaces mac-cli update functionality

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Function to update macOS
update_macos() {
    print_status "Checking for macOS updates..."
    
    # Check for updates
    if softwareupdate -l 2>&1 | grep -q "No new software available"; then
        print_success "macOS is up to date"
    else
        print_status "macOS updates available:"
        softwareupdate -l
        
        read -p "Install macOS updates? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Installing macOS updates..."
            sudo softwareupdate -i -a
            print_success "macOS updates installed"
        else
            print_warning "Skipping macOS updates"
        fi
    fi
}

# Function to update Homebrew
update_homebrew() {
    print_status "Updating Homebrew..."
    
    if command -v brew &> /dev/null; then
        brew update
        print_success "Homebrew updated"
        
        print_status "Upgrading Homebrew packages..."
        brew upgrade
        print_success "Homebrew packages upgraded"
        
        print_status "Upgrading Homebrew casks..."
        brew upgrade --cask
        print_success "Homebrew casks upgraded"
        
        print_status "Cleaning up Homebrew..."
        brew cleanup -s
        brew autoremove
        print_success "Homebrew cleaned up"
    else
        print_warning "Homebrew not installed"
    fi
}

# Function to update Mac App Store apps
update_mas() {
    print_status "Checking Mac App Store updates..."
    
    if command -v mas &> /dev/null; then
        outdated=$(mas outdated)
        if [ -z "$outdated" ]; then
            print_success "Mac App Store apps are up to date"
        else
            print_status "Mac App Store updates available:"
            echo "$outdated"
            
            read -p "Install Mac App Store updates? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                print_status "Installing Mac App Store updates..."
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
    print_status "Updating npm packages..."
    
    if command -v npm &> /dev/null; then
        print_status "Updating npm itself..."
        npm install -g npm@latest
        print_success "npm updated"
        
        print_status "Updating global npm packages..."
        npm update -g
        print_success "Global npm packages updated"
    else
        print_warning "npm not installed"
    fi
}

# Function to update Ruby gems
update_ruby() {
    print_status "Updating Ruby gems..."
    
    if command -v gem &> /dev/null; then
        print_status "Updating RubyGems system..."
        gem update --system
        print_success "RubyGems system updated"
        
        print_status "Updating installed gems..."
        gem update
        print_success "Ruby gems updated"
        
        print_status "Cleaning up old gem versions..."
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
    print_status "Updating Python packages..."
    
    if command -v pip3 &> /dev/null; then
        print_status "Updating pip..."
        pip3 install --upgrade pip
        print_success "pip updated"
        
        print_status "Listing outdated packages..."
        outdated=$(pip3 list --outdated --format=json 2>/dev/null | python3 -c "import sys, json; packages = json.load(sys.stdin); print(' '.join([p['name'] for p in packages]))" 2>/dev/null || echo "")
        
        if [ -n "$outdated" ]; then
            print_status "Outdated packages: $outdated"
            read -p "Update all Python packages? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                for package in $outdated; do
                    pip3 install --upgrade "$package" 2>/dev/null || print_warning "Failed to update $package"
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

# Main update function
main() {
    echo "==================================="
    echo "     Mac System Update Utility     "
    echo "==================================="
    echo
    
    # Parse arguments
    if [ $# -eq 0 ]; then
        # No arguments, run all updates
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
                *)
                    print_error "Unknown update target: $arg"
                    echo "Available targets: macos, brew, mas, npm, ruby, pip"
                    exit 1
                    ;;
            esac
            echo
        done
    fi
    
    echo
    print_success "Update process complete!"
}

# Run main function
main "$@"