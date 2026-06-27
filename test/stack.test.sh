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

DESCRIBE "The 'stack_push' pushes a value on top of stack."

value1="car"
value2="train"
value3="airplain"

stack=("$value1"); # Global array with initial value
log_variable stack

RUN stack_push stack "$value2"
log_variable stack

RUN stack_push stack "$value3"
log_variable stack

expected=("$value1" "$value2" "$value3")
EXPECT_TO_BE_EQUAL "${expected[*]}" "${stack[*]}" "The stack does not contain these elements: '${expected[*]}'." 

ENDTEST

# ==============================================================================

DESCRIBE "The 'stack_pop' pops the top most value of the stack \
or returns with error '1' if it is empty."

value1="car"
value2="person"
value3="airplane"

stack=("$value1" "$value2" "$value3"); # Global array with initial value
value=""
log_variable stack
log_variable value
RUN stack_pop stack value
log_variable stack
log_variable value
expected=("$value1" "$value2")
EXPECT_TO_BE_EQUAL "${expected[*]}" "${stack[*]}" "The stack does not contain these two elements: '${expected[*]}'." 
expected="$value3"
EXPECT_TO_BE_EQUAL "$expected" "$value" "The poped value is not '$value3'" 

RUN stack_pop stack value
log_variable stack
log_variable value
expected=("$value1")
EXPECT_TO_BE_EQUAL "${expected[*]}" "${stack[*]}" "The stack does not contain this element: '${expected[*]}'." 
expected="$value2"
EXPECT_TO_BE_EQUAL "$expected" "$value" "The poped value is not '$expected'." 

RUN stack_pop stack value
log_variable stack
log_variable value
expected=()
EXPECT_TO_BE_EQUAL "${expected[*]}" "${stack[*]}" "The stack does not contain this element: '${expected[*]}'." 
expected="$value1"
EXPECT_TO_BE_EQUAL "$expected" "$value" "The poped value is not '$expected'." 

RUN stack_pop stack value
ret_val=$?
log_variable ret_val
expected=1
EXPECT_TO_BE_EQUAL "$expected" "$ret_val" "The return value should be '$expected'"

ENDTEST

# ==============================================================================

DESCRIBE "The 'stack_top' command returns the top most element \
or returns with error '1' if it is empty."

value1="car"
value2="train"
value3="airplain"

stack=("$value1" "$value2" "$value3"); # Global array with initial value

RUN stack_top stack value
log_variable stack
log_variable value
expected=("$value1" "$value2" "$value3")
EXPECT_TO_BE_EQUAL "${expected[*]}" "${stack[*]}" "The stack does not contain these elements: '${expected[*]}'." 
expected="$value3"
EXPECT_TO_BE_EQUAL "$expected" "$value" "The returned value should be '$expected'." 

stack=("$value1"); # Global array with initial value
value=""
RUN stack_top stack value
log_variable stack
log_variable value
expected=("$value1")
EXPECT_TO_BE_EQUAL "${expected[*]}" "${stack[*]}" "The stack does not contain these elements: '${expected[*]}'." 
expected="$value1"
EXPECT_TO_BE_EQUAL "$expected" "$value" "The returned value should be '$expected'." 

stack=(); # Global array with initial value
value=""
RUN stack_top stack value
ret_val=$?
log_variable stack
log_variable ret_val
expected=1
EXPECT_TO_BE_EQUAL "$expected" "$ret_val" "The returned value should be '$expected'." 

ENDTEST

# ==============================================================================

DESCRIBE "The 'stack_size' command returns the nr. of items in the stack" 

value1="car"
value2="train"
value3="airplain"

stack=("$value1" "$value2" "$value3"); # Global array with initial value
RUN stack_size stack
log_variable stack
copy_stdout_to size
log_variable size
expected=3
EXPECT_TO_BE_EQUAL "$expected" "$size" "The size should be '$expected'." 

stack=("$value1" "$value2"); # Global array with initial value
RUN stack_size stack size
log_variable stack
copy_stdout_to size
log_variable size
expected=2
EXPECT_TO_BE_EQUAL "$expected" "$size" "The size should be '$expected'." 

stack=("$value1"); # Global array with initial value
RUN stack_size stack size
log_variable stack
copy_stdout_to size
log_variable size
expected=1
EXPECT_TO_BE_EQUAL "$expected" "$size" "The size should be '$expected'." 

stack=(); # Global array with initial value
RUN stack_size stack size
log_variable stack
log_variable size
copy_stdout_to size
expected=1
expected=0
EXPECT_TO_BE_EQUAL "$expected" "$size" "The size should be '$expected'." 

ENDTEST

# ==============================================================================

DESCRIBE "The 'stack_is_empty' command returns '0' for empty stacks and '1' for non-empty stacks."

value1="car"

stack=("$value1"); # Global array with initial value
RUN stack_is_empty stack
ret_val=$?
expected=1
EXPECT_TO_BE_EQUAL "$expected" "$ret_val" "The stack should not be empty when it contains one element."

stack_pop stack value
RUN stack_is_empty stack
ret_val=$?
expected=0
EXPECT_TO_BE_EQUAL "$expected" "$ret_val" "The stack should be empty after removing its only element."

ENDTEST

# ============================================================================== 

