#!/bin/bash

# Homebrew Tap Sync Manager for Mac Power Tools
# Manages synchronization between main repo and Homebrew tap

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
MAIN_REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOMEBREW_TAP_DIR="$HOME/src/github/mikejennings/homebrew-mac-power-tools"
FORMULA_FILE="Formula/mac-power-tools.rb"

print_info() { echo -e "${CYAN}ℹ${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }

# Initialize Homebrew tap if not exists
init_tap() {
    if [ ! -d "$HOMEBREW_TAP_DIR" ]; then
        print_info "Homebrew tap not found. Cloning..."
        git clone https://github.com/mikejennings/homebrew-mac-power-tools.git "$HOMEBREW_TAP_DIR"
        print_success "Homebrew tap cloned"
    else
        print_info "Homebrew tap already exists"
    fi
}

# Sync formula from tap to main repo
pull_formula() {
    print_info "Pulling latest formula from Homebrew tap..."
    
    cd "$HOMEBREW_TAP_DIR"
    git pull origin main
    
    if [ -f "$HOMEBREW_TAP_DIR/$FORMULA_FILE" ]; then
        mkdir -p "$MAIN_REPO_DIR/homebrew/Formula"
        cp "$HOMEBREW_TAP_DIR/$FORMULA_FILE" "$MAIN_REPO_DIR/homebrew/Formula/"
        print_success "Formula pulled from tap"
    else
        print_error "Formula not found in tap"
        return 1
    fi
}

# Push formula from main repo to tap
push_formula() {
    print_info "Pushing formula to Homebrew tap..."
    
    if [ ! -f "$MAIN_REPO_DIR/homebrew/Formula/mac-power-tools.rb" ]; then
        print_error "Formula not found in main repo"
        return 1
    fi
    
    cp "$MAIN_REPO_DIR/homebrew/Formula/mac-power-tools.rb" "$HOMEBREW_TAP_DIR/$FORMULA_FILE"
    
    cd "$HOMEBREW_TAP_DIR"
    git add "$FORMULA_FILE"
    
    if git diff --staged --quiet; then
        print_info "No changes to push"
    else
        git commit -m "Update Mac Power Tools formula"
        git push origin main
        print_success "Formula pushed to tap"
    fi
}

# Check formula syntax
check_formula() {
    print_info "Checking formula syntax..."
    
    if command -v brew &> /dev/null; then
        if [ -f "$HOMEBREW_TAP_DIR/$FORMULA_FILE" ]; then
            if brew audit --formula "$HOMEBREW_TAP_DIR/$FORMULA_FILE" 2>/dev/null; then
                print_success "Formula syntax is valid"
            else
                print_warning "Formula has issues (run 'brew audit' for details)"
            fi
        fi
    else
        print_warning "Homebrew not installed, skipping formula check"
    fi
}

# Show status
show_status() {
    print_info "Homebrew Tap Status"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Check main repo version
    if [ -f "$MAIN_REPO_DIR/mac" ]; then
        local main_version=$(grep -E "^VERSION=" "$MAIN_REPO_DIR/mac" | cut -d'"' -f2)
        echo "Main repo version: $main_version"
    fi
    
    # Check formula version
    if [ -f "$HOMEBREW_TAP_DIR/$FORMULA_FILE" ]; then
        local formula_version=$(grep -E "^\s*url.*\/v[0-9]" "$HOMEBREW_TAP_DIR/$FORMULA_FILE" | grep -oE "v[0-9]+\.[0-9]+\.[0-9]+" | sed 's/v//')
        echo "Formula version: $formula_version"
    fi
    
    # Check git status
    echo
    echo "Homebrew tap git status:"
    cd "$HOMEBREW_TAP_DIR" 2>/dev/null && git status --short
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Main menu
main() {
    echo -e "${BLUE}═══════════════════════════════════════════${NC}"
    echo -e "${BLUE}    Homebrew Tap Sync Manager${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════${NC}"
    echo
    
    PS3="Select an option: "
    options=(
        "Initialize tap"
        "Pull formula from tap"
        "Push formula to tap"
        "Check formula syntax"
        "Show status"
        "Full sync (pull + check)"
        "Exit"
    )
    
    select opt in "${options[@]}"; do
        case $REPLY in
            1) init_tap ;;
            2) pull_formula ;;
            3) push_formula ;;
            4) check_formula ;;
            5) show_status ;;
            6) pull_formula && check_formula ;;
            7) break ;;
            *) print_error "Invalid option" ;;
        esac
        echo
    done
}

# Handle command line arguments
case "${1:-}" in
    init)
        init_tap
        ;;
    pull)
        pull_formula
        ;;
    push)
        push_formula
        ;;
    check)
        check_formula
        ;;
    status)
        show_status
        ;;
    sync)
        pull_formula && check_formula
        ;;
    *)
        main
        ;;
esac