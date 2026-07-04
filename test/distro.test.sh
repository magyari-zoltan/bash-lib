#!/bin/bash

# Get current scripts absolute path
CURRENT_SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The "lib" folders relative path
LIB="$CURRENT_SCRIPT_PATH/../lib"


# Import library scripts
source "$LIB/unit_test.sh"

# ------------------------------------------------------------------------------
# Cleanup
# ------------------------------------------------------------------------------

function cleanup() {
	local exit_code=$?
	cleanup_test_env

	if [[ "$UNIT_TEST_FAILED_TESTS" -gt 0 ]]; then
		exit 1
	fi

	exit "$exit_code"
}


trap 'cleanup' EXIT

# ------------------------------------------------------------------------------
# Test cases
# ------------------------------------------------------------------------------

DESCRIBE "The execution environment reports the expected Linux distribution."

expected_distro_id="${EXPECTED_DISTRO_ID:-}"

if [[ -z "$expected_distro_id" ]]; then
	FAIL "EXPECTED_DISTRO_ID is not set."
	ENDTEST
fi

if [[ ! -r /etc/os-release ]]; then
	FAIL "/etc/os-release is not readable."
	ENDTEST
fi

# shellcheck disable=SC1091
source /etc/os-release

expected="$expected_distro_id"
actual="${ID:-unknown}"
EXPECT_TO_BE_EQUAL "$expected" "$actual" "The test environment should be running on '$expected' (detected: '$actual')."

ENDTEST

# ============================================================================== 
