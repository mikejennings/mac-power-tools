#!/bin/bash

# Mac Power Tools - Local Test Runner
# Comprehensive testing without GitHub Actions

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Test statistics
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Function to print colored output
print_color() {
    local color=$1
    shift
    printf "${color}%s${NC}\n" "$*"
}

# Function to print section headers
print_header() {
    echo
    print_color "$CYAN" "════════════════════════════════════════"
    print_color "$CYAN" "  $1"
    print_color "$CYAN" "════════════════════════════════════════"
    echo
}

# Function to check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to run shellcheck on all scripts
run_shellcheck() {
    print_header "ShellCheck Analysis"
    
    if ! command_exists shellcheck; then
        print_color "$YELLOW" "⚠ ShellCheck not installed"
        print_color "$YELLOW" "  Install with: brew install shellcheck"
        ((TESTS_SKIPPED++))
        return 0
    fi
    
    local errors=0
    local files_checked=0
    
    # Check main script
    print_color "$BLUE" "Checking main script..."
    if shellcheck -S warning mac 2>/dev/null; then
        print_color "$GREEN" "  ✓ mac"
        ((files_checked++))
    else
        print_color "$RED" "  ✗ mac (errors found)"
        ((errors++))
    fi
    
    # Check all scripts in scripts/ directory
    print_color "$BLUE" "Checking scripts directory..."
    for script in scripts/*.sh; do
        if [ -f "$script" ]; then
            local basename=$(basename "$script")
            if shellcheck -S warning "$script" 2>/dev/null; then
                print_color "$GREEN" "  ✓ $basename"
                ((files_checked++))
            else
                print_color "$RED" "  ✗ $basename (errors found)"
                ((errors++))
            fi
        fi
    done
    
    # Check test scripts
    print_color "$BLUE" "Checking test scripts..."
    for script in test/*.sh; do
        if [ -f "$script" ]; then
            local basename=$(basename "$script")
            if shellcheck -S warning "$script" 2>/dev/null; then
                print_color "$GREEN" "  ✓ $basename"
                ((files_checked++))
            else
                print_color "$RED" "  ✗ $basename (errors found)"
                ((errors++))
            fi
        fi
    done
    
    echo
    if [ $errors -eq 0 ]; then
        print_color "$GREEN" "✓ ShellCheck: All $files_checked files passed"
        ((TESTS_PASSED++))
    else
        print_color "$RED" "✗ ShellCheck: $errors files with issues"
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))
    
    return 0
}

# Function to check script permissions
check_permissions() {
    print_header "File Permissions Check"
    
    local issues=0
    
    # Check main script is executable
    if [ -x "mac" ]; then
        print_color "$GREEN" "✓ mac is executable"
    else
        print_color "$RED" "✗ mac is not executable"
        ((issues++))
    fi
    
    # Check all scripts in scripts/ are executable
    for script in scripts/*.sh; do
        if [ -f "$script" ]; then
            local basename=$(basename "$script")
            if [ -x "$script" ]; then
                print_color "$GREEN" "✓ $basename is executable"
            else
                print_color "$RED" "✗ $basename is not executable"
                ((issues++))
            fi
        fi
    done
    
    echo
    if [ $issues -eq 0 ]; then
        print_color "$GREEN" "✓ Permissions: All scripts are executable"
        ((TESTS_PASSED++))
    else
        print_color "$RED" "✗ Permissions: $issues files need chmod +x"
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))
    
    return 0
}

# Function to run unit tests
run_unit_tests() {
    print_header "Unit Tests"
    
    if [ -f "./test/run_tests.sh" ]; then
        print_color "$BLUE" "Running test suite..."
        
        # Run tests and capture output
        if ./test/run_tests.sh 2>&1 | tee /tmp/test_output.log; then
            print_color "$GREEN" "✓ Unit Tests: All tests passed"
            ((TESTS_PASSED++))
        else
            print_color "$RED" "✗ Unit Tests: Some tests failed"
            ((TESTS_FAILED++))
        fi
    else
        print_color "$YELLOW" "⚠ No test suite found at ./test/run_tests.sh"
        ((TESTS_SKIPPED++))
    fi
    ((TESTS_RUN++))
    
    return 0
}

# Function to check dependencies
check_dependencies() {
    print_header "Dependency Check"
    
    local missing=0
    local optional_missing=0
    
    print_color "$BLUE" "Required dependencies:"
    
    # Check required commands
    local required_cmds=("bash" "sed" "awk" "grep" "find")
    for cmd in "${required_cmds[@]}"; do
        if command_exists "$cmd"; then
            print_color "$GREEN" "  ✓ $cmd"
        else
            print_color "$RED" "  ✗ $cmd (REQUIRED)"
            ((missing++))
        fi
    done
    
    echo
    print_color "$BLUE" "Optional dependencies:"
    
    # Check optional commands
    local optional_cmds=("brew" "git" "fzf" "mas" "npm" "python3" "ruby")
    for cmd in "${optional_cmds[@]}"; do
        if command_exists "$cmd"; then
            print_color "$GREEN" "  ✓ $cmd"
        else
            print_color "$YELLOW" "  ⚠ $cmd (optional)"
            ((optional_missing++))
        fi
    done
    
    echo
    if [ $missing -eq 0 ]; then
        print_color "$GREEN" "✓ Dependencies: All required dependencies present"
        if [ $optional_missing -gt 0 ]; then
            print_color "$YELLOW" "  Note: $optional_missing optional dependencies missing"
        fi
        ((TESTS_PASSED++))
    else
        print_color "$RED" "✗ Dependencies: $missing required dependencies missing"
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))
    
    return 0
}

# Function to validate version consistency
check_version_consistency() {
    print_header "Version Consistency Check"
    
    # Get version from main script
    local mac_version=$(grep '^VERSION=' mac | cut -d'"' -f2)
    print_color "$BLUE" "Version in mac script: $mac_version"
    
    local issues=0
    
    # Check CLAUDE.md
    if [ -f "CLAUDE.md" ]; then
        if grep -q "Current version: $mac_version" CLAUDE.md; then
            print_color "$GREEN" "✓ CLAUDE.md version matches"
        else
            print_color "$RED" "✗ CLAUDE.md version mismatch"
            ((issues++))
        fi
    fi
    
    # Check if version follows semver
    if [[ $mac_version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        print_color "$GREEN" "✓ Version follows semantic versioning"
    else
        print_color "$RED" "✗ Version doesn't follow semantic versioning"
        ((issues++))
    fi
    
    echo
    if [ $issues -eq 0 ]; then
        print_color "$GREEN" "✓ Version: Consistent across all files"
        ((TESTS_PASSED++))
    else
        print_color "$RED" "✗ Version: $issues inconsistencies found"
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))
    
    return 0
}

# Function to run syntax checks
run_syntax_checks() {
    print_header "Bash Syntax Check"
    
    local errors=0
    local files_checked=0
    
    # Check main script
    if bash -n mac 2>/dev/null; then
        print_color "$GREEN" "✓ mac syntax valid"
        ((files_checked++))
    else
        print_color "$RED" "✗ mac has syntax errors"
        ((errors++))
    fi
    
    # Check all scripts
    for script in scripts/*.sh; do
        if [ -f "$script" ]; then
            local basename=$(basename "$script")
            if bash -n "$script" 2>/dev/null; then
                print_color "$GREEN" "✓ $basename syntax valid"
                ((files_checked++))
            else
                print_color "$RED" "✗ $basename has syntax errors"
                ((errors++))
            fi
        fi
    done
    
    echo
    if [ $errors -eq 0 ]; then
        print_color "$GREEN" "✓ Syntax: All $files_checked files valid"
        ((TESTS_PASSED++))
    else
        print_color "$RED" "✗ Syntax: $errors files with errors"
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))
    
    return 0
}

# Function to check for common issues
check_common_issues() {
    print_header "Common Issues Check"
    
    local issues=0
    
    # Check for hardcoded paths
    print_color "$BLUE" "Checking for hardcoded paths..."
    if grep -r "/Users/[^/]*/" scripts/ 2>/dev/null | grep -v "^Binary"; then
        print_color "$YELLOW" "⚠ Found hardcoded user paths"
        ((issues++))
    else
        print_color "$GREEN" "✓ No hardcoded user paths"
    fi
    
    # Check for TODO/FIXME comments
    print_color "$BLUE" "Checking for TODO/FIXME comments..."
    local todos=$(grep -r "TODO\|FIXME" scripts/ mac 2>/dev/null | wc -l)
    if [ "$todos" -gt 0 ]; then
        print_color "$YELLOW" "⚠ Found $todos TODO/FIXME comments"
    else
        print_color "$GREEN" "✓ No TODO/FIXME comments"
    fi
    
    # Check for debugging statements
    print_color "$BLUE" "Checking for debug statements..."
    if grep -r "set -x" scripts/ mac 2>/dev/null | grep -v "^Binary"; then
        print_color "$YELLOW" "⚠ Found 'set -x' debug statements"
        ((issues++))
    else
        print_color "$GREEN" "✓ No debug statements"
    fi
    
    echo
    if [ $issues -eq 0 ]; then
        print_color "$GREEN" "✓ Common Issues: None found"
        ((TESTS_PASSED++))
    else
        print_color "$YELLOW" "⚠ Common Issues: $issues potential issues"
        ((TESTS_PASSED++))  # Still pass, these are warnings
    fi
    ((TESTS_RUN++))
    
    return 0
}

# Function to generate test report
generate_report() {
    print_header "Test Report Summary"
    
    local total=$TESTS_RUN
    local pass_rate=0
    if [ $total -gt 0 ]; then
        pass_rate=$((TESTS_PASSED * 100 / total))
    fi
    
    print_color "$BLUE" "Tests Run:     $TESTS_RUN"
    print_color "$GREEN" "Tests Passed:  $TESTS_PASSED"
    print_color "$RED" "Tests Failed:  $TESTS_FAILED"
    print_color "$YELLOW" "Tests Skipped: $TESTS_SKIPPED"
    echo
    
    if [ $TESTS_FAILED -eq 0 ]; then
        print_color "$GREEN" "✓ All tests passed! (${pass_rate}% pass rate)"
        return 0
    else
        print_color "$RED" "✗ Some tests failed (${pass_rate}% pass rate)"
        return 1
    fi
}

# Function to run quick tests only
run_quick_tests() {
    print_color "$CYAN" "Running quick tests..."
    run_syntax_checks
    check_permissions
    check_version_consistency
}

# Function to run all tests
run_all_tests() {
    print_color "$CYAN" "Running comprehensive test suite..."
    check_dependencies
    run_syntax_checks
    check_permissions
    run_shellcheck
    check_version_consistency
    check_common_issues
    run_unit_tests
}

# Main function
main() {
    print_color "$MAGENTA" "╔════════════════════════════════════════╗"
    print_color "$MAGENTA" "║   Mac Power Tools - Local Test Suite   ║"
    print_color "$MAGENTA" "╚════════════════════════════════════════╝"
    
    case "${1:-all}" in
        quick)
            run_quick_tests
            ;;
        syntax)
            run_syntax_checks
            ;;
        shellcheck)
            run_shellcheck
            ;;
        deps|dependencies)
            check_dependencies
            ;;
        unit)
            run_unit_tests
            ;;
        version)
            check_version_consistency
            ;;
        permissions)
            check_permissions
            ;;
        issues)
            check_common_issues
            ;;
        all)
            run_all_tests
            ;;
        help|--help|-h)
            echo "Usage: $0 [command]"
            echo ""
            echo "Commands:"
            echo "  all          Run all tests (default)"
            echo "  quick        Run quick tests only"
            echo "  syntax       Check bash syntax"
            echo "  shellcheck   Run ShellCheck analysis"
            echo "  deps         Check dependencies"
            echo "  unit         Run unit tests"
            echo "  version      Check version consistency"
            echo "  permissions  Check file permissions"
            echo "  issues       Check for common issues"
            echo "  help         Show this help"
            exit 0
            ;;
        *)
            print_color "$RED" "Unknown command: $1"
            echo "Run '$0 help' for usage"
            exit 1
            ;;
    esac
    
    echo
    generate_report
    exit_code=$?
    
    echo
    print_color "$CYAN" "Test run completed at $(date '+%Y-%m-%d %H:%M:%S')"
    
    exit $exit_code
}

# Run main function
main "$@"