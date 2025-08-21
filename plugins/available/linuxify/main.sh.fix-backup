#!/bin/bash

# Native plugin implementation
# Migrated from legacy script to use plugin API

# Source the plugin API
source "${MAC_POWER_TOOLS_HOME}/lib/plugin-api.sh"



set -euo pipefail

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output

# GNU packages to install
GNU_CORE_PACKAGES=(
    "coreutils"      # GNU core utilities (ls, cat, echo, mkdir, rm, etc.)
    "binutils"       # GNU binary utilities (ar, nm, objdump, etc.)
    "diffutils"      # GNU diff, cmp, diff3, sdiff
    "findutils"      # GNU find, locate, xargs, updatedb
    "gawk"           # GNU awk
    "gnu-indent"     # GNU indent
    "gnu-sed"        # GNU sed
    "gnu-tar"        # GNU tar
    "gnu-which"      # GNU which
    "grep"           # GNU grep, egrep, fgrep
    "gzip"           # GNU gzip, gunzip, zcat
    "make"           # GNU make
)

# Extended GNU utilities for more complete coverage
GNU_EXTENDED_PACKAGES=(
    "util-linux"     # Large collection of utilities (cal, col, column, hexdump, look, rename, etc.)
    "inetutils"      # Network utilities (ftp, telnet, traceroute, whois, etc.)
    "gnu-getopt"     # GNU getopt
    "gnu-units"      # GNU units
    "gnu-time"       # GNU time
    "moreutils"      # Additional Unix utilities (parallel, pee, sponge, ts, etc.)
    "proctools"      # Process tools (pgrep, pkill, etc.)
    "psutils"        # PostScript utilities
)

GNU_EXTRA_PACKAGES=(
    "bash"           # Latest GNU bash
    "ed"             # GNU ed
    "file-formula"   # GNU file
    "git"            # Latest git
    "less"           # GNU less
    "m4"             # GNU m4
    "nano"           # GNU nano
    "rsync"          # GNU rsync
    "screen"         # GNU screen
    "tmux"           # Terminal multiplexer
    "unzip"          # Better unzip
    "vim"            # Latest vim
    "watch"          # GNU watch
    "wdiff"          # GNU wdiff
    "wget"           # GNU wget
    "curl"           # Better curl
    "htop"           # Better top
    "ncdu"           # NCurses disk usage
    "tree"           # Directory tree
)

# Development tools
GNU_DEV_PACKAGES=(
    "autoconf"       # GNU autoconf
    "automake"       # GNU automake
    "bison"          # GNU bison
    "flex"           # Fast lexical analyzer
    "gdb"            # GNU debugger
    "gettext"        # GNU gettext
    "libtool"        # GNU libtool
    "pkg-config"     # Package config tool
)

# Modern CLI replacements (optional)
MODERN_TOOLS=(
    "bat"            # Better cat
    "eza"            # Better ls (formerly exa)
    "fd"             # Better find
    "fzf"            # Fuzzy finder
    "htop"           # Better top
    "jq"             # JSON processor
    "ripgrep"        # Better grep
    "tree"           # Directory tree
    "zoxide"         # Better cd
)

# Configuration file content
LINUXIFY_CONFIG='#!/bin/bash
# Mac Power Tools - GNU/Linux Environment Configuration
# Source this file in your shell configuration (.bashrc, .zshrc)

# Detect Homebrew prefix
if [[ -x "/opt/homebrew/bin/brew" ]]; then
    BREW_PREFIX="/opt/homebrew"
elif [[ -x "/usr/local/bin/brew" ]]; then
    BREW_PREFIX="/usr/local"
else
    echo "Warning: Homebrew not found"
    return 1
fi

# GNU Core Utilities
if [[ -d "$BREW_PREFIX/opt/coreutils/libexec/gnubin" ]]; then
    export PATH="$BREW_PREFIX/opt/coreutils/libexec/gnubin:$PATH"
    export MANPATH="$BREW_PREFIX/opt/coreutils/libexec/gnuman:$MANPATH"
fi

# GNU Make
if [[ -d "$BREW_PREFIX/opt/make/libexec/gnubin" ]]; then
    export PATH="$BREW_PREFIX/opt/make/libexec/gnubin:$PATH"
    export MANPATH="$BREW_PREFIX/opt/make/libexec/gnuman:$MANPATH"
fi

# GNU Sed
if [[ -d "$BREW_PREFIX/opt/gnu-sed/libexec/gnubin" ]]; then
    export PATH="$BREW_PREFIX/opt/gnu-sed/libexec/gnubin:$PATH"
    export MANPATH="$BREW_PREFIX/opt/gnu-sed/libexec/gnuman:$MANPATH"
fi

# GNU Tar
if [[ -d "$BREW_PREFIX/opt/gnu-tar/libexec/gnubin" ]]; then
    export PATH="$BREW_PREFIX/opt/gnu-tar/libexec/gnubin:$PATH"
    export MANPATH="$BREW_PREFIX/opt/gnu-tar/libexec/gnuman:$MANPATH"
fi

# GNU Which
if [[ -d "$BREW_PREFIX/opt/gnu-which/libexec/gnubin" ]]; then
    export PATH="$BREW_PREFIX/opt/gnu-which/libexec/gnubin:$PATH"
    export MANPATH="$BREW_PREFIX/opt/gnu-which/libexec/gnuman:$MANPATH"
fi

# GNU Grep
if [[ -d "$BREW_PREFIX/opt/grep/libexec/gnubin" ]]; then
    export PATH="$BREW_PREFIX/opt/grep/libexec/gnubin:$PATH"
    export MANPATH="$BREW_PREFIX/opt/grep/libexec/gnuman:$MANPATH"
fi

# GNU Find
if [[ -d "$BREW_PREFIX/opt/findutils/libexec/gnubin" ]]; then
    export PATH="$BREW_PREFIX/opt/findutils/libexec/gnubin:$PATH"
    export MANPATH="$BREW_PREFIX/opt/findutils/libexec/gnuman:$MANPATH"
fi

# GNU Awk
if [[ -d "$BREW_PREFIX/opt/gawk/libexec/gnubin" ]]; then
    export PATH="$BREW_PREFIX/opt/gawk/libexec/gnubin:$PATH"
    export MANPATH="$BREW_PREFIX/opt/gawk/libexec/gnuman:$MANPATH"
fi

# GNU Indent
if [[ -d "$BREW_PREFIX/opt/gnu-indent/libexec/gnubin" ]]; then
    export PATH="$BREW_PREFIX/opt/gnu-indent/libexec/gnubin:$PATH"
    export MANPATH="$BREW_PREFIX/opt/gnu-indent/libexec/gnuman:$MANPATH"
fi

# Other GNU tools
if [[ -d "$BREW_PREFIX/opt/ed/libexec/gnubin" ]]; then
    export PATH="$BREW_PREFIX/opt/ed/libexec/gnubin:$PATH"
    export MANPATH="$BREW_PREFIX/opt/ed/libexec/gnuman:$MANPATH"
fi

# File formula
if [[ -d "$BREW_PREFIX/opt/file-formula/bin" ]]; then
    export PATH="$BREW_PREFIX/opt/file-formula/bin:$PATH"
fi

# Gettext
if [[ -d "$BREW_PREFIX/opt/gettext/bin" ]]; then
    export PATH="$BREW_PREFIX/opt/gettext/bin:$PATH"
fi

# Unzip
if [[ -d "$BREW_PREFIX/opt/unzip/bin" ]]; then
    export PATH="$BREW_PREFIX/opt/unzip/bin:$PATH"
fi

# Python (if installed via brew)
if [[ -d "$BREW_PREFIX/opt/python/libexec/bin" ]]; then
    export PATH="$BREW_PREFIX/opt/python/libexec/bin:$PATH"
fi

# Useful aliases for GNU tools
alias ll="ls -l --color=auto"
alias la="ls -la --color=auto"
alias ls="ls --color=auto"
alias grep="grep --color=auto"
alias egrep="egrep --color=auto"
alias fgrep="fgrep --color=auto"

# Set default editor to vim if available
if command -v vim &> /dev/null; then
    export EDITOR="vim"
    export VISUAL="vim"
fi

# Enable color support for various tools
export CLICOLOR=1
export LSCOLORS=ExGxBxDxCxEgEdxbxgxcxd

# GNU dircolors
if command -v dircolors &> /dev/null; then
    if [[ -r ~/.dircolors ]]; then
        eval "$(dircolors -b ~/.dircolors)"
    else
        eval "$(dircolors -b)"
    fi
fi'

# Check if running on macOS
check_macos() {
    if [[ "$(uname)" != "Darwin" ]]; then
        printf "${RED}Error: This script is designed for macOS only${NC}\n"
        exit 1
    fi
}

# Check if Homebrew is installed
check_homebrew() {
    if ! command -v brew &> /dev/null; then
        printf "${RED}Error: Homebrew is not installed${NC}\n"
        printf "Install it from: https://brew.sh\n"
        exit 1
    fi
}

# Install GNU packages
install_gnu_packages() {
    printf "${CYAN}=== Installing GNU Core Packages ===${NC}\n\n"
    
    local failed=()
    local installed=0
    local skipped=0
    
    # Install core packages
    for package in "${GNU_CORE_PACKAGES[@]}"; do
        if brew list --formula "$package" &> /dev/null; then
            printf "${BLUE}✓ $package already installed${NC}\n"
            skipped=$((skipped + 1))
        else
            printf "${YELLOW}Installing $package...${NC} "
            if brew install "$package" &> /dev/null; then
                printf "${GREEN}✓${NC}\n"
                installed=$((installed + 1))
            else
                printf "${RED}✗${NC}\n"
                failed+=("$package")
            fi
        fi
    done
    
    # Ask about extended GNU utilities
    printf "\n${YELLOW}Install extended GNU utilities for complete Linux compatibility? (y/n)${NC} "
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        printf "\n${CYAN}Installing extended GNU utilities...${NC}\n"
        printf "${YELLOW}Note: This includes util-linux and inetutils for comprehensive coverage${NC}\n\n"
        for package in "${GNU_EXTENDED_PACKAGES[@]}"; do
            if brew list --formula "$package" &> /dev/null; then
                printf "${BLUE}✓ $package already installed${NC}\n"
                skipped=$((skipped + 1))
            else
                printf "${YELLOW}Installing $package...${NC} "
                if brew install "$package" &> /dev/null; then
                    printf "${GREEN}✓${NC}\n"
                    installed=$((installed + 1))
                else
                    # Some packages might not exist, that's ok
                    printf "${YELLOW}⚠ Not available${NC}\n"
                fi
            fi
        done
    fi
    
    # Ask about extra packages
    printf "\n${YELLOW}Install additional GNU tools? (y/n)${NC} "
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        printf "\n${CYAN}Installing additional GNU tools...${NC}\n"
        for package in "${GNU_EXTRA_PACKAGES[@]}"; do
            if brew list --formula "$package" &> /dev/null; then
                printf "${BLUE}✓ $package already installed${NC}\n"
                skipped=$((skipped + 1))
            else
                printf "${YELLOW}Installing $package...${NC} "
                if brew install "$package" &> /dev/null; then
                    printf "${GREEN}✓${NC}\n"
                    installed=$((installed + 1))
                else
                    printf "${RED}✗${NC}\n"
                    failed+=("$package")
                fi
            fi
        done
    fi
    
    # Ask about development tools
    printf "\n${YELLOW}Install GNU development tools? (y/n)${NC} "
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        printf "\n${CYAN}Installing development tools...${NC}\n"
        for package in "${GNU_DEV_PACKAGES[@]}"; do
            if [[ "$package" == "gdb" ]]; then
                printf "${YELLOW}Note: gdb requires additional setup on macOS${NC}\n"
                continue
            fi
            
            if brew list --formula "$package" &> /dev/null; then
                printf "${BLUE}✓ $package already installed${NC}\n"
                skipped=$((skipped + 1))
            else
                printf "${YELLOW}Installing $package...${NC} "
                if brew install "$package" &> /dev/null; then
                    printf "${GREEN}✓${NC}\n"
                    installed=$((installed + 1))
                else
                    printf "${RED}✗${NC}\n"
                    failed+=("$package")
                fi
            fi
        done
    fi
    
    # Ask about modern CLI tools
    printf "\n${YELLOW}Install modern CLI replacements (bat, ripgrep, etc.)? (y/n)${NC} "
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        printf "\n${CYAN}Installing modern CLI tools...${NC}\n"
        for package in "${MODERN_TOOLS[@]}"; do
            if brew list --formula "$package" &> /dev/null; then
                printf "${BLUE}✓ $package already installed${NC}\n"
                skipped=$((skipped + 1))
            else
                printf "${YELLOW}Installing $package...${NC} "
                if brew install "$package" &> /dev/null; then
                    printf "${GREEN}✓${NC}\n"
                    installed=$((installed + 1))
                else
                    printf "${RED}✗${NC}\n"
                    failed+=("$package")
                fi
            fi
        done
    fi
    
    printf "\n${GREEN}Installation Summary:${NC}\n"
    printf "  Installed: $installed packages\n"
    printf "  Skipped: $skipped packages (already installed)\n"
    
    if [[ ${#failed[@]} -gt 0 ]]; then
        printf "  ${RED}Failed: ${#failed[@]} packages${NC}\n"
        printf "  Failed packages: ${failed[*]}\n"
    fi
}

# Setup configuration file
setup_config() {
    printf "\n${CYAN}=== Setting Up Configuration ===${NC}\n\n"
    
    local config_file="$HOME/.mac_linuxify"
    
    # Write configuration file
    printf "%s" "$LINUXIFY_CONFIG" > "$config_file"
    chmod +x "$config_file"
    
    printf "${GREEN}✓ Created configuration file: $config_file${NC}\n"
    
    # Detect current shell
    local current_shell=$(basename "$SHELL")
    local shell_config=""
    
    case "$current_shell" in
        bash)
            shell_config="$HOME/.bashrc"
            [[ ! -f "$shell_config" ]] && shell_config="$HOME/.bash_profile"
            ;;
        zsh)
            shell_config="$HOME/.zshrc"
            ;;
        *)
            printf "${YELLOW}Warning: Unknown shell $current_shell${NC}\n"
            shell_config=""
            ;;
    esac
    
    if [[ -n "$shell_config" ]]; then
        # Check if already sourced
        if grep -q "source.*\.mac_linuxify" "$shell_config" 2>/dev/null; then
            printf "${BLUE}✓ Configuration already sourced in $shell_config${NC}\n"
        else
            printf "\n${YELLOW}Add to $shell_config? (y/n)${NC} "
            read -r response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                echo "" >> "$shell_config"
                echo "# Mac Power Tools - GNU/Linux environment" >> "$shell_config"
                echo "[[ -f ~/.mac_linuxify ]] && source ~/.mac_linuxify" >> "$shell_config"
                printf "${GREEN}✓ Added to $shell_config${NC}\n"
                printf "${YELLOW}Reload your shell or run: source ~/.mac_linuxify${NC}\n"
            fi
        fi
    else
        printf "\n${YELLOW}Add this line to your shell configuration:${NC}\n"
        printf "  [[ -f ~/.mac_linuxify ]] && source ~/.mac_linuxify\n"
    fi
}

# Change default shell to Homebrew bash
change_shell() {
    printf "\n${CYAN}=== Shell Configuration ===${NC}\n\n"
    
    local brew_bash
    if [[ -x "/opt/homebrew/bin/bash" ]]; then
        brew_bash="/opt/homebrew/bin/bash"
    elif [[ -x "/usr/local/bin/bash" ]]; then
        brew_bash="/usr/local/bin/bash"
    else
        printf "${YELLOW}Homebrew bash not found. Install with: brew install bash${NC}\n"
        return 1
    fi
    
    printf "${YELLOW}Change default shell to Homebrew bash? (y/n)${NC} "
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        # Add to /etc/shells if not present
        if ! grep -q "$brew_bash" /etc/shells; then
            printf "${YELLOW}Adding $brew_bash to /etc/shells (requires sudo)...${NC}\n"
            echo "$brew_bash" | sudo tee -a /etc/shells > /dev/null
        fi
        
        # Change shell
        printf "${YELLOW}Changing default shell...${NC}\n"
        if chsh -s "$brew_bash"; then
            printf "${GREEN}✓ Default shell changed to $brew_bash${NC}\n"
            printf "${YELLOW}Please restart your terminal for changes to take effect${NC}\n"
        else
            printf "${RED}Failed to change shell${NC}\n"
        fi
    fi
}

# Show status of GNU tools
show_status() {
    printf "${CYAN}=== GNU Tools Status ===${NC}\n\n"
    
    printf "${YELLOW}Checking installed GNU packages...${NC}\n\n"
    
    local installed=0
    local not_installed=0
    
    printf "${BLUE}Core Packages:${NC}\n"
    for package in "${GNU_CORE_PACKAGES[@]}"; do
        if brew list --formula "$package" &> /dev/null 2>&1; then
            printf "  ${GREEN}✓${NC} $package\n"
            installed=$((installed + 1))
        else
            printf "  ${RED}✗${NC} $package\n"
            not_installed=$((not_installed + 1))
        fi
    done
    
    # Check extended packages
    printf "\n${BLUE}Extended Packages:${NC}\n"
    for package in "${GNU_EXTENDED_PACKAGES[@]}"; do
        if brew list --formula "$package" &> /dev/null 2>&1; then
            printf "  ${GREEN}✓${NC} $package\n"
            installed=$((installed + 1))
        else
            printf "  ${YELLOW}○${NC} $package (optional)\n"
        fi
    done
    
    printf "\n${BLUE}Configuration:${NC}\n"
    if [[ -f "$HOME/.mac_linuxify" ]]; then
        printf "  ${GREEN}✓${NC} Configuration file exists\n"
        
        # Check if sourced in shell config
        for config in "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.zshrc"; do
            if [[ -f "$config" ]] && grep -q "source.*\.mac_linuxify" "$config" 2>/dev/null; then
                printf "  ${GREEN}✓${NC} Sourced in $(basename "$config")\n"
            fi
        done
    else
        printf "  ${RED}✗${NC} Configuration file not found\n"
    fi
    
    printf "\n${BLUE}Current Tools:${NC}\n"
    printf "  which ls:   $(which ls)\n"
    printf "  which sed:  $(which sed)\n"
    printf "  which grep: $(which grep)\n"
    printf "  which make: $(which make)\n"
    
    printf "\n${GREEN}Summary:${NC}\n"
    printf "  Installed: $installed packages\n"
    printf "  Not installed: $not_installed packages\n"
}

# Uninstall/revert
uninstall_linuxify() {
    printf "${CYAN}=== Uninstall Linuxify ===${NC}\n\n"
    
    printf "${YELLOW}This will remove the configuration file and shell modifications.${NC}\n"
    printf "${YELLOW}GNU packages will remain installed (remove with brew uninstall).${NC}\n"
    printf "${YELLOW}Continue? (y/n)${NC} "
    read -r response
    
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        printf "${BLUE}Cancelled${NC}\n"
        return 0
    fi
    
    # Remove configuration file
    if [[ -f "$HOME/.mac_linuxify" ]]; then
        rm "$HOME/.mac_linuxify"
        printf "${GREEN}✓ Removed configuration file${NC}\n"
    fi
    
    # Remove from shell configs
    for config in "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.zshrc"; do
        if [[ -f "$config" ]]; then
            # Remove the source line
            sed -i '' '/source.*\.mac_linuxify/d' "$config" 2>/dev/null || true
            sed -i '' '/Mac Power Tools - GNU\/Linux environment/d' "$config" 2>/dev/null || true
            printf "${GREEN}✓ Cleaned up $(basename "$config")${NC}\n"
        fi
    done
    
    printf "\n${GREEN}✓ Linuxify configuration removed${NC}\n"
    printf "${YELLOW}To remove GNU packages, use: brew uninstall <package>${NC}\n"
}

# Show help
show_help() {
    print_info "Mac Linuxify - Transform macOS to use GNU/Linux tools${NC}\n"
    
    print_warning "Usage:"
    echo "  mac linuxify                  Install GNU tools and configure"
    echo "  mac linuxify status           Show installed GNU tools"
    echo "  mac linuxify shell            Change default shell to bash"
    echo "  mac linuxify uninstall        Remove configuration"
    echo -e "  mac linuxify help             Show this help message\n"
    
    print_warning "What it does:"
    echo "  1. Installs GNU coreutils, sed, grep, make, etc."
    echo "  2. Optionally installs util-linux and inetutils for complete coverage"
    echo "  3. Configures PATH to use GNU tools by default"
    echo "  4. Sets up useful aliases and environment variables"
    echo -e "  5. Optionally installs modern CLI tools (bat, ripgrep, etc.)\n"
    
    print_warning "Tool Coverage:"
    echo "  - Core utilities: ls, cat, echo, mkdir, rm, cp, mv, etc."
    echo "  - Text processing: sed, awk, grep, diff, etc."
    echo "  - File utilities: find, tar, gzip, which, etc."
    echo "  - Extended utils: cal, column, hexdump, rename (util-linux)"
    echo -e "  - Network tools: ftp, telnet, traceroute, whois (inetutils)\n"
    
    print_warning "After installation:"
    echo "  - Restart your terminal or run: source ~/.mac_linuxify"
    echo "  - GNU tools will be used by default (ls, sed, grep, etc.)"
    echo -e "  - Original macOS tools still available with 'g' prefix\n"
    
    print_warning "Examples:"
    echo "  mac linuxify                  # Full installation"
    echo "  mac linuxify status           # Check what's installed"
    echo "  mac linuxify shell            # Switch to GNU bash"
}

# Main function
main() {
    local command="${1:-}"
    
    case "$command" in
        ""|install)
            check_macos
            check_homebrew
            install_gnu_packages
            setup_config
            change_shell
            printf "\n${GREEN}✓ Linuxify complete!${NC}\n"
            printf "${YELLOW}Restart your terminal or run: source ~/.mac_linuxify${NC}\n"
            ;;
        status)
            check_homebrew
            show_status
            ;;
        shell)
            change_shell
            ;;
        uninstall|remove)
            uninstall_linuxify
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            printf "${RED}Unknown command: $command${NC}\n"
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"

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
