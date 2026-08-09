#!/usr/bin/env bash

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
source "$LIB/logger.sh"
source "$LIB/stack.sh"

# ------------------------------------------------------------------------------
# Private helper methods
# ------------------------------------------------------------------------------

function trim() {
    local str="$1"

    debug "Trimming value: '$str'"

    if [[ "$str" =~ ^[[:space:]]*([^[:space:]].*)$ ]]; then
        str="${BASH_REMATCH[1]}"
    fi

    if [[ "$str" =~ ^(.*[^[:space:]])[[:space:]]*$ ]]; then
        str="${BASH_REMATCH[1]}"
    fi

    printf '%s' "$str"
}

function yaml_comment() {
    local line="$1"
    local stackName="$2"
    local mapName="$3"
    local -n keyStackRef="$stackName"
    local -n mapRef="$mapName"

    if [[ "$line" =~ ^(.*)[[:space:]]*#.*$ ]]; then
        local stripped_line="${BASH_REMATCH[1]}"
        debug "Stripping inline comment: original='$line' stripped='$stripped_line' stack='${keyStackRef[*]}'"
        parse_line "$stripped_line" "$stackName" "$mapName"
    elif [[ "$line" =~ ^[[:space:]]*#.*$ ]]; then
        debug "Skipping comment-only line: '$line'"
    fi
}

function key_from_stack() {
    local stackName="$1"
    local -n keyStackRef="$stackName"
    local key=""

    debug "Building key from stack: ${keyStackRef[*]}"
    local length
    length=$(stack_size "$stackName")
    for (( i=0; i<length; i++ )); do
        if [[ $(type_of_value "${keyStackRef[i]}") == "number" ]]; then
            key="${key}[${keyStackRef[i]}]"
        else
            key="${key}.${keyStackRef[i]}"
        fi
    done

    printf '%s' "$key"
}

function top_level() {
    local stackName="$1"
    local mapName="$2"
    local -n keyStackRef="$stackName"
    local -n mapRef="$mapName"
    local key
    key=$(key_from_stack "$stackName")
    local level="${mapRef["${key}:level"]:-0}"

    debug "Resolved top level: key='$key' level='$level'"
    printf '%s' "${level}"
}

# ------------------------------------------------------------------------------
# Private parsing methods
# ------------------------------------------------------------------------------

function value() {
    local line="$1"
    local stackName="$2"
    local mapName="$3"
    local -n keyStackRef="$stackName"
    local -n mapRef="$mapName"

    debug "Parsing scalar value: line='$line'"
    local val=$(trim "$line")
    local key
    key=$(key_from_stack "$stackName")

    local valueType

    valueType=$(type_of_value "$val")
    debug "Writing scalar value: key='$key' value='$val' type='$valueType'"

    mapRef["${key}:type"]="$valueType"
    mapRef["${key}"]="$val"
}

function values() {
    local line="$1"
    local stackName="$2"
    local mapName="$3"
    local -n keyStackRef="$stackName"
    local -n mapRef="$mapName"

    debug "Parsing comma-separated values: line='$line' stack='${keyStackRef[*]}'"
    if [[ "$line" =~ ^([^,]+),(.*)$ ]]; then
        local val="${BASH_REMATCH[1]}"
        local remaining="${BASH_REMATCH[2]}"
        debug "Split values: first='$val' remaining='$remaining'"

        value "$val" "$stackName" "$mapName"
        local level
        level=$(top_level "$stackName" "$mapName")

        stack_pop "$stackName" index
        # local array_key=$(key_from_stack "${!keyStackRef}")
        stack_push "$stackName" $((index + 1))

        # The level of the new value is the same as the previous one, so we need to set it again
        local key
        key=$(key_from_stack "$stackName")
        debug "Advanced array index: key='$key' index='$((index + 1))' level='$level'"
        mapRef["${key}:type"]="index"
        mapRef["${key}:level"]="${level}"

        parse_line "$remaining" "$stackName" "$mapName"
    fi
}

function object() {
    local line="$1"
    local stackName="$2"
    local mapName="$3"
    local -n keyStackRef="$stackName"
    local -n mapRef="$mapName"
    local index=0

    debug "Parsing object: line='$line' stack='${keyStackRef[*]}'"
    if [[ "$line" =~ ^([[:space:]]*)([^:]+):[[:space:]]*$ ]]; then
        local name=$(trim "${BASH_REMATCH[2]}")
        local level="${#BASH_REMATCH[1]}"
        debug "Matched object: name='$name' level='$level' current_top='$(top_level "$stackName" "$mapName")'"

        if [[ $level -lt $(top_level "$stackName" "$mapName") ]]; then
            # Pop the last element if the level is the same
            stack_pop "$stackName" _
            object "$line" "$stackName" "$mapName"
            return 0
        fi

        if [[ "$level" == $(top_level "$stackName" "$mapName") ]]; then
            # Pop the last element if the level is the same
            stack_is_empty "$stackName" || stack_pop "$stackName" _
        fi

        stack_push "$stackName" "$name"
        local key
        key=$(key_from_stack "$stackName")
        debug "Registered object: key='$key' level='$level'"
        mapRef["${key}:type"]="object"
        mapRef["${key}:level"]="${level}"
    fi
}

function property() {
    local line="$1"
    local stackName="$2"
    local mapName="$3"
    local -n keyStackRef="$stackName"
    local -n mapRef="$mapName"

    debug "Parsing property: line='$line' stack='${keyStackRef[*]}'"
    if [[ "$line" =~ ^([[:space:]]*)([^:]+):[[:space:]]*(.+)[[:space:]]*$ ]]; then
        local name="$(trim "${BASH_REMATCH[2]}")"
        local value="$(trim "${BASH_REMATCH[3]}")"
        local level="${#BASH_REMATCH[1]}"
        debug "Matched property: name='$name' value='$value' level='$level' current_top='$(top_level "$stackName" "$mapName")'"

        if [[ $level -lt $(top_level "$stackName" "$mapName") ]]; then
            # Pop the last element if the level is the same
            stack_pop "$stackName" _
            property "$line" "$stackName" "$mapName"
            return 0
        fi

        if [[ "$level" == $(top_level "$stackName" "$mapName") ]]; then
            # Pop the last element if the level is the same
            stack_is_empty "$stackName" || stack_pop "$stackName" _
        fi

        stack_push "$stackName" "${name}"
        debug "Pushed property key: stack='${keyStackRef[*]}'"
        value "$value" "$stackName" "$mapName"
        stack_pop "$stackName" _
    fi
}

function array() {
    local line="$1"
    local stackName="$2"
    local mapName="$3"
    local -n keyStackRef="$stackName"
    local -n mapRef="$mapName"

    debug "Parsing array: line='$line' stack='${keyStackRef[*]}'"
    if [[ "$line" =~ ^([[:space:]]*)([^:]+):[[:space:]]*\[(.*)$ ]]; then
        local name="$(trim "${BASH_REMATCH[2]}")"
        local values="$(trim "${BASH_REMATCH[3]}")"
        local level="${#BASH_REMATCH[1]}"
        local index=0
        debug "Matched array: name='$name' values='$values' level='$level' current_top='$(top_level "$stackName" "$mapName")'"

        if [[ $level -lt $(top_level "$stackName" "$mapName") ]]; then
            # Pop the last element if the level is the same
            stack_pop "$stackName" _
            array "$line" "$stackName" "$mapName"
            return 0
        fi

        if [[ "$level" == $(top_level "$stackName" "$mapName") ]]; then
            # Pop the last element if the level is the same
            stack_is_empty "$stackName" || stack_pop "$stackName" _
        fi

        stack_push "$stackName" "${name}"
        local key
        key=$(key_from_stack "$stackName")
        debug "Registered array container: key='$key' level='$level'"
        mapRef["${key}:type"]="array"
        mapRef["${key}:level"]=${level}

        stack_push "$stackName" 0
        key=$(key_from_stack "$stackName")
        debug "Registered array index: key='$key' level='$level'"
        mapRef["${key}:type"]="index"
        mapRef["${key}:level"]=${level}

        parse_line "$values" "$stackName" "$mapName"
    else
        if [[ "$line" =~ ^(.*)\][[:space:]]*$ ]]; then
            local before_bracket="${BASH_REMATCH[1]}"
            parse_line "$before_bracket" "$stackName" "$mapName"

            # Pop the index from the stack
            stack_pop "$stackName" index
            local key
            key=$(key_from_stack "$stackName")
            local length=$((index + 1))
            mapRef["${key}:length"]=${length}

            # Pop the array from the stack
            stack_pop "$stackName" _
        fi
    fi
}

function array_item() {
    local line="$1"
    local stackName="$2"
    local mapName="$3"
    local -n keyStackRef="$stackName"
    local -n mapRef="$mapName"
    local index=0
    local length=1

    debug "Parsing array item: line='$line' stack='${keyStackRef[*]}'"
    if [[ "$line" =~ ^([[:space:]]*)-([[:space:]]*)([^[:space:]].*)$ ]]; then
        local space_before_hyphen="${BASH_REMATCH[1]}"
        local space_after_hyphen="${BASH_REMATCH[2]}"
        local value="$(trim "${BASH_REMATCH[3]}")"
        local level="${#space_before_hyphen}"
        debug "Matched array item: value='$value' level='$level' current_top='$(top_level "$stackName" "$mapName")'"

        if [[ $level -lt $(top_level "$stackName" "$mapName") ]]; then
            # Pop the last element if the level is the same
            stack_pop "$stackName" _
            array_item "$line" "$stackName" "$mapName"
            return 0
        fi

        if [[ "$level" == $(top_level "$stackName" "$mapName") ]]; then
            # Pop the last element if the level is the same
            stack_is_empty "$stackName" || stack_pop "$stackName" index

            # Calculate the nex index for the next array item
            index=$((index + 1))

            # Increase the length of the arrayj
            local key
            key=$(key_from_stack "$stackName")
            length=$((mapRef["${key}:length"] + 1))
        fi

        local key
        key=$(key_from_stack "$stackName")
        debug "Registered array container: key='$key' length='$length'"
        mapRef["${key}:type"]="array"
        mapRef["${key}:length"]=${length}

        stack_push "$stackName" "${index}"
        key=$(key_from_stack "$stackName")
        debug "Registered array item index: key='$key' level='$level'"
        mapRef["${key}:type"]="index"
        mapRef["${key}:level"]=${level}

        parse_line "${space_before_hyphen} ${space_after_hyphen}$value" "$stackName" "$mapName"
    fi
}

# ------------------------------------------------------------------------------
# Public API
# ------------------------------------------------------------------------------

function parse_line() {
    local line="$1"
    local stackName="$2"
    local mapName="$3"
    local -n keyStackRef="$stackName"
    local -n mapRef="$mapName"

    debug "Parsing line: '$line' stack='${keyStackRef[*]}'"

    # Skip empty lines
    if [[ "$line" =~ ^[[:space:]]*$ ]]; then
        debug "Skipping empty line"
        return 0
    fi

    if [[ "$line" == *"#"* ]]; then
        yaml_comment "$line" "$stackName" "$mapName"
        return 0
    fi

    # If the line contains a hyphen and something else after it
    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*[^[:space:]].*$ ]]; then
        debug "Detected array item: '$line'"
        array_item "$line" "$stackName" "$mapName"
        return 0
    fi

    # If the line contains a colon and only spaces after it is a object
    if [[ "$line" =~ ^[^:]+:[[:space:]]*$ ]]; then
        debug "Detected object: '$line'"
        object "$line" "$stackName" "$mapName"
        return 0
    fi

    # If the line contains a colon and opening brancket
    if [[ "$line" =~ ^[^:]+:[[:space:]]*\[.*$ || "$line" =~ ^[^\]]*\][[:space:]]*$ ]]; then
        debug "Detected array: '$line'"
        array "$line" "$stackName" "$mapName"
        return 0
    fi

    # If the line contains a colon and a value the colon then it is a property
    if [[ "$line" =~ ^[^:]+:[[:space:]]*.+[[:space:]]*$ ]]; then
        debug "Detected property: '$line'"
        property "$line" "$stackName" "$mapName"
        return 0
    fi

    # If the line contains a comma, it indicates multiple values
    if [[ "$line" =~ , ]]; then 
        debug "Detected multiple values: '$line'"
        values "$line" "$stackName" "$mapName"
        return 0
    fi

    debug "Treating as scalar value: '$line'"
    value "$line" "$stackName" "$mapName"
}

# ------------------------------------------------------------------------------
# Public API
# ------------------------------------------------------------------------------

parse_yaml() {
    local yaml_file="$1"
    local -n parseYamlRef="$2"

    info "Parsing YAML file: $yaml_file"

    if [[ ! -r "$yaml_file" ]]; then
        error "unable to read YAML file: $yaml_file"
        return 1
    fi

    # Initialize the stack
    local parseYamlStack=()
    debug "Initialized parse stack"

    # Iterate through each line of the YAML file
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            debug "Processing YAML line"
            # Parse the line and update the associative array
            parse_line "$line" parseYamlStack parseYamlRef
        fi
    done < "$yaml_file"

    info "Finished parsing YAML file: $yaml_file"
}
