#!/bin/bash

# ------------------------------------------------------------------------------
# The implementation of the stack data structure.
#
# Provides simple Bash array based stack operations. The push function appends a
# value to the top of the referenced stack, while pop removes the top value and
# writes it into the referenced output variable.
#
# ------------------------------------------------------------------------------

# Adds a new element to the top of the stack
function push() {
    local -n stackRef="$1"                      # Creates a name reference to the stack passed as the first parameter
    stackRef+=("$2")                            # Inserts the value of the second parameter onto the stack
}

# Removes an element from the top of the stack
function pop() {
    local -n stackRef="$1"                      # Creates a name reference to the stack passed as the first parameter
    local -n valueRef="$2"                      # Creates a name reference to the second parameter 

    local length=${#stackRef[@]}                # Get the length of the array
    if [[ $length -le 0 ]] then                 # Element can not be poped from an empty stack
        valueRef=""                             # Set the poped value to empty string
        return 0
    fi 
    local lastIndex=$((length - 1))             # Calculate the index of the last element

    valueRef="${stackRef[$lastIndex]}"          # Get the last element value
    unset "stackRef[$lastIndex]"                # Remove the last element
}
