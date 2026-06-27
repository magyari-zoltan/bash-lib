#!/bin/bash

# Get current scripts absolute path
CURRENT_SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The "lib" folders relative path
LIB="$CURRENT_SCRIPT_PATH/../lib"


# Import library scripts
source "$LIB/unit_test.sh"
source "$LIB/type.sh"

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

# ==============================================================================
# type
# ==============================================================================

DESCRIBE "The 'type' command returns 'array' for indexed arrays."

declare -a items=("car" "train")

RUN type items
ret_val=$?
log_variable items
copy_stdout_to output

EXPECT_TO_BE_EQUAL "0" "$ret_val" "The return value should be '0'."

expected="array"
EXPECT_TO_BE_EQUAL "$expected" "$output" "The type of 'items' should be '$expected'."

ENDTEST

# ==============================================================================

DESCRIBE "The 'type' command returns 'associative map' for associative arrays."

declare -A map=([car]="vehicle")

RUN type map
ret_val=$?
log_variable map
copy_stdout_to output

EXPECT_TO_BE_EQUAL "0" "$ret_val" "The return value should be '0'."

expected="associative map"
EXPECT_TO_BE_EQUAL "$expected" "$output" "The type of 'map' should be '$expected'."

ENDTEST

# ==============================================================================

DESCRIBE "The 'type' command returns 'nameref' for name references."

value="train"
declare -n ref=value

RUN type ref
ret_val=$?
log_variable ref
copy_stdout_to output

EXPECT_TO_BE_EQUAL "0" "$ret_val" "The return value should be '0'."

expected="nameref"
EXPECT_TO_BE_EQUAL "$expected" "$output" "The type of 'ref' should be '$expected'."

ENDTEST

# ==============================================================================

DESCRIBE "The 'type' command returns 'number' for numeric scalar values."

value="42"

RUN type value
ret_val=$?
log_variable value
copy_stdout_to output

EXPECT_TO_BE_EQUAL "0" "$ret_val" "The return value should be '0'."

expected="number"
EXPECT_TO_BE_EQUAL "$expected" "$output" "The type of 'value' should be '$expected'."

ENDTEST

# ==============================================================================

DESCRIBE "The 'type' command returns 'boolean' for boolean scalar values."

value="true"

RUN type value
ret_val=$?
log_variable value
copy_stdout_to output

EXPECT_TO_BE_EQUAL "0" "$ret_val" "The return value should be '0'."

expected="boolean"
EXPECT_TO_BE_EQUAL "$expected" "$output" "The type of 'value' should be '$expected'."

value="false"

RUN type value
ret_val=$?
log_variable value
copy_stdout_to output

EXPECT_TO_BE_EQUAL "0" "$ret_val" "The return value should be '0'."

expected="boolean"
EXPECT_TO_BE_EQUAL "$expected" "$output" "The type of 'value' should be '$expected'."

ENDTEST

# ==============================================================================

DESCRIBE "The 'type' command returns 'string' for other scalar values."

value="car"

RUN type value
ret_val=$?

log_variable value
copy_stdout_to output

EXPECT_TO_BE_EQUAL "0" "$ret_val" "The return value should be '0'."

expected="string"
EXPECT_TO_BE_EQUAL "$expected" "$output" "The type of 'value' should be '$expected'."

ENDTEST

# ==============================================================================

DESCRIBE "The 'type' command returns 'undefined' and exits with 1 for unknown variables."

unset missing_value 2>/dev/null

RUN type missing_value
ret_val=$?
copy_stdout_to output

EXPECT_TO_BE_EQUAL "1" "$ret_val" "The return value should be '1'."

expected="undefined"
EXPECT_TO_BE_EQUAL "$expected" "$output" "The type of 'missing_value' should be '$expected'."

ENDTEST


# ==============================================================================
# type_of_value
# ==============================================================================

DESCRIBE "The 'type_of_value' command returns 'number' for numeric values."

value="42"

RUN type_of_value "$value"
ret_val=$?
copy_stdout_to output

EXPECT_TO_BE_EQUAL "0" "$ret_val" "The return value should be '0'."
EXPECT_TO_BE_EQUAL "number" "$output" "The type of '$value' should be 'number'."

ENDTEST

# ==============================================================================

DESCRIBE "The 'type_of_value' command returns 'boolean' for boolean values."

value="true"

RUN type_of_value "$value"
ret_val=$?
copy_stdout_to output

EXPECT_TO_BE_EQUAL "0" "$ret_val" "The return value should be '0'."
EXPECT_TO_BE_EQUAL "boolean" "$output" "The type of '$value' should be 'boolean'."

value="false"

RUN type_of_value "$value"
ret_val=$?
copy_stdout_to output

EXPECT_TO_BE_EQUAL "0" "$ret_val" "The return value should be '0'."
EXPECT_TO_BE_EQUAL "boolean" "$output" "The type of '$value' should be 'boolean'."

ENDTEST

# ==============================================================================

DESCRIBE "The 'type_of_value' command returns 'string' for non-numeric non-boolean values."

value="car"

RUN type_of_value "$value"
ret_val=$?
copy_stdout_to output

EXPECT_TO_BE_EQUAL "0" "$ret_val" "The return value should be '0'."
EXPECT_TO_BE_EQUAL "string" "$output" "The type of '$value' should be 'string'."

ENDTEST

# ==============================================================================

