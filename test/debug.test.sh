#!/bin/bash

# Get current scripts absolute path
CURRENT_SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The "lib" folders relative path
LIB="$CURRENT_SCRIPT_PATH/../lib"


# Import library scripts
source "$LIB/unit_test.sh"
source "$LIB/debug.sh"

# ------------------------------------------------------------------------------
# Cleanup
# ------------------------------------------------------------------------------

function cleanup() {
	cleanup_test_env
}

trap 'cleanup' EXIT

# ------------------------------------------------------------------------------
# Test cases
# ------------------------------------------------------------------------------

DESCRIBE "Turning debug on will print the commands on the error output"

function turn_debug_on_and_off() {
	debug_on
	echo "Hello World!"
	debug_off
	echo "Whats up!"

}

RUN turn_debug_on_and_off

expected="Hello World!
Whats up!"
copy_stdout_to output

EXPECT_TO_BE_EQUAL "$expected" "$output" "On the standart output is expected to be '$expected'." 

ENDTEST

# ==============================================================================

DESCRIBE "Disable debug entierly"

function disable_debug_entierly() {
	DEBUG=0
	debug_on
	echo "Debug is globally disabled"
	debug_off
	DEBUG=1
}

RUN disable_debug_entierly

expected="Debug is globally disabled"
copy_stdout_to output

EXPECT_TO_BE_EQUAL "$expected" "$output" "On the standart output is expected to be '$expected'."

ENDTEST

# ==============================================================================
