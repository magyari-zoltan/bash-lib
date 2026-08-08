#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# Bash type inspection helper.
#
# This file provides helper functions for detecting Bash variable and value
# types such as arrays, maps, numbers, booleans, strings, and namerefs.
# ------------------------------------------------------------------------------

# Prevent multiple sourcing
if [[ -n "${TYPE_LOADED:-}" ]]; then
	# Return instead of exit to avoid terminating the calling script.
	return 0
fi

readonly TYPE_LOADED=true

type() {
    local var_name="$1"

    local declaration
    declaration=$(declare -p "$var_name" 2>/dev/null) || {
        printf 'undefined\n'
        return 1
    }

    case "$declaration" in
        "declare -a "*)
            printf 'array\n'
            return
            ;;
        "declare -A "*)
            printf 'associative map\n'
            return
            ;;
        "declare -n "*)
            printf 'nameref\n'
            return
            ;;
    esac

    local -n ref="$var_name"
    local value="$ref"

    if [[ "$value" =~ ^-?[0-9]+([.][0-9]+)?$ ]]; then
        printf 'number\n'
    elif [[ "$value" == "true" || "$value" == "false" ]]; then
        printf 'boolean\n'
    else
        printf 'string\n'
    fi
}

type_of_value() {
    local value="$1"

    if [[ "$value" =~ ^-?[0-9]+([.][0-9]+)?$ ]]; then
        printf 'number\n'
    elif [[ "$value" == "true" || "$value" == "false" ]]; then
        printf 'boolean\n'
    else
        printf 'string\n'
    fi
}
