#!/bin/bash

# Mac Power Tools Release Manager
# Comprehensive local release management without GitHub Actions

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOMEBREW_TAP_DIR="$HOME/src/github/mikejennings/homebrew-mac-power-tools"
CURRENT_VERSION=$(grep -E "^VERSION=" "$SCRIPT_DIR/mac" | cut -d'"' -f2)

# Functions
print_header() {
    echo -e "${BLUE}═══════════════════════════════════════════${NC}"
    echo -e "${BLUE}     Mac Power Tools Release Manager${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════${NC}"
}

print_info() { echo -e "${CYAN}ℹ${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    local missing_tools=()
    
    # Check required tools
    for tool in git gh jq curl shasum; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        print_info "Install with: brew install ${missing_tools[*]}"
        return 1
    fi
    
    # Check if Homebrew tap exists
    if [ ! -d "$HOMEBREW_TAP_DIR" ]; then
        print_warning "Homebrew tap not found at $HOMEBREW_TAP_DIR"
        print_info "Clone it with: git clone https://github.com/mikejennings/homebrew-mac-power-tools.git $HOMEBREW_TAP_DIR"
        return 1
    fi
    
    print_success "All prerequisites met"
    return 0
}

# Run tests
run_tests() {
    print_info "Running test suite..."
    
    if [ -f "$SCRIPT_DIR/local-test.sh" ]; then
        if "$SCRIPT_DIR/local-test.sh" quick; then
            print_success "Tests passed"
            return 0
        else
            print_error "Tests failed"
            return 1
        fi
    else
        print_warning "Test script not found, skipping tests"
        return 0
    fi
}

# Create release archive
create_archive() {
    local version=$1
    local archive_name="mac-power-tools-${version}.tar.gz"
    local archive_path="/tmp/${archive_name}"
    
    print_info "Creating release archive..."
    
    # Create clean archive without git files
    cd "$SCRIPT_DIR"
    tar -czf "$archive_path" \
        --exclude=".git" \
        --exclude=".gitignore" \
        --exclude="*.swp" \
        --exclude=".DS_Store" \
        --exclude="homebrew" \
        --exclude="release-manager.sh" \
        .
    
    print_success "Archive created: $archive_path"
    echo "$archive_path"
}

# Calculate SHA256
calculate_sha256() {
    local file=$1
    local sha256=$(shasum -a 256 "$file" | cut -d' ' -f1)
    echo "$sha256"
}

# Update Homebrew formula
update_homebrew_formula() {
    local version=$1
    local archive_path=$2
    local sha256=$3
    
    print_info "Updating Homebrew formula..."
    
    # Navigate to Homebrew tap
    cd "$HOMEBREW_TAP_DIR"
    
    # Pull latest changes
    git pull origin main 2>/dev/null || true
    
    # Update formula file
    local formula_file="Formula/mac-power-tools.rb"
    
    if [ ! -f "$formula_file" ]; then
        print_error "Formula file not found: $formula_file"
        return 1
    fi
    
    # Create formula update
    cat > "$formula_file" << EOF
class MacPowerTools < Formula
  desc "Comprehensive macOS system management CLI tool"
  homepage "https://github.com/mikejennings/mac-power-tools"
  url "https://github.com/mikejennings/mac-power-tools/archive/refs/tags/v${version}.tar.gz"
  sha256 "${sha256}"
  license "MIT"

  depends_on :macos

  def install
    bin.install "mac"
    
    # Install all library files
    lib.install Dir["lib/*"]
    
    # Install plugins
    (lib/"plugins").mkpath
    (lib/"plugins").install Dir["plugins/*"]
    
    # Install test suite
    (lib/"test").mkpath
    (lib/"test").install Dir["test/*"] if Dir.exist?("test")
    
    # Install additional scripts
    bin.install Dir["*.sh"].reject { |f| f == "install.sh" || f == "release-manager.sh" }
    
    # Create symlink in libexec for better organization
    libexec.install_symlink lib/"plugins"
    libexec.install_symlink lib/"lib"
  end

  def caveats
    <<~EOS
      Mac Power Tools has been installed!
      
      Run 'mac help' to get started.
      
      To enable all features, you may need to install optional dependencies:
        brew install fzf          # For interactive menus
        brew install blueutil     # For Bluetooth management
        brew install mas          # For Mac App Store updates
        
      Plugin system is now available. Manage plugins with:
        mac plugin list          # List all plugins
        mac plugin enable <name> # Enable a plugin
        mac plugin disable <name> # Disable a plugin
    EOS
  end

  test do
    system "#{bin}/mac", "--version"
  end
end
EOF
    
    print_success "Formula updated for version $version"
}

# Create git tag
create_git_tag() {
    local version=$1
    
    print_info "Creating git tag v$version..."
    
    cd "$SCRIPT_DIR"
    
    # Create annotated tag
    git tag -a "v$version" -m "Release v$version

Mac Power Tools v$version

See CHANGELOG.md for details."
    
    print_success "Git tag created: v$version"
}

# Push changes
push_changes() {
    local version=$1
    
    print_info "Pushing changes..."
    
    # Push main repository
    cd "$SCRIPT_DIR"
    git push origin master
    git push origin "v$version"
    
    # Commit and push Homebrew formula
    cd "$HOMEBREW_TAP_DIR"
    git add Formula/mac-power-tools.rb
    git commit -m "Update Mac Power Tools to v$version" || true
    git push origin main
    
    print_success "Changes pushed to repositories"
}

# Create GitHub release
create_github_release() {
    local version=$1
    local archive_path=$2
    
    print_info "Creating GitHub release..."
    
    cd "$SCRIPT_DIR"
    
    # Get recent commits for release notes
    local release_notes=$(git log --pretty=format:"- %s" HEAD~10..HEAD)
    
    # Create release with gh CLI
    gh release create "v$version" \
        "$archive_path" \
        --title "v$version" \
        --notes "# Mac Power Tools v$version

## What's Changed
$release_notes

## Installation

### Via Homebrew
\`\`\`bash
brew update
brew upgrade mac-power-tools
\`\`\`

### Manual Installation
\`\`\`bash
curl -L https://github.com/mikejennings/mac-power-tools/archive/refs/tags/v$version.tar.gz | tar xz
cd mac-power-tools-$version
./install.sh
\`\`\`

**Full Changelog**: https://github.com/mikejennings/mac-power-tools/compare/v$CURRENT_VERSION...v$version"
    
    print_success "GitHub release created"
}

# Main release flow
main() {
    print_header
    
    # Check prerequisites
    if ! check_prerequisites; then
        exit 1
    fi
    
    # Get new version
    echo
    print_info "Current version: $CURRENT_VERSION"
    read -p "Enter new version (without 'v' prefix): " NEW_VERSION
    
    if [ -z "$NEW_VERSION" ]; then
        print_error "Version cannot be empty"
        exit 1
    fi
    
    # Confirm release
    echo
    print_warning "This will create release v$NEW_VERSION"
    read -p "Continue? (y/N) " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Release cancelled"
        exit 0
    fi
    
    # Run tests
    echo
    if ! run_tests; then
        print_error "Tests failed. Fix issues before releasing."
        exit 1
    fi
    
    # Update version in main script
    print_info "Updating version in mac script..."
    sed -i '' "s/VERSION=\".*\"/VERSION=\"$NEW_VERSION\"/" "$SCRIPT_DIR/mac"
    
    # Commit version change
    cd "$SCRIPT_DIR"
    git add mac
    git commit -m "Bump version to $NEW_VERSION" || true
    
    # Create archive
    echo
    ARCHIVE_PATH=$(create_archive "$NEW_VERSION")
    
    # Calculate SHA256
    SHA256=$(calculate_sha256 "$ARCHIVE_PATH")
    print_info "SHA256: $SHA256"
    
    # Update Homebrew formula
    echo
    update_homebrew_formula "$NEW_VERSION" "$ARCHIVE_PATH" "$SHA256"
    
    # Create git tag
    echo
    create_git_tag "$NEW_VERSION"
    
    # Push all changes
    echo
    push_changes "$NEW_VERSION"
    
    # Create GitHub release
    echo
    create_github_release "$NEW_VERSION" "$ARCHIVE_PATH"
    
    # Summary
    echo
    print_header
    print_success "Release v$NEW_VERSION completed successfully!"
    echo
    print_info "Next steps:"
    echo "  1. Verify the release at: https://github.com/mikejennings/mac-power-tools/releases"
    echo "  2. Test Homebrew installation: brew update && brew upgrade mac-power-tools"
    echo "  3. Update documentation if needed"
    echo
    print_success "Release complete! 🎉"
}

# Handle script arguments
case "${1:-}" in
    --check)
        check_prerequisites
        ;;
    --test)
        run_tests
        ;;
    --help|-h)
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --check    Check prerequisites only"
        echo "  --test     Run tests only"
        echo "  --help     Show this help message"
        echo ""
        echo "Without options, runs the full release process"
        ;;
    *)
        main
        ;;
esac