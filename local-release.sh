#!/bin/bash

# Mac Power Tools - Local Release Management Script
# Replaces GitHub Actions with local release management

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    local color=$1
    shift
    printf "${color}%s${NC}\n" "$*"
}

# Function to print section headers
print_header() {
    echo
    print_color "$CYAN" "=== $1 ==="
    echo
}

# Function to check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to run tests
run_tests() {
    print_header "Running Tests"
    
    if [ -f "./test/run_tests.sh" ]; then
        print_color "$YELLOW" "Running test suite..."
        if ./test/run_tests.sh; then
            print_color "$GREEN" "✓ All tests passed"
            return 0
        else
            print_color "$RED" "✗ Tests failed"
            return 1
        fi
    else
        print_color "$YELLOW" "No test suite found, skipping tests"
        return 0
    fi
}

# Function to run shellcheck
run_shellcheck() {
    print_header "Running ShellCheck"
    
    if command_exists shellcheck; then
        print_color "$YELLOW" "Running shellcheck on all scripts..."
        local errors=0
        
        # Check main script
        if ! shellcheck mac; then
            ((errors++))
        fi
        
        # Check all scripts in scripts/ directory
        for script in scripts/*.sh; do
            if [ -f "$script" ]; then
                if ! shellcheck "$script"; then
                    ((errors++))
                fi
            fi
        done
        
        if [ $errors -eq 0 ]; then
            print_color "$GREEN" "✓ ShellCheck passed"
            return 0
        else
            print_color "$RED" "✗ ShellCheck found $errors issues"
            return 1
        fi
    else
        print_color "$YELLOW" "ShellCheck not installed. Install with: brew install shellcheck"
        return 0
    fi
}

# Function to create release archive
create_release_archive() {
    local version=$1
    print_header "Creating Release Archive"
    
    local archive_name="mac-power-tools-${version}.tar.gz"
    local temp_dir="mac-power-tools-${version}"
    
    print_color "$YELLOW" "Creating release archive: $archive_name"
    
    # Create temporary directory
    rm -rf "$temp_dir"
    mkdir "$temp_dir"
    
    # Copy files to temp directory
    cp -r mac scripts/ README.md LICENSE install.sh "$temp_dir/"
    
    # Create archive
    tar -czf "$archive_name" "$temp_dir"
    rm -rf "$temp_dir"
    
    # Generate SHA256
    if command_exists shasum; then
        shasum -a 256 "$archive_name" > "${archive_name}.sha256"
        print_color "$GREEN" "✓ Created $archive_name"
        print_color "$GREEN" "✓ Created ${archive_name}.sha256"
    else
        print_color "$YELLOW" "Warning: shasum not found, skipping SHA256 generation"
    fi
    
    return 0
}

# Function to create git tag
create_git_tag() {
    local version=$1
    local message=$2
    
    print_header "Creating Git Tag"
    
    local tag="v${version}"
    
    # Check if tag already exists
    if git rev-parse "$tag" >/dev/null 2>&1; then
        print_color "$YELLOW" "Tag $tag already exists"
        read -p "Delete and recreate tag? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git tag -d "$tag"
            git push origin --delete "$tag" 2>/dev/null || true
        else
            return 1
        fi
    fi
    
    # Create annotated tag
    if [ -n "$message" ]; then
        git tag -a "$tag" -m "$message"
    else
        git tag -a "$tag" -m "Release version $version"
    fi
    
    print_color "$GREEN" "✓ Created tag $tag"
    
    # Ask if should push tag
    read -p "Push tag to GitHub? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git push origin "$tag"
        print_color "$GREEN" "✓ Pushed tag $tag to GitHub"
    fi
    
    return 0
}

# Function to update Homebrew formula locally
update_homebrew_formula() {
    local version=$1
    local sha256=$2
    
    print_header "Updating Homebrew Formula"
    
    local tap_dir="$HOME/src/github/mikejennings/homebrew-mac-power-tools"
    
    if [ ! -d "$tap_dir" ]; then
        print_color "$YELLOW" "Homebrew tap not found at $tap_dir"
        read -p "Clone homebrew tap? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git clone https://github.com/mikejennings/homebrew-mac-power-tools.git "$tap_dir"
        else
            return 1
        fi
    fi
    
    cd "$tap_dir"
    
    # Update formula
    local formula_file="Formula/mac-power-tools.rb"
    if [ -f "$formula_file" ]; then
        # Update version
        sed -i.bak "s/version \".*\"/version \"${version}\"/" "$formula_file"
        
        # Update SHA256 if provided
        if [ -n "$sha256" ]; then
            sed -i.bak "s/sha256 \".*\"/sha256 \"${sha256}\"/" "$formula_file"
        fi
        
        rm "${formula_file}.bak"
        
        print_color "$GREEN" "✓ Updated Homebrew formula"
        
        # Commit and push
        git add "$formula_file"
        git commit -m "Update to version ${version}"
        
        read -p "Push Homebrew formula update? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git push origin main
            print_color "$GREEN" "✓ Pushed Homebrew formula update"
        fi
    else
        print_color "$RED" "Formula file not found"
        return 1
    fi
    
    cd - > /dev/null
    return 0
}

# Function to show release checklist
show_release_checklist() {
    local version=$1
    
    print_header "Release Checklist for v${version}"
    
    echo "Pre-release:"
    echo "  [ ] All features implemented and tested"
    echo "  [ ] Documentation updated (README.md, CLAUDE.md)"
    echo "  [ ] Changelog entry added"
    echo "  [ ] Version bumped in all files"
    echo ""
    echo "Release:"
    echo "  [ ] Tests passing"
    echo "  [ ] ShellCheck passing"
    echo "  [ ] Git tag created"
    echo "  [ ] Release archive created"
    echo "  [ ] Homebrew formula updated"
    echo ""
    echo "Post-release:"
    echo "  [ ] Test installation via Homebrew"
    echo "  [ ] Announce release (if needed)"
    echo ""
}

# Function to perform full release
full_release() {
    local version=$1
    
    print_header "Full Release Process for v${version}"
    
    # Run tests
    if ! run_tests; then
        print_color "$RED" "Tests failed. Fix issues before releasing."
        return 1
    fi
    
    # Run shellcheck
    if ! run_shellcheck; then
        read -p "ShellCheck found issues. Continue anyway? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    # Create release archive
    create_release_archive "$version"
    
    # Get SHA256 if it was created
    local sha256=""
    if [ -f "mac-power-tools-${version}.tar.gz.sha256" ]; then
        sha256=$(cut -d' ' -f1 < "mac-power-tools-${version}.tar.gz.sha256")
    fi
    
    # Create git tag
    create_git_tag "$version" "Release version ${version}"
    
    # Update Homebrew formula
    update_homebrew_formula "$version" "$sha256"
    
    print_header "Release Complete!"
    print_color "$GREEN" "✓ Version ${version} has been released"
    print_color "$CYAN" "Next steps:"
    echo "  1. Test installation: brew upgrade mac-power-tools"
    echo "  2. Create GitHub release manually if desired"
    echo "  3. Clean up release files: rm mac-power-tools-${version}.*"
}

# Main menu
show_menu() {
    print_color "$CYAN" "Mac Power Tools - Local Release Manager"
    echo
    print_color "$YELLOW" "Select an option:"
    echo "1) Run tests only"
    echo "2) Run ShellCheck only"
    echo "3) Create release archive"
    echo "4) Create git tag"
    echo "5) Update Homebrew formula"
    echo "6) Full release (all steps)"
    echo "7) Show release checklist"
    echo "8) Exit"
    echo
}

# Main function
main() {
    # Get current version
    CURRENT_VERSION=$(grep '^VERSION=' mac | cut -d'"' -f2)
    
    if [ $# -eq 0 ]; then
        # Interactive mode
        while true; do
            show_menu
            print_color "$BLUE" "Current version: $CURRENT_VERSION"
            echo
            read -p "Choice (1-8): " choice
            
            case $choice in
                1)
                    run_tests
                    ;;
                2)
                    run_shellcheck
                    ;;
                3)
                    create_release_archive "$CURRENT_VERSION"
                    ;;
                4)
                    read -p "Enter release message (optional): " message
                    create_git_tag "$CURRENT_VERSION" "$message"
                    ;;
                5)
                    sha256=""
                    if [ -f "mac-power-tools-${CURRENT_VERSION}.tar.gz.sha256" ]; then
                        sha256=$(cut -d' ' -f1 < "mac-power-tools-${CURRENT_VERSION}.tar.gz.sha256")
                    fi
                    update_homebrew_formula "$CURRENT_VERSION" "$sha256"
                    ;;
                6)
                    full_release "$CURRENT_VERSION"
                    ;;
                7)
                    show_release_checklist "$CURRENT_VERSION"
                    ;;
                8)
                    print_color "$YELLOW" "Goodbye!"
                    exit 0
                    ;;
                *)
                    print_color "$RED" "Invalid choice"
                    ;;
            esac
            
            echo
            read -p "Press Enter to continue..."
        done
    else
        # Command line mode
        case "$1" in
            test)
                run_tests
                ;;
            check)
                run_shellcheck
                ;;
            archive)
                create_release_archive "$CURRENT_VERSION"
                ;;
            tag)
                create_git_tag "$CURRENT_VERSION" "${2:-}"
                ;;
            homebrew)
                sha256="${2:-}"
                update_homebrew_formula "$CURRENT_VERSION" "$sha256"
                ;;
            release)
                full_release "$CURRENT_VERSION"
                ;;
            checklist)
                show_release_checklist "$CURRENT_VERSION"
                ;;
            *)
                print_color "$RED" "Unknown command: $1"
                echo "Usage: $0 [test|check|archive|tag|homebrew|release|checklist]"
                exit 1
                ;;
        esac
    fi
}

# Run main function
main "$@"