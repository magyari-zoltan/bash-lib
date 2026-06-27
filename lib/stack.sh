#!/bin/bash

# ------------------------------------------------------------------------------
# The implementation of the stack data structure.
#
# Provides simple Bash array based stack operations. The push function appends a
# value to the top of the referenced stack, while pop removes the top value and
# writes it into the referenced output variable.
#
# ------------------------------------------------------------------------------

# Prevent multiple sourcing
if [[ -n "${STACK_LOADED:-}" ]]; then
	# Return instead of exit to avoid terminating the calling script.
	return 0 
fi

readonly STACK_LOADED=true

# ------------------------------------------------------------------------------
# Public API
# ------------------------------------------------------------------------------

# Returns the size of the stack
function stack_size() {
    local -n stackRef="$1"                      # Creates a name reference to the stack passed as the first parameter
    echo "${#stackRef[@]}"                      # Get the size of the array
}

# Returns true if the stack is empty,
# false otherwise 
function stack_is_empty() {
    [[ $(stack_size "$1") -eq 0 ]] && return 0 || return 1
}

# Adds a new element to the top of the stack
function stack_push() {
    local -n stackRef="$1"                      # Creates a name reference to the stack passed as the first parameter
    stackRef+=("$2")                            # Inserts the value of the second parameter onto the stack
}

# Removes an element from the top of the stack
function stack_pop() {
    local -n stackRef="$1"                      # Creates a name reference to the stack passed as the first parameter
    local -n valueRef="$2"                      # Creates a name reference to the second parameter 

    if stack_is_empty "$1"; then                # Element can not be poped from an empty stack
        return 1                                # Returns 1
    fi 
    local size=$(stack_size "$1")               # Get the length of the array
    local lastIndex=$((size - 1))               # Calculate the index of the last element

    valueRef="${stackRef[$lastIndex]}"          # Get the last element value
    unset "stackRef[$lastIndex]"                # Remove the last element
}

# Returns the top most element
function stack_top() {
    local -n stackRef="$1"                      # Creates a name reference to the stack passed as the first parameter
    local -n valueRef="$2"                      # Creates a name reference to the second parameter 
    
    if stack_is_empty "$1"; then                # Element can not be poped from an empty stack
        return 1                                # Returns 1
    fi 

    local size=$(stack_size "$1")               # Get the length of the array
    local lastIndex=$((size - 1))               # Calculate the index of the last element

    valueRef="${stackRef[$lastIndex]}"          # Get the last element value
}

