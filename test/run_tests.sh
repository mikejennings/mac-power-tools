#!/bin/bash

# Main test runner for Mac Power Tools
# Runs all test suites and generates a report

# Get the directory where this script is located
TEST_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$TEST_DIR")"

# Source the test helper
source "$TEST_DIR/test_helper.sh"

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Test results
TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0

printf "${BLUE}════════════════════════════════════════════════${NC}\n"
printf "${BLUE}    Mac Power Tools - Test Suite Runner${NC}\n"
printf "${BLUE}════════════════════════════════════════════════${NC}\n"
printf "Project Directory: $PROJECT_DIR\n"
printf "Test Directory: $TEST_DIR\n"

# Function to run a test file
run_test_file() {
    local test_file="$1"
    local suite_name=$(basename "$test_file" .test.sh)
    
    ((TOTAL_SUITES++))
    
    printf "\n${BLUE}Running: $suite_name${NC}\n"
    
    if bash "$test_file"; then
        ((PASSED_SUITES++))
        printf "${GREEN}✓ Suite passed: $suite_name${NC}\n"
    else
        ((FAILED_SUITES++))
        printf "${RED}✗ Suite failed: $suite_name${NC}\n"
    fi
}

# Run all test files
if [[ "$1" == "" ]]; then
    # Run all tests
    for test_file in "$TEST_DIR"/*.test.sh; do
        if [[ -f "$test_file" ]]; then
            run_test_file "$test_file"
        fi
    done
else
    # Run specific test
    if [[ -f "$TEST_DIR/$1.test.sh" ]]; then
        run_test_file "$TEST_DIR/$1.test.sh"
    elif [[ -f "$1" ]]; then
        run_test_file "$1"
    else
        printf "${RED}Test file not found: $1${NC}\n"
        exit 1
    fi
fi

# Print final summary
printf "\n${BLUE}════════════════════════════════════════════════${NC}\n"
printf "${BLUE}    Final Test Summary${NC}\n"
printf "${BLUE}════════════════════════════════════════════════${NC}\n"
printf "Total Test Suites: $TOTAL_SUITES\n"
printf "${GREEN}Passed Suites: $PASSED_SUITES${NC}\n"
printf "${RED}Failed Suites: $FAILED_SUITES${NC}\n"

if [[ $FAILED_SUITES -eq 0 && $TOTAL_SUITES -gt 0 ]]; then
    printf "\n${GREEN}✓✓✓ All test suites passed! ✓✓✓${NC}\n"
    exit 0
elif [[ $TOTAL_SUITES -eq 0 ]]; then
    printf "\n${YELLOW}No test suites found${NC}\n"
    printf "Create test files with .test.sh extension in: $TEST_DIR\n"
    exit 1
else
    printf "\n${RED}✗✗✗ Some test suites failed ✗✗✗${NC}\n"
    exit 1
fi