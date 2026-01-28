#!/bin/bash
###############################################################
# Test Suite: user_manager.sh
# Description: Comprehensive test suite for user management script
# Author: Samiul alam Sumel
# Version: 1.0.0
###############################################################

# Test configuration
readonly TEST_SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
readonly MAIN_SCRIPT="$TEST_SCRIPT_DIR/../user_manager.sh"
readonly TEST_USER_PREFIX="testuser_$$"
readonly TEST_LOG_FILE="/tmp/user_manager_test_$$.log"

# Test counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

# Cleanup function
cleanup() {
	echo -e "${YELLOW}Cleaning up test users...${NC}"
	for user in $(grep "^$TEST_USER_PREFIX" /etc/passwd | cut -d: -f1); do
		userdel -r "$user" 2>/dev/null || true
	done
	rm -f "$TEST_LOG_FILE"
}

# Setup trap for cleanup
trap cleanup EXIT INT TERM

# Test utility functions
log_test() {
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] TEST: $1" | tee -a "$TEST_LOG_FILE"
}

log_pass() {
	echo -e "${GREEN}PASS: $1${NC}"
	((TESTS_PASSED++))
}

log_fail() {
	echo -e "${RED}FAIL: $1${NC}"
	((TESTS_FAILED++))
}

run_test() {
	local test_name="$1"
	local test_command="$2"
	local expected_exit_code="${3:-0}"

	((TESTS_TOTAL++))
	log_test "Running: $test_name"

	if eval "$test_command" >>"$TEST_LOG_FILE" 2>&1; then
		local actual_exit_code=$?
		if [[ $actual_exit_code -eq $expected_exit_code ]]; then
			log_pass "$test_name"
		else
			log_fail "$test_name (exit code: $actual_exit_code, expected: $expected_exit_code)"
		fi
	else
		local actual_exit_code=$?
		if [[ $actual_exit_code -eq $expected_exit_code ]]; then
			log_pass "$test_name"
		else
			log_fail "$test_name (exit code: $actual_exit_code, expected: $expected_exit_code)"
		fi
	fi
}

# Pre-flight checks
test_script_exists() {
	run_test "Script exists" "[[ -f '$MAIN_SCRIPT' ]]"
}

test_script_executable() {
	run_test "Script executable" "[[ -x '$MAIN_SCRIPT' ]]"
}

test_config_exists() {
	run_test "Config file exists" "[[ -f '$TEST_SCRIPT_DIR/../config/script.conf' ]]"
}

test_shebang_valid() {
	run_test "Valid shebang" "head -1 '$MAIN_SCRIPT' | grep -q '^#!/bin/bash'"
}

# Configuration tests
test_config_loading() {
	run_test "Config loading" "bash -c 'source \"$TEST_SCRIPT_DIR/../config/script.conf\" && echo \$LOG_DIR'"
}

# Function tests
test_validate_username() {
	local test_username="${TEST_USER_PREFIX}valid"
	run_test "Valid username" "echo '$test_username' | grep -q '^[a-z][a-z0-9_-]*$'"
}

test_validate_username_invalid() {
	run_test "Invalid username (uppercase)" "echo 'InvalidUser' | grep -vq '^[a-z][a-z0-9_-]*$'"
}

test_validate_username_empty() {
	run_test "Invalid username (empty)" "[[ -z '' ]]"
}

# User creation tests
test_user_creation() {
	local test_username="${TEST_USER_PREFIX}create"
	run_test "Create user" "sudo '$MAIN_SCRIPT' create '$test_username' 'TestPass123!'"
}

test_user_creation_exists() {
	local test_username="${TEST_USER_PREFIX}exists"
	sudo "$MAIN_SCRIPT" create "$test_username" "TestPass123!" >/dev/null 2>&1
	run_test "Create existing user (should fail)" "sudo '$MAIN_SCRIPT' create '$test_username' 'TestPass123!'" 4
}

test_user_creation_invalid_username() {
	run_test "Create user with invalid username" "sudo '$MAIN_SCRIPT' create 'InvalidUser' 'TestPass123!'" 3
}

# User modification tests
test_user_modify_shell() {
	local test_username="${TEST_USER_PREFIX}modify"
	sudo "$MAIN_SCRIPT" create "$test_username" "TestPass123!" >/dev/null 2>&1
	run_test "Modify user shell" "sudo '$MAIN_SCRIPT' modify '$test_username' shell /bin/zsh"
}

test_user_modify_lock() {
	local test_username="${TEST_USER_PREFIX}lock"
	sudo "$MAIN_SCRIPT" create "$test_username" "TestPass123!" >/dev/null 2>&1
	run_test "Lock user" "sudo '$MAIN_SCRIPT' modify '$test_username' lock"
}

test_user_modify_unlock() {
	local test_username="${TEST_USER_PREFIX}unlock"
	sudo "$MAIN_SCRIPT" create "$test_username" "TestPass123!" >/dev/null 2>&1
	sudo "$MAIN_SCRIPT" modify "$test_username" lock >/dev/null 2>&1
	run_test "Unlock user" "sudo '$MAIN_SCRIPT' modify '$test_username' unlock"
}

# User deletion tests
test_user_delete() {
	local test_username="${TEST_USER_PREFIX}delete"
	sudo "$MAIN_SCRIPT" create "$test_username" "TestPass123!" >/dev/null 2>&1
	run_test "Delete user" "sudo '$MAIN_SCRIPT' delete '$test_username'"
}

test_user_delete_nonexistent() {
	local test_username="${TEST_USER_PREFIX}nonexistent"
	run_test "Delete non-existent user (should fail)" "sudo '$MAIN_SCRIPT' delete '$test_username'" 5
}

# System user protection test
test_system_user_protection() {
	run_test "System user deletion protection" "sudo '$MAIN_SCRIPT' delete 'root'" 2
}

# List users test
test_list_users() {
	run_test "List users" "sudo '$MAIN_SCRIPT' list regular"
}

# Backup tests
test_backup_creation() {
	run_test "Backup directory creation" "sudo '$MAIN_SCRIPT' create '${TEST_USER_PREFIX}backup' 'TestPass123!' && [[ -d '/tmp/user_manager_backups' ]]"
}

# Permission tests
test_root_required() {
	run_test "Root requirement" "su -s /bin/bash -c '$MAIN_SCRIPT list' 2>/dev/null" 2
}

# Help and usage tests
test_help_display() {
	run_test "Help display" "sudo '$MAIN_SCRIPT' help"
}

test_version_display() {
	run_test "Version display" "sudo '$MAIN_SCRIPT' --version"
}

# Main test execution
main() {
	echo -e "${YELLOW}Starting User Management Script Test Suite${NC}"
	echo "Log file: $TEST_LOG_FILE"
	echo "=================================================="

	# Pre-flight checks
	test_script_exists
	test_script_executable
	test_config_exists
	test_shebang_valid

	# Configuration tests
	test_config_loading

	# Function tests
	test_validate_username
	test_validate_username_invalid
	test_validate_username_empty

	# User management tests
	test_user_creation
	test_user_creation_exists
	test_user_creation_invalid_username
	test_user_modify_shell
	test_user_modify_lock
	test_user_modify_unlock
	test_user_delete
	test_user_delete_nonexistent
	test_system_user_protection

	# Feature tests
	test_list_users
	test_backup_creation
	test_root_required
	test_help_display
	test_version_display

	# Results summary
	echo "=================================================="
	echo -e "${YELLOW}Test Results Summary:${NC}"
	echo "Total tests: $TESTS_TOTAL"
	echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
	echo -e "Failed: ${RED}$TESTS_FAILED${NC}"

	if [[ $TESTS_FAILED -eq 0 ]]; then
		echo -e "${GREEN}All tests passed!${NC}"
		exit 0
	else
		echo -e "${RED}Some tests failed. Check log file: $TEST_LOG_FILE${NC}"
		exit 1
	fi
}

# Run main function
main "$@"
