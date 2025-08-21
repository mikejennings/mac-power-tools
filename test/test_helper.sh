#!/bin/bash

# Test helper functions for Mac Power Tools
# Provides a simple testing framework for bash scripts

# Colors for test output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Test results array
declare -a TEST_RESULTS

# Helper function for test steps
test_step() {
    local step_name="$1"
    printf "\n${YELLOW}▶ Testing: ${step_name}${NC}\n"
}

# Helper function to mark test as passed
pass() {
    local message="$1"
    printf "  ${GREEN}✓ PASS${NC}: $message\n"
    ((TESTS_PASSED++))
}

# Helper function to mark test as failed
fail() {
    local message="$1"
    printf "  ${RED}✗ FAIL${NC}: $message\n"
    ((TESTS_FAILED++))
}

# Function to start a test suite
test_suite() {
    local suite_name="$1"
    printf "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    printf "${BLUE}Running Test Suite: ${suite_name}${NC}\n"
    printf "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    TESTS_RUN=0
    TESTS_PASSED=0
    TESTS_FAILED=0
    TESTS_SKIPPED=0
    TEST_RESULTS=()
}

# Function to run a test
test() {
    local test_name="$1"
    local test_command="$2"
    
    ((TESTS_RUN++))
    
    printf "\n${YELLOW}▶ Test ${TESTS_RUN}: ${test_name}${NC}\n"
    
    # Run the test command
    if eval "$test_command" > /dev/null 2>&1; then
        printf "  ${GREEN}✓ PASSED${NC}\n"
        ((TESTS_PASSED++))
        TEST_RESULTS+=("PASS: $test_name")
    else
        printf "  ${RED}✗ FAILED${NC}\n"
        ((TESTS_FAILED++))
        TEST_RESULTS+=("FAIL: $test_name")
    fi
}

# Function to test with expected output
test_output() {
    local test_name="$1"
    local test_command="$2"
    local expected_output="$3"
    
    ((TESTS_RUN++))
    
    printf "\n${YELLOW}▶ Test ${TESTS_RUN}: ${test_name}${NC}\n"
    
    local actual_output
    actual_output=$(eval "$test_command" 2>&1)
    
    if [[ "$actual_output" == *"$expected_output"* ]]; then
        printf "  ${GREEN}✓ PASSED${NC}\n"
        ((TESTS_PASSED++))
        TEST_RESULTS+=("PASS: $test_name")
    else
        printf "  ${RED}✗ FAILED${NC}\n"
        printf "  Expected output to contain: '$expected_output'\n"
        printf "  Actual output: '$actual_output'\n"
        ((TESTS_FAILED++))
        TEST_RESULTS+=("FAIL: $test_name")
    fi
}

# Function to test file existence
test_file_exists() {
    local test_name="$1"
    local file_path="$2"
    
    ((TESTS_RUN++))
    
    printf "\n${YELLOW}▶ Test ${TESTS_RUN}: ${test_name}${NC}\n"
    
    if [[ -f "$file_path" ]]; then
        printf "  ${GREEN}✓ PASSED${NC} - File exists: $file_path\n"
        ((TESTS_PASSED++))
        TEST_RESULTS+=("PASS: $test_name")
    else
        printf "  ${RED}✗ FAILED${NC} - File not found: $file_path\n"
        ((TESTS_FAILED++))
        TEST_RESULTS+=("FAIL: $test_name")
    fi
}

# Function to test directory existence
test_dir_exists() {
    local test_name="$1"
    local dir_path="$2"
    
    ((TESTS_RUN++))
    
    printf "\n${YELLOW}▶ Test ${TESTS_RUN}: ${test_name}${NC}\n"
    
    if [[ -d "$dir_path" ]]; then
        printf "  ${GREEN}✓ PASSED${NC} - Directory exists: $dir_path\n"
        ((TESTS_PASSED++))
        TEST_RESULTS+=("PASS: $test_name")
    else
        printf "  ${RED}✗ FAILED${NC} - Directory not found: $dir_path\n"
        ((TESTS_FAILED++))
        TEST_RESULTS+=("FAIL: $test_name")
    fi
}

# Function to test command availability
test_command_exists() {
    local test_name="$1"
    local command_name="$2"
    
    ((TESTS_RUN++))
    
    printf "\n${YELLOW}▶ Test ${TESTS_RUN}: ${test_name}${NC}\n"
    
    if command -v "$command_name" > /dev/null 2>&1; then
        printf "  ${GREEN}✓ PASSED${NC} - Command available: $command_name\n"
        ((TESTS_PASSED++))
        TEST_RESULTS+=("PASS: $test_name")
    else
        printf "  ${RED}✗ FAILED${NC} - Command not found: $command_name\n"
        ((TESTS_FAILED++))
        TEST_RESULTS+=("FAIL: $test_name")
    fi
}

# Function to skip a test
skip_test() {
    local test_name="$1"
    local reason="$2"
    
    ((TESTS_RUN++))
    ((TESTS_SKIPPED++))
    
    printf "\n${YELLOW}▶ Test ${TESTS_RUN}: ${test_name}${NC}\n"
    printf "  ${YELLOW}⊘ SKIPPED${NC} - Reason: $reason\n"
    TEST_RESULTS+=("SKIP: $test_name - $reason")
}

# Function to assert equality
assert_equal() {
    local actual="$1"
    local expected="$2"
    local message="${3:-Values should be equal}"
    
    if [[ "$actual" == "$expected" ]]; then
        return 0
    else
        printf "  Assertion failed: $message\n"
        printf "  Expected: '$expected'\n"
        printf "  Actual: '$actual'\n"
        return 1
    fi
}

# Function to assert that a value is not empty
assert_not_empty() {
    local value="$1"
    local message="${2:-Value should not be empty}"
    
    if [[ -n "$value" ]]; then
        return 0
    else
        printf "  Assertion failed: $message\n"
        return 1
    fi
}

# Function to print test summary
test_summary() {
    printf "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    printf "${BLUE}Test Summary${NC}\n"
    printf "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    printf "Total Tests: ${TESTS_RUN}\n"
    printf "${GREEN}Passed: ${TESTS_PASSED}${NC}\n"
    printf "${RED}Failed: ${TESTS_FAILED}${NC}\n"
    printf "${YELLOW}Skipped: ${TESTS_SKIPPED}${NC}\n"
    
    if [[ ${TESTS_FAILED} -eq 0 && ${TESTS_PASSED} -gt 0 ]]; then
        printf "\n${GREEN}✓ All tests passed!${NC}\n"
        return 0
    elif [[ ${TESTS_FAILED} -gt 0 ]]; then
        printf "\n${RED}✗ Some tests failed${NC}\n"
        printf "\nFailed tests:\n"
        for result in "${TEST_RESULTS[@]}"; do
            if [[ "$result" == FAIL:* ]]; then
                printf "  ${RED}• ${result#FAIL: }${NC}\n"
            fi
        done
        return 1
    else
        printf "\n${YELLOW}No tests were run${NC}\n"
        return 1
    fi
}

# Setup test environment
setup_test_env() {
    # Create temporary test directory
    TEST_DIR=$(mktemp -d "/tmp/mac-power-tools-test.XXXXXX")
    export TEST_DIR
    printf "${BLUE}Test directory: ${TEST_DIR}${NC}\n"
}

# Cleanup test environment
cleanup_test_env() {
    if [[ -n "$TEST_DIR" ]] && [[ -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
        printf "${BLUE}Cleaned up test directory${NC}\n"
    fi
}

# Mock function for dangerous commands
mock_command() {
    local command="$1"
    local mock_output="${2:-Mock output}"
    
    eval "${command}() { echo '$mock_output'; return 0; }"
}

# Restore mocked command
unmock_command() {
    local command="$1"
    unset -f "$command"
}