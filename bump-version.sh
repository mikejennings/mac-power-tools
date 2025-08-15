#!/bin/bash

# Mac Power Tools - Version Bump Script (Local Edition)
# This script helps bump the version locally without GitHub Actions

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

# Get current version
CURRENT_VERSION=$(grep '^VERSION=' mac | cut -d'"' -f2)
print_color "$BLUE" "Current version: $CURRENT_VERSION"

# Parse version components
IFS='.' read -r major minor patch <<< "$CURRENT_VERSION"

# Show options
echo
print_color "$YELLOW" "Select version bump type:"
echo "1) Patch ($major.$minor.$((patch + 1)))"
echo "2) Minor ($major.$((minor + 1)).0)"
echo "3) Major ($((major + 1)).0.0)"
echo "4) Custom"
echo "5) Exit"
echo

read -p "Choice (1-5): " choice

case $choice in
    1)
        patch=$((patch + 1))
        NEW_VERSION="$major.$minor.$patch"
        BUMP_TYPE="patch"
        ;;
    2)
        minor=$((minor + 1))
        patch=0
        NEW_VERSION="$major.$minor.$patch"
        BUMP_TYPE="minor"
        ;;
    3)
        major=$((major + 1))
        minor=0
        patch=0
        NEW_VERSION="$major.$minor.$patch"
        BUMP_TYPE="major"
        ;;
    4)
        read -p "Enter new version (e.g., 1.2.3): " NEW_VERSION
        BUMP_TYPE="custom"
        ;;
    5)
        print_color "$YELLOW" "Exiting without changes"
        exit 0
        ;;
    *)
        print_color "$RED" "Invalid choice"
        exit 1
        ;;
esac

print_color "$GREEN" "New version will be: $NEW_VERSION"
echo

# Ask for changelog entry
print_color "$CYAN" "Enter changelog entry (or press Enter to skip):"
read -r CHANGELOG

# Update version in mac script
print_color "$YELLOW" "Updating version in mac script..."
sed -i.bak "s/^VERSION=\"${CURRENT_VERSION}\"/VERSION=\"${NEW_VERSION}\"/" mac
rm mac.bak

# Update version in CLAUDE.md
print_color "$YELLOW" "Updating version in CLAUDE.md..."
sed -i.bak "s/Current version: ${CURRENT_VERSION}/Current version: ${NEW_VERSION}/" CLAUDE.md
rm CLAUDE.md.bak

# Update README if changelog provided
if [ -n "$CHANGELOG" ]; then
    print_color "$YELLOW" "Adding changelog entry to README.md..."
    
    # Create new changelog entry
    CHANGELOG_ENTRY="### v${NEW_VERSION} ($(date +%Y-%m-%d))\n- ${CHANGELOG}"
    
    # Find the Changelog section and insert new entry after it
    awk '/^## Changelog$/ {
        print
        print ""
        print "'"${CHANGELOG_ENTRY}"'"
        next
    } 1' README.md > README.tmp
    mv README.tmp README.md
fi

# Show what changed
echo
print_color "$GREEN" "✓ Version bumped from $CURRENT_VERSION to $NEW_VERSION"
print_color "$CYAN" "Files updated:"
echo "  - mac"
echo "  - CLAUDE.md"
[ -n "$CHANGELOG" ] && echo "  - README.md (changelog)"

# Ask if should commit
echo
read -p "Commit changes? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    git add mac CLAUDE.md README.md
    
    COMMIT_MSG="Bump version to ${NEW_VERSION}"
    [ -n "$CHANGELOG" ] && COMMIT_MSG="${COMMIT_MSG}

- ${CHANGELOG}"
    
    git commit -m "$COMMIT_MSG"
    print_color "$GREEN" "✓ Changes committed locally"
    
    # Ask about next steps
    echo
    print_color "$CYAN" "Version bumped successfully!"
    print_color "$YELLOW" "Next steps:"
    echo "  1. Run tests: ./local-test.sh"
    echo "  2. Create release: ./local-release.sh release"
    echo "  3. Push to GitHub: git push origin master"
    echo
    
    read -p "Run tests now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ./local-test.sh quick
        echo
        read -p "Create release? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ./local-release.sh release
        fi
    fi
else
    print_color "$YELLOW" "Changes made but not committed"
    print_color "$CYAN" "Run 'git diff' to see changes"
fi