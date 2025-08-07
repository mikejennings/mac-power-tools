#!/bin/bash

# Mac Power Tools - Tab Completion Installation Script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPLETIONS_DIR="$SCRIPT_DIR/completions"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_color() {
    local color=$1
    shift
    printf "${color}%s${NC}\n" "$*"
}

print_color "$BLUE" "Mac Power Tools - Installing Tab Completion"
echo

# Detect shell
SHELL_TYPE=$(basename "$SHELL")
print_color "$YELLOW" "Detected shell: $SHELL_TYPE"

case "$SHELL_TYPE" in
    zsh)
        # Install zsh completion
        ZSH_COMPLETIONS_DIR=""
        
        # Try different zsh completion directories
        if [[ -d "/opt/homebrew/share/zsh/site-functions" ]]; then
            ZSH_COMPLETIONS_DIR="/opt/homebrew/share/zsh/site-functions"
        elif [[ -d "/usr/local/share/zsh/site-functions" ]]; then
            ZSH_COMPLETIONS_DIR="/usr/local/share/zsh/site-functions"
        elif [[ -d "$HOME/.oh-my-zsh/completions" ]]; then
            ZSH_COMPLETIONS_DIR="$HOME/.oh-my-zsh/completions"
            mkdir -p "$ZSH_COMPLETIONS_DIR"
        else
            # Create user completion directory
            ZSH_COMPLETIONS_DIR="$HOME/.zsh/completions"
            mkdir -p "$ZSH_COMPLETIONS_DIR"
        fi
        
        print_color "$YELLOW" "Installing zsh completion to: $ZSH_COMPLETIONS_DIR"
        
        if [[ -w "$ZSH_COMPLETIONS_DIR" ]]; then
            cp "$COMPLETIONS_DIR/_mac" "$ZSH_COMPLETIONS_DIR/_mac"
            print_color "$GREEN" "✓ Zsh completion installed"
        else
            print_color "$YELLOW" "Need sudo for system-wide installation:"
            sudo cp "$COMPLETIONS_DIR/_mac" "$ZSH_COMPLETIONS_DIR/_mac"
            print_color "$GREEN" "✓ Zsh completion installed (with sudo)"
        fi
        
        # Add to fpath if using custom directory
        if [[ "$ZSH_COMPLETIONS_DIR" == "$HOME/.zsh/completions" ]]; then
            if ! grep -q "fpath.*\.zsh/completions" ~/.zshrc 2>/dev/null; then
                echo "" >> ~/.zshrc
                echo "# Mac Power Tools completion" >> ~/.zshrc
                echo "fpath=(~/.zsh/completions \$fpath)" >> ~/.zshrc
                echo "autoload -Uz compinit && compinit" >> ~/.zshrc
                print_color "$GREEN" "✓ Added completion path to ~/.zshrc"
            fi
        fi
        
        print_color "$YELLOW" "To activate completions:"
        echo "1. Restart your terminal, or"
        echo "2. Run: source ~/.zshrc && compinit"
        ;;
        
    bash)
        # Install bash completion
        BASH_COMPLETIONS_DIR=""
        
        # Try different bash completion directories
        if [[ -d "/opt/homebrew/etc/bash_completion.d" ]]; then
            BASH_COMPLETIONS_DIR="/opt/homebrew/etc/bash_completion.d"
        elif [[ -d "/usr/local/etc/bash_completion.d" ]]; then
            BASH_COMPLETIONS_DIR="/usr/local/etc/bash_completion.d"
        elif [[ -d "/etc/bash_completion.d" ]]; then
            BASH_COMPLETIONS_DIR="/etc/bash_completion.d"
        else
            # Create user completion directory
            BASH_COMPLETIONS_DIR="$HOME/.bash_completion.d"
            mkdir -p "$BASH_COMPLETIONS_DIR"
        fi
        
        print_color "$YELLOW" "Installing bash completion to: $BASH_COMPLETIONS_DIR"
        
        if [[ -w "$BASH_COMPLETIONS_DIR" ]]; then
            cp "$COMPLETIONS_DIR/mac-completion.bash" "$BASH_COMPLETIONS_DIR/mac"
            print_color "$GREEN" "✓ Bash completion installed"
        else
            print_color "$YELLOW" "Need sudo for system-wide installation:"
            sudo cp "$COMPLETIONS_DIR/mac-completion.bash" "$BASH_COMPLETIONS_DIR/mac"
            print_color "$GREEN" "✓ Bash completion installed (with sudo)"
        fi
        
        # Add to .bashrc if using custom directory
        if [[ "$BASH_COMPLETIONS_DIR" == "$HOME/.bash_completion.d" ]]; then
            if ! grep -q "bash_completion.d" ~/.bashrc 2>/dev/null; then
                echo "" >> ~/.bashrc
                echo "# Mac Power Tools completion" >> ~/.bashrc
                echo "for f in ~/.bash_completion.d/*; do source \$f; done" >> ~/.bashrc
                print_color "$GREEN" "✓ Added completion loading to ~/.bashrc"
            fi
        fi
        
        print_color "$YELLOW" "To activate completions:"
        echo "1. Restart your terminal, or"
        echo "2. Run: source ~/.bashrc"
        ;;
        
    *)
        print_color "$RED" "Unsupported shell: $SHELL_TYPE"
        echo "Supported shells: zsh, bash"
        exit 1
        ;;
esac

echo
print_color "$GREEN" "Tab completion installation complete!"
print_color "$BLUE" "Try typing: mac <TAB>"
echo

# Test if mac command is available
if command -v mac >/dev/null 2>&1; then
    print_color "$GREEN" "✓ mac command found in PATH"
else
    print_color "$YELLOW" "⚠ mac command not found in PATH"
    print_color "$YELLOW" "Make sure Mac Power Tools is properly installed"
fi