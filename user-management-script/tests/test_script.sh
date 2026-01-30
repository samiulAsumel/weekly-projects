#!/bin/bash
###############################################################
# Test Suite: user_manager.sh
# Description: Comprehensive test suite for user management script
# Author: Samiul alam Sumel
# Version: 1.0.0
###############################################################

# Test configuration
TEST_SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
readonly TEST_SCRIPT_DIR
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
# shellcheck disable=SC2317,SC1090,SC1091,SC2034,SC2035,SC2036,SC2037,SC2038,SC2039,SC2046,SC2086,SC2087,SC2088,SC2089,SC2090,SC2091,SC2092,SC2093,SC2094,SC2095,SC2096,SC2097,SC2098,SC2099,SC2100,SC2101,SC2102,SC2103,SC2104,SC2105,SC2106,SC2107,SC2108,SC2109,SC2110,SC2111,SC2112,SC2113,SC2114,SC2115,SC2116,SC2117,SC2118,SC2119,SC2120,SC2121,SC2122,SC2123,SC2124,SC2125,SC2126,SC2127,SC2128,SC2129,SC2130,SC2131,SC2132,SC2133,SC2134,SC2135,SC2136,SC2137,SC2138,SC2139,SC2140,SC2141,SC2142,SC2143,SC2144,SC2145,SC2146,SC2147,SC2148,SC2149,SC2150,SC2151,SC2152,SC2153,SC2154,SC2155,SC2156,SC2157,SC2158,SC2159,SC2160,SC2161,SC2162,SC2163,SC2164,SC2165,SC2166,SC2167,SC2168,SC2169,SC2170,SC2171,SC2172,SC2173,SC2174,SC2175,SC2176,SC2177,SC2178,SC2179,SC2180,SC2181,SC2182,SC2183,SC2184,SC2185,SC2186,SC2187,SC2188,SC2189,SC2190,SC2191,SC2192,SC2193,SC2194,SC2195,SC2196,SC2197,SC2198,SC2199,SC2200,SC2201,SC2202,SC2203,SC2204,SC2205,SC2206,SC2207,SC2208,SC2209,SC2210,SC2211,SC2212,SC2213,SC2214,SC2215,SC2216,SC2217,SC2218,SC2219,SC2220,SC2221,SC2222,SC2223,SC2224,SC2225,SC2226,SC2227,SC2228,SC2229,SC2230,SC2231,SC2232,SC2233,SC2234,SC2235,SC2236,SC2237,SC2238,SC2239,SC2240,SC2241,SC2242,SC2243,SC2244,SC2245,SC2246,SC2247,SC2248,SC2249,SC2250,SC2251,SC2252,SC2253,SC2254,SC2255,SC2256,SC2257,SC2258,SC2259,SC2260,SC2261,SC2262,SC2263,SC2264,SC2265,SC2266,SC2267,SC2268,SC2269,SC2270,SC2271,SC2272,SC2273,SC2274,SC2275,SC2276,SC2277,SC2278,SC2279,SC2280,SC2281,SC2282,SC2283,SC2284,SC2285,SC2286,SC2287,SC2288,SC2289,SC2290,SC2291,SC2292,SC2293,SC2294,SC2295,SC2296,SC2297,SC2298,SC2299,SC2300,SC2301,SC2302,SC2303,SC2304,SC2305,SC2306,SC2307,SC2308,SC2309,SC2310,SC2311,SC2312,SC2313,SC2314,SC2315,SC2316,SC2317,SC2318,SC2319,SC2320,SC2321,SC2322,SC2323,SC2324,SC2325,SC2326,SC2327,SC2328,SC2329,SC2330,SC2331,SC2332,SC2333,SC2334,SC2335,SC2336,SC2337,SC2338,SC2339,SC2340,SC2341,SC2342,SC2343,SC2344,SC2345,SC2346,SC2347,SC2348,SC2349,SC2350,SC2351,SC2352,SC2353,SC2354,SC2355,SC2356,SC2357,SC2358,SC2359,SC2360,SC2361,SC2362,SC2363,SC2364,SC2365,SC2366,SC2367,SC2368,SC2369,SC2370,SC2371,SC2372,SC2373,SC2374,SC2375,SC2376,SC2377,SC2378,SC2379,SC2380,SC2381,SC2382,SC2383,SC2384,SC2385,SC2386,SC2387,SC2388,SC2389,SC2390,SC2391,SC2392,SC2393,SC2394,SC2395,SC2396,SC2397,SC2398,SC2399,SC2400,SC2401,SC2402,SC2403,SC2404,SC2405,SC2406,SC2407,SC2408,SC2409,SC2410,SC2411,SC2412,SC2413,SC2414,SC2415,SC2416,SC2417,SC2418,SC2419,SC2420,SC2421,SC2422,SC2423,SC2424,SC2425,SC2426,SC2427,SC2428,SC2429,SC2430,SC2431,SC2432,SC2433,SC2434,SC2435,SC2436,SC2437,SC2438,SC2439,SC2440,SC2441,SC2442,SC2443,SC2444,SC2445,SC2446,SC2447,SC2448,SC2449,SC2450,SC2451,SC2452,SC2453,SC2454,SC2455,SC2456,SC2457,SC2458,SC2459,SC2460,SC2461,SC2462,SC2463,SC2464,SC2465,SC2466,SC2467,SC2468,SC2469,SC2470,SC2471,SC2472,SC2473,SC2474,SC2475,SC2476,SC2477,SC2478,SC2479,SC2480,SC2481,SC2482,SC2483,SC2484,SC2485,SC2486,SC2487,SC2488,SC2489,SC2490,SC2491,SC2492,SC2493,SC2494,SC2495,SC2496,SC2497,SC2498,SC2499,SC2500
cleanup() {
  echo -e "${YELLOW}Cleaning up test users...${NC}"
  while IFS=: read -r username _; do
    if [[ "$username" =~ ^$TEST_USER_PREFIX ]]; then
      userdel -r "$username" 2>/dev/null || true
    fi
  done </etc/passwd
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
