#!/bin/bash

# ------------------------------------------------------------------------------
# This script is used to parse yaml files and convert them into bash associative 
# array.
#
# A corresponding entry is created in the associative array for every YAML entry.
# The key used in the associative array expresses the entry’s location within the
# YAML structure using a logical format. This makes references to individual 
# entries within the associative array clear and intuitive.
#
# Additional metadata is also stored in the associative array, such as the 
# length of an array or the type of an entry.
#
# Examples:
#
# disks_map['disks:type'] - The type of the disks entry (array).
# disks_map['disks:length'] - The number of disks in the disks array.
#
# disks_map['disks[0]:type'] - The type of the first disk entry (object). 
# disks_map['disks[0].device'] - /dev/sda
# disks_map['disks[0].device:type'] - The type of the device entry (string).
#
# ------------------------------------------------------------------------------

# Prevent multiple sourcing
if [[ -n "${YAML_PARSER_LOADED:-}" ]]; then
	# Return instead of exit to avoid terminating the calling script.
	return 0 
fi

readonly YAML_PARSER_LOADED=true

# ------------------------------------------------------------------------------
# Import dependencies
# ------------------------------------------------------------------------------

# Get current scripts absolute path
CURRENT_SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The "lib" folders relative path
LIB="$CURRENT_SCRIPT_PATH"

source "$LIB/type.sh"
source "$LIB/stack.sh"

# ------------------------------------------------------------------------------
# Private helper methods
# ------------------------------------------------------------------------------

function trim() {
    local str="$1"

    if [[ "$str" =~ ^[[:space:]]*([^[:space:]].*)$ ]]; then
        str="${BASH_REMATCH[1]}"
    fi

    if [[ "$str" =~ ^(.*[^[:space:]])[[:space:]]*$ ]]; then
        str="${BASH_REMATCH[1]}"
    fi

    printf '%s' "$str"
}

function key_from_stack() {
    local -n keyStackRef="$1"
    local key="${keyStackRef[0]}"

    local length=$(stack_size "${!keyStackRef}")
    for (( i=1; i<length; i++ )); do
        if [[ $(type_of_value "${keyStackRef[i]}") == "number" ]]; then
            key="${key}[${keyStackRef[i]}]"
        else
            key="${key}.${keyStackRef[i]}"
        fi
    done

    printf '%s' "$key"
}

function top_level() {
    local -n keyStackRef="$1"
    local -n mapRef="$2"
    local key=$(key_from_stack "${!keyStackRef}")
    local level="${mapRef["${key}:level"]:-0}"

    printf '%s' "${level}"
}

# ------------------------------------------------------------------------------
# Private parsing methods
# ------------------------------------------------------------------------------

function value() {
    local line="$1"
    local -n keyStackRef="$2"
    local -n mapRef="$3"

    local val=$(trim "$line")
    local key=$(key_from_stack "${!keyStackRef}")

    mapRef["${key}:type"]=$(type_of_value "$val")
    mapRef["${key}"]="$val"
}

function values() {
    local line="$1"
    local -n keyStackRef="$2"
    local -n mapRef="$3"

    if [[ "$line" =~ ^([^,]+),(.*)$ ]]; then
        local val="${BASH_REMATCH[1]}"
        local remaining="${BASH_REMATCH[2]}"

        value "$val" ${!keyStackRef} ${!mapRef}
        local level=$(top_level "${!keyStackRef}" "${!mapRef}")

        stack_pop keyStackRef index
        # local array_key=$(key_from_stack "${!keyStackRef}")
        stack_push keyStackRef $((index + 1))

        # The level of the new value is the same as the previous one, so we need to set it again
        local key=$(key_from_stack "${!keyStackRef}")
        mapRef["${key}:type"]="index"
        mapRef["${key}:level"]="${level}"

        parse_line "$remaining" ${!keyStackRef} ${!mapRef}
    fi
}

function object() {
    local line="$1"
    local -n keyStackRef="$2"
    local -n mapRef="$3"
    local index=0

    if [[ "$line" =~ ^([[:space:]]*)([^:]+):[[:space:]]*$ ]]; then
        local name=$(trim "${BASH_REMATCH[2]}")
        local level="${#BASH_REMATCH[1]}"

        if [[ $level -lt $(top_level "${!keyStackRef}" "${!mapRef}") ]]; then
            # Pop the last element if the level is the same
            stack_pop "${!keyStackRef}" _  
            object "$line" ${!keyStackRef} ${!mapRef}
            return 0
        fi

        if [[ "$level" == $(top_level "${!keyStackRef}" "${!mapRef}") ]]; then
            # Pop the last element if the level is the same
            stack_pop "${!keyStackRef}" _  
        fi

        stack_push keyStackRef "$name"
        local key=$(key_from_stack "${!keyStackRef}")
        mapRef["${key}:type"]="object"
        mapRef["${key}:level"]="${level}"
    fi
}

function property() {
    local line="$1"
    local -n keyStackRef="$2"
    local -n mapRef="$3"

    if [[ "$line" =~ ^([[:space:]]*)([^:]+):[[:space:]]*(.+)[[:space:]]*$ ]]; then
        local name="$(trim "${BASH_REMATCH[2]}")"
        local value="$(trim "${BASH_REMATCH[3]}")"
        local level="${#BASH_REMATCH[1]}"

        if [[ $level -lt $(top_level "${!keyStackRef}" "${!mapRef}") ]]; then
            # Pop the last element if the level is the same
            stack_pop "${!keyStackRef}" _  
            property "$line" ${!keyStackRef} ${!mapRef}
            return 0
        fi

        if [[ "$level" == $(top_level "${!keyStackRef}" "${!mapRef}") ]]; then
            # Pop the last element if the level is the same
            stack_pop "${!keyStackRef}" _  
        fi

        stack_push ${!keyStackRef} "${name}"
        value "$value" ${!keyStackRef} ${!mapRef}
        stack_pop ${!keyStackRef} _
    fi
}

function array() {
    local line="$1"
    local -n keyStackRef="$2"
    local -n mapRef="$3"

    if [[ "$line" =~ ^([[:space:]]*)([^:]+):[[:space:]]*\[(.*)$ ]]; then
        local name="$(trim "${BASH_REMATCH[2]}")"
        local values="$(trim "${BASH_REMATCH[3]}")"
        local level="${#BASH_REMATCH[1]}"
        local index=0

        if [[ $level -lt $(top_level "${!keyStackRef}" "${!mapRef}") ]]; then
            # Pop the last element if the level is the same
            stack_pop "${!keyStackRef}" _  
            array "$line" ${!keyStackRef} ${!mapRef}
            return 0
        fi

        if [[ "$level" == $(top_level "${!keyStackRef}" "${!mapRef}") ]]; then
            # Pop the last element if the level is the same
            stack_pop "${!keyStackRef}" _  
        fi

        stack_push ${!keyStackRef} "${name}"
        local key=$(key_from_stack "${!keyStackRef}")
        mapRef["${key}:type"]="array"
        mapRef["${key}:level"]=${level}

        stack_push ${!keyStackRef} 0
        local key=$(key_from_stack "${!keyStackRef}")
        mapRef["${key}:type"]="index"
        mapRef["${key}:level"]=${level}

        parse_line "$values" ${!keyStackRef} ${!mapRef}
    else
        if [[ "$line" =~ ^(.*)\][[:space:]]*$ ]]; then
            local before_bracket="${BASH_REMATCH[1]}"
            parse_line "$before_bracket" ${!keyStackRef} ${!mapRef}

            # Pop the index from the stack
            stack_pop ${!keyStackRef} index
            local length=$((index + 1))
            mapRef["${key}:length"]=${length}

            # Pop the array from the stack
            stack_pop ${!keyStackRef} _
        fi
    fi
}

function array_item() {
    local line="$1"
    local -n keyStackRef="$2"
    local -n mapRef="$3"
    local index=0
    local length=1

    if [[ "$line" =~ ^([[:space:]]*)-([[:space:]]*)([^[:space:]].*)$ ]]; then
        local space_before_hyphen="${BASH_REMATCH[1]}"
        local space_after_hyphen="${BASH_REMATCH[2]}"
        local value="$(trim "${BASH_REMATCH[3]}")"
        local level="${#space_before_hyphen}"

        if [[ $level -lt $(top_level "${!keyStackRef}" "${!mapRef}") ]]; then
            # Pop the last element if the level is the same
            stack_pop "${!keyStackRef}" _  
            array_item "$line" ${!keyStackRef} ${!mapRef}
            return 0
        fi

        if [[ "$level" == $(top_level "${!keyStackRef}" "${!mapRef}") ]]; then
            # Pop the last element if the level is the same
            stack_pop "${!keyStackRef}" index 

            # Calculate the nex index for the next array item
            index=$((index + 1))

            # Increase the length of the arrayj
            local key=$(key_from_stack "${!keyStackRef}")
            length=$((mapRef["${key}:length"] + 1))
        fi

        local key=$(key_from_stack "${!keyStackRef}")
        mapRef["${key}:type"]="array"
        mapRef["${key}:length"]=${length}

        stack_push ${!keyStackRef} ${index}
        local key=$(key_from_stack "${!keyStackRef}")
        mapRef["${key}:type"]="index"
        mapRef["${key}:level"]=${level}

        parse_line "${space_before_hyphen} ${space_after_hyphen}$value" ${!keyStackRef} ${!mapRef}
    fi
}

# ------------------------------------------------------------------------------
# Public API
# ------------------------------------------------------------------------------

function parse_line() {
    local line="$1"
    local -n keyStackRef="$2"
    local -n mapRef="$3"

    # Skip empty lines
    if [[ "$line" =~ ^[[:space:]]*$ ]]; then
        return 0
    fi

    # If the line contains a hyphen and something else after it
    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*[^[:space:]].*$ ]]; then
        array_item "$line" ${!keyStackRef} ${!mapRef}
        return 0
    fi

    # If the line contains a colon and only spaces after it is a object
    if [[ "$line" =~ ^[^:]+:[[:space:]]*$ ]]; then
        object "$line" ${!keyStackRef} ${!mapRef}
        return 0
    fi

    # If the line contains a colon and opening brancket
    if [[ "$line" =~ ^[^:]+:[[:space:]]*\[.*$ || "$line" =~ ^[^\]]*\][[:space:]]*$ ]]; then
        array "$line" ${!keyStackRef} ${!mapRef}
        return 0
    fi

    # If the line contains a colon and a value the colon then it is a property
    if [[ "$line" =~ ^[^:]+:[[:space:]]*.+[[:space:]]*$ ]]; then
        property "$line" ${!keyStackRef} ${!mapRef}
        return 0
    fi

    # If the line contains a comma, it indicates multiple values
    if [[ "$line" =~ , ]]; then 
        values "$line" ${!keyStackRef} ${!mapRef}
        return 0
    fi
    value "$line" ${!keyStackRef} ${!mapRef}
}

# ------------------------------------------------------------------------------
# Public API
# ------------------------------------------------------------------------------

parse_yaml() {
    local yaml_file="$1"
    local -n parseYamlRef="$2"

    # Initialize the stack
    local parseYamlStack=()

    # Iterate through each line of the YAML file
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            # Parse the line and update the associative array
            parse_line "$line" parseYamlStack parseYamlRef
        fi
    done < "$yaml_file"
}
