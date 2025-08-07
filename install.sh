#!/bin/bash

# Mac Power Tools Installation Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default installation directory
DEFAULT_INSTALL_DIR="$HOME/.mac-power-tools"

print_header() {
    echo
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}   Mac Power Tools Installer    ${NC}"
    echo -e "${BLUE}================================${NC}"
    echo
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Detect shell
detect_shell() {
    if [ -n "$ZSH_VERSION" ]; then
        SHELL_NAME="zsh"
        SHELL_RC="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        SHELL_NAME="bash"
        SHELL_RC="$HOME/.bashrc"
        # Check for .bash_profile on macOS
        if [ -f "$HOME/.bash_profile" ]; then
            SHELL_RC="$HOME/.bash_profile"
        fi
    else
        SHELL_NAME="unknown"
        SHELL_RC=""
    fi
}

# Check for required dependencies
check_dependencies() {
    print_info "Checking dependencies..."
    
    local missing_deps=()
    
    # Check for git
    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    fi
    
    # Optional dependencies (just warn if missing)
    if ! command -v brew &> /dev/null; then
        echo -e "${YELLOW}⚠${NC} Homebrew not installed (optional for brew updates)"
    fi
    
    if ! command -v mas &> /dev/null; then
        echo -e "${YELLOW}⚠${NC} mas-cli not installed (optional for Mac App Store updates)"
    fi
    
    if ! command -v npm &> /dev/null; then
        echo -e "${YELLOW}⚠${NC} npm not installed (optional for Node.js package updates)"
    fi
    
    # Check if any required dependencies are missing
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        echo "Please install them first."
        exit 1
    fi
    
    print_success "All required dependencies are installed"
}

# Installation function
install_mac_power_tools() {
    local install_dir="$1"
    
    # Create installation directory if it doesn't exist
    if [ ! -d "$install_dir" ]; then
        print_info "Creating installation directory: $install_dir"
        mkdir -p "$install_dir"
    fi
    
    # Copy files
    print_info "Installing Mac Power Tools..."
    
    # If we're in the repo directory, copy from here
    if [ -f "mac" ] && [ -d "scripts" ]; then
        cp -r mac scripts "$install_dir/"
        [ -f "README.md" ] && cp README.md "$install_dir/"
        [ -f "LICENSE" ] && cp LICENSE "$install_dir/"
    else
        # Clone from GitHub
        print_info "Cloning from GitHub..."
        git clone https://github.com/mikejennings/mac-power-tools.git "$install_dir/temp"
        cp -r "$install_dir/temp/"* "$install_dir/"
        rm -rf "$install_dir/temp"
    fi
    
    # Make scripts executable
    chmod +x "$install_dir/mac"
    chmod +x "$install_dir/scripts/"*.sh
    [ -f "$install_dir/install-completions.sh" ] && chmod +x "$install_dir/install-completions.sh"
    
    print_success "Mac Power Tools installed to $install_dir"
}

# Add to PATH
add_to_path() {
    local install_dir="$1"
    
    detect_shell
    
    if [ -z "$SHELL_RC" ]; then
        print_error "Could not detect shell configuration file"
        echo
        echo "Please add the following line to your shell configuration file manually:"
        echo "export PATH=\"\$PATH:$install_dir\""
        return
    fi
    
    print_info "Adding Mac Power Tools to PATH in $SHELL_RC"
    
    # Check if already in PATH
    if grep -q "mac-power-tools" "$SHELL_RC" 2>/dev/null; then
        print_info "Mac Power Tools already in PATH"
    else
        echo "" >> "$SHELL_RC"
        echo "# Mac Power Tools" >> "$SHELL_RC"
        echo "export PATH=\"\$PATH:$install_dir\"" >> "$SHELL_RC"
        print_success "Added to PATH"
    fi
    
    # Also create an alias for convenience
    if ! grep -q "alias mac=" "$SHELL_RC" 2>/dev/null; then
        echo "alias mac='$install_dir/mac'" >> "$SHELL_RC"
        print_success "Created 'mac' alias"
    fi
}

# Create symlink option
create_symlink() {
    local install_dir="$1"
    
    print_info "Creating symlink in /usr/local/bin..."
    
    # Create /usr/local/bin if it doesn't exist
    if [ ! -d "/usr/local/bin" ]; then
        sudo mkdir -p /usr/local/bin
    fi
    
    # Create symlink
    if [ -L "/usr/local/bin/mac" ]; then
        print_info "Symlink already exists, updating..."
        sudo rm /usr/local/bin/mac
    fi
    
    sudo ln -s "$install_dir/mac" /usr/local/bin/mac
    print_success "Symlink created at /usr/local/bin/mac"
}

# Main installation
main() {
    print_header
    
    # Check dependencies
    check_dependencies
    
    # Ask for installation method
    echo "Choose installation method:"
    echo "1) Install to home directory (recommended)"
    echo "2) Install with symlink to /usr/local/bin (requires sudo)"
    echo "3) Custom installation directory"
    echo
    read -p "Select option (1-3): " install_option
    
    case $install_option in
        1)
            INSTALL_DIR="$DEFAULT_INSTALL_DIR"
            install_mac_power_tools "$INSTALL_DIR"
            add_to_path "$INSTALL_DIR"
            ;;
        2)
            INSTALL_DIR="$DEFAULT_INSTALL_DIR"
            install_mac_power_tools "$INSTALL_DIR"
            create_symlink "$INSTALL_DIR"
            ;;
        3)
            read -p "Enter installation directory: " CUSTOM_DIR
            INSTALL_DIR="${CUSTOM_DIR/#\~/$HOME}"
            install_mac_power_tools "$INSTALL_DIR"
            add_to_path "$INSTALL_DIR"
            ;;
        *)
            print_error "Invalid option"
            exit 1
            ;;
    esac
    
    echo
    print_success "Installation complete!"
    echo
    echo "To start using Mac Power Tools:"
    echo "1. Reload your shell: source $SHELL_RC"
    echo "2. Run: mac help"
    echo
    
    # Offer to install tab completion
    if [ -f "$INSTALL_DIR/install-completions.sh" ]; then
        echo "Would you like to install tab completion? (y/N)"
        read -r install_completion
        if [[ "$install_completion" =~ ^[Yy]$ ]]; then
            "$INSTALL_DIR/install-completions.sh"
        else
            echo "You can install tab completion later by running:"
            echo "$INSTALL_DIR/install-completions.sh"
        fi
        echo
    fi
    
    echo "For more information, visit:"
    echo "https://github.com/mikejennings/mac-power-tools"
}

# Run main function
main