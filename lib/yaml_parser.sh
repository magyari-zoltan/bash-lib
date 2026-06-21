#!/bin/bash

# ------------------------------------------------------------------------------
# This script is used to parse yaml files and convert them into bash associative 
# array.
# 
# ------------------------------------------------------------------------------

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

            (    
                paths(scalars) as $p |
                [($p | path_to_key), getpath($p) | tostring] | @tsv
            ),
            (
                paths as $p |
                select(getpath($p) | type == "array") |
                [($p | path_to_key) + ".length", (getpath($p) | length | tostring)] | @tsv
            )
        ' "$input_file"
    )
}
