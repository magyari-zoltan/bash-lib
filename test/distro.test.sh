#!/bin/bash

# Get current scripts absolute path
CURRENT_SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The "lib" folders relative path
LIB="$CURRENT_SCRIPT_PATH/../lib"


# Import library scripts
source "$LIB/unit_test.sh"
source "$LIB/distro.sh"

# ------------------------------------------------------------------------------
# Cleanup
# ------------------------------------------------------------------------------

TMP_DIR="$(mktemp -d)"

function cleanup() {
	local exit_code=$?
	rm -rf "$TMP_DIR"
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

RUN distro
ret_val=$?
copy_stdout_to output
copy_stderr_to stderr_output

expected="$expected_distro_id"
EXPECT_TO_BE_EQUAL "0" "$ret_val" "The distro helper should succeed for the current environment."
EXPECT_TO_BE_EQUAL "$expected" "$output" "The test environment should be running on '$expected'."
EXPECT_TO_BE_EQUAL "" "$stderr_output" "The distro helper should not print errors for the current environment."

ENDTEST

function write_os_release_file() {
	local file="$1"
	local distro_id="$2"
	local name="${3:-TestOS}"

	cat > "$file" <<EOF
NAME="$name"
ID=$distro_id
EOF
}

DESCRIBE "The distro command accepts a custom os-release file."

custom_os_release="$TMP_DIR/custom-os-release"
write_os_release_file "$custom_os_release" "custom-linux"

RUN distro "$custom_os_release"
ret_val=$?
copy_stdout_to output
copy_stderr_to stderr_output

EXPECT_TO_BE_EQUAL "0" "$ret_val" "The return value should be '0' for a readable custom file."
EXPECT_TO_BE_EQUAL "custom-linux" "$output" "The distro should be read from the provided file."
EXPECT_TO_BE_EQUAL "" "$stderr_output" "No error output is expected for a readable custom file."

ENDTEST

# ==============================================================================

DESCRIBE "The distro command returns 1 when the os-release file is missing."

missing_os_release="$TMP_DIR/missing-os-release"

RUN distro "$missing_os_release"
ret_val=$?
copy_stdout_to output
copy_stderr_to stderr_output

EXPECT_TO_BE_EQUAL "1" "$ret_val" "The return value should be '1' for a missing os-release file."
EXPECT_TO_BE_EQUAL "" "$output" "No stdout output is expected for a missing os-release file."
EXPECT_TO_BE_EQUAL "ERROR: unable to read os-release file: $missing_os_release" "$stderr_output" "The error message should mention the missing file."

ENDTEST

# ==============================================================================

DESCRIBE "The distro command returns 1 when the file has no ID entry."

no_id_os_release="$TMP_DIR/no-id-os-release"
cat > "$no_id_os_release" <<EOF
NAME=TestOS
VERSION=1
EOF

RUN distro "$no_id_os_release"
ret_val=$?
copy_stdout_to output
copy_stderr_to stderr_output

EXPECT_TO_BE_EQUAL "1" "$ret_val" "The return value should be '1' when the file has no ID entry."
EXPECT_TO_BE_EQUAL "" "$output" "No stdout output is expected when the ID entry is missing."
EXPECT_TO_BE_EQUAL "ERROR: distro ID not found in $no_id_os_release" "$stderr_output" "The error message should explain the missing ID."

ENDTEST

# ==============================================================================
