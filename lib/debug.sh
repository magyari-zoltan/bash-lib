#!/bin/bash

# ------------------------------------------------------------------------------
# Bash script debug helper.
#
# This file provides small helper functions for controlling shell trace mode 
# `set -x` in Bash scripts. When trace mode is enabled, Bash prints each command 
# before executing it, which is useful for debugging script flow.
#
# The `DEBUG` variable controls whether tracing should be enabled:
# 0 - tracing disabled
# 1 - tracing enabled
# ------------------------------------------------------------------------------

# Prevent multiple sourcing
[[ -v "DEBUG_LOADED" ]] && return 0 # Return instead of exit to avoid terminating the calling script.
readonly DEBUG_LOADED=true

# ------------------------------------------------------------------------------
# Public API: Functions intended for external use
# ------------------------------------------------------------------------------

# Global trace mode swith
# 0 - disabled
# 1 - enabled
DEBUG=1

# Enables Bash trace mode when debugging is active.
function debug_on {
	if [[ "$DEBUG" != "0" ]]; then
		echo "+ debug_on" >&2
		set -x # trace mode on: echo executed commands.
	fi
}

# Disables Bash trace mode when debugging is active.
function debug_off() {
	{ 
		if [[ "$DEBUG" != "0" ]]; then
			set +x; # trace mode off: don't echo executed commands.
		fi
	} 2> /dev/null # Prevents commands in thist block to be traced.
}

# ------------------------------------------------------------------------------

