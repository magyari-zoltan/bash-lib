#!/bin/bash

# Get current scripts absolute path
CURRENT_SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The "lib" folders relative path
LIB="$CURRENT_SCRIPT_PATH/../lib"


# Import library scripts
source "$LIB/unit_test.sh"

# ------------------------------------------------------------------------------
# cleanup
# ------------------------------------------------------------------------------

function cleanup() {
	cleanup_test_env
}

trap 'cleanup' exit

# ------------------------------------------------------------------------------
# test cases
# ------------------------------------------------------------------------------

DESCRIBE "Merge item with an array of items"

function type_of_items() {
    items=("a" "b" "c")
    items=("${items[@]}" "d")
    declare -p items
}

RUN type_of_items
copy_stdout_to actual

items=("a" "b" "c" "d")
expected="$(declare -p items)"
EXPECT_TO_BE_EQUAL "$expected" "$actual" "The output is expected to be a merged array of items ${expected}"

ENDTEST

# ==============================================================================

DESCRIBE "Passing in arguments as merged array a stack behaviour can be achieved"

function level_three() {
    local stack=("$@")
    echo "Level three: $(declare -p stack)"
}

function level_two() {
    local stack=("$@")
    echo "Level two: $(declare -p stack)"
    level_three "${stack[@]}" "c"
    echo "Level two: $(declare -p stack)"
}

function level_one() {
    local stack=("$@")
    echo
    echo "Level one: $(declare -p stack)"
    level_two "${stack[@]}" "b"
    echo "Level one: $(declare -p stack)"
}

items=()
RUN level_one "${items[@]}" "a"
copy_stdout_to actual

expected="
Level one: declare -a stack=([0]=\"a\")
Level two: declare -a stack=([0]=\"a\" [1]=\"b\")
Level three: declare -a stack=([0]=\"a\" [1]=\"b\" [2]=\"c\")
Level two: declare -a stack=([0]=\"a\" [1]=\"b\")
Level one: declare -a stack=([0]=\"a\")"

EXPECT_TO_BE_EQUAL "$expected" "$actual" "Does not behave like a stack: ${expected}"

ENDTEST

# ==============================================================================
