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
# Private methods
# ------------------------------------------------------------------------------
function validate_arguments() {
    if [[ $# -eq 0 ]]; then
        echo "Error: Missing input file." >&2
        return 1
    fi

    if [[ $# -gt 2 ]]; then
        echo "Error: Too many arguments." >&2
        return 2
    fi

    if [[ ! -f "$1" ]]; then
        echo "Error: Input file '$1' does not exist." >&2
        return 3
    fi

    if [[ -z ${2+x} ]]; then
        echo "Error: Missing output associative array variable name." >&2
        return 4
    fi

    if ! declare -p "$2" &>/dev/null; then
        echo "Error: The output variable '$2' does not exist." >&2
        return 5
    fi

    if [[ $(declare -p "$2") != declare\ -A* ]]; then
        echo "Error: The output variable '$2' is not an associative array." >&2
        return 5
    fi
}


# ------------------------------------------------------------------------------
# Public API
# ------------------------------------------------------------------------------
function parse_yaml() {
    validate_arguments "$@" || return $?

    local input_file="$1"
    local -n yaml_map="$2"

    while IFS=$'\t' read -r key value; do
        yaml_map["$key"]="$value"
    done < <(
        yq -r '
            def path_to_key:
                reduce .[] as $part ("";
                    if ($part | type) == "number" then
                        . + "[" + ($part | tostring) + "]"
                    else
                        if . == "" then
                            ($part | tostring)
                        else
                            . + "." + ($part | tostring)
                        end
                    end
                );

            paths as $p |
            (
                [($p | path_to_key) + ":type", (getpath($p) | type)] | @tsv
            ),
            (
                if (getpath($p) | type) == "array" then
                    [($p | path_to_key) + ":length", (getpath($p) | length | tostring)] | @tsv
                else
                    empty
                end
            ),
            (
                if ((getpath($p) | type) != "array" and (getpath($p) | type) != "object") then
                    [($p | path_to_key), (getpath($p) | tostring)] | @tsv
                else
                    empty
                end
            )
        ' "$input_file"
    )
}
