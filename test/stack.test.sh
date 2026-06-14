#!/bin/bash

# Get current scripts absolute path
CURRENT_SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The "lib" folders relative path
LIB="$CURRENT_SCRIPT_PATH/../lib"


# Import library scripts
source "$LIB/unit_test.sh"
source "$LIB/stack.sh"

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

DESCRIBE "The 'push stack \"\$value\"' takes a global array, considers it a stack \
and pushes a value on top of it."

value1="car"
value2="train"
value3="airplain"

stack=("$value1"); # Global array with initial value
log_variable stack

RUN push stack "$value2"
log_variable stack

RUN push stack "$value3"
log_variable stack

expected=("$value1" "$value2" "$value3")
EXPECT_TO_BE_EQUAL "${expected[*]}" "${stack[*]}" "The stack does not contain these elements: '${expected[*]}'." 

ENDTEST

# ==============================================================================

DESCRIBE "The 'pop stack value' pops the top most value of the stack and sets the \
global var passed in as second parameter."

value1="car"
value2="person"
value3="airplane"

stack=("$value1" "$value2" "$value3"); # Global array with initial value
log_variable stack

value=""
log_variable value

RUN pop stack value
log_variable stack
log_variable value

expected=("$value1" "$value2")
EXPECT_TO_BE_EQUAL "${expected[*]}" "${stack[*]}" "The stack does not contain these two elements: '${expected[*]}'." 

expected="$value3"
EXPECT_TO_BE_EQUAL "$expected" "$value" "The poped value is not '$value3'" 

RUN pop stack value
log_variable stack
log_variable value

expected=("$value1")
EXPECT_TO_BE_EQUAL "${expected[*]}" "${stack[*]}" "The stack does not contain this element: '${expected[*]}'." 

expected="$value2"
EXPECT_TO_BE_EQUAL "$expected" "$value" "The poped value is not '$expected'." 

ENDTEST

# ==============================================================================

DESCRIBE "The pop is a safe command, if stack is empty will not pop anything from it."

value1="car"

stack=("$value1"); # Global array with initial value
log_variable stack

value=""
log_variable value

RUN pop stack value
log_variable stack
log_variable value

expected=()
EXPECT_TO_BE_EQUAL "${expected[*]}" "${stack[*]}" "The stack is not empty." 

expected="$value1"
EXPECT_TO_BE_EQUAL "$expected" "$value" "The value is not '$expected'." 

RUN pop stack value
log_variable stack
log_variable value

expected=()
EXPECT_TO_BE_EQUAL "${expected[*]}" "${stack[*]}" "The stack is not empty." 

expected=""
EXPECT_TO_BE_EQUAL "$expected" "$value" "The value is not '$expected'." 

ENDTEST

# ==============================================================================
