#!/bin/bash

# ------------------------------------------------------------------------------
# Library
#
# Shared Bash error handling helpers for enabling strict mode and printing
# contextual diagnostics with a stack trace when a command fails.
# ------------------------------------------------------------------------------

# Prevent multiple sourcing
if [[ -n "${ERROR_HANDLER_LOADED:-}" ]]; then
	# Return instead of exit to avoid terminating the calling script.
	return 0 
fi

readonly ERROR_HANDLER_LOADED=true

# ------------------------------------------------------------------------------
# Internal API: Functions intended for use within this library
# ------------------------------------------------------------------------------

# Logger method to print the error
function error_handler_log() {
	echo "$@" >&2
}

# Prints detailed error diagnostics for the failed command, including exit code,
# source location, calling function, and a stack trace collected from Bash
# internals.
function error_handler() {
	exit_code=$1
	bash_command="$2"
	line_no=$3
	file="${BASH_SOURCE[1]}"
	function_name="${FUNCNAME[1]}"
	
	error_handler_log 
	error_handler_log 'ERROR:'
	error_handler_log '  Exit code: '"$exit_code"
	error_handler_log '  Command: '"$bash_command"
	error_handler_log '  Line: '"$line_no"
	error_handler_log '  File: '"$file"
	error_handler_log '  Function: '"$function_name"
	
	error_handler_log
	error_handler_log 'STACK TRACE:'
	for i in "${!FUNCNAME[@]}"; do
		if [ $i -eq 0 ]; then
			error_handler_log "  ${FUNCNAME[$i]} ${BASH_SOURCE[$i]}"
		else
			prev=(i-1)
			error_handler_log "  ${FUNCNAME[$i]} ${BASH_SOURCE[$i]}:${BASH_LINENO[$prev]}"
		fi
	done
}

# ------------------------------------------------------------------------------
# Public API: Functions intended for external use
# ------------------------------------------------------------------------------

# Enables strict Bash error handling and registers the ERR trap so failed
# commands are reported through error_handler with diagnostic context.
function enable_error_handler() {
	# Registers the ERR trap so error_handler runs when a command fails.
	trap 'error_handler $? "$BASH_COMMAND" $LINENO' ERR

	# Enables strict Bash error handling modes.
	set -Eeuo pipefail
}

# Disables the custom ERR trap and turns off strict Bash error handling so
# subsequent commands run without automatic error interception.
function disable_error_handler() {
	# Disables strict Bash error handling modes.
	set +Eeuo pipefail

	# Removes the ERR trap so error_handler is no longer invoked automatically.
	trap - ERR
}

# ------------------------------------------------------------------------------
enable_error_handler
