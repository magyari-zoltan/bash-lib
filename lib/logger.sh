#!/bin/bash

# ------------------------------------------------------------------------------
# Bash script logging helper.
#
# This file provides simple helper functions for writing timestamped log
# messages either to standard output or to a configured log file.
#
# The logger behavior is controlled by these runtime variables:
#
# LOGGING  - Enables or disables logging entirely
#
# LOGFILE  - When set, log messages are appended to this file
#
# LOGLEVEL - Limits specialized logging behavior such as error output.
#            Allowed values: DEBUG | NORMAL | INFO | WARNING | ERROR
#
#            Default: LOGFILTER="NORMAL | WARNNING | ERROR"
# ------------------------------------------------------------------------------

# Prevent multiple sourcing
if [[ -n "${LOGGER_LOADED:-}" ]]; then
	# Return instead of exit to avoid terminating the calling script.
	return 0 
fi

readonly LOGGER_LOADED=true

# Global logging switch
# 0 - disabled
# 1 - enabled
LOGGING=1

# When empty, log output is written to standard output.
LOGFILE=""

# Turning on / off the filters
LOGFILTER="NORMAL | WARNNING | ERROR"

# Writes a timestamped log entry when logging is enabled.
# If a second argument is provided, it is used as the log level label otherwies
# considers the log level to be NORMAL.
log() {
	# If logging is disabled then return.
	[[ "$LOGGING" == "0" ]] && return 0
	
	# If no text passed in then do nothing.
	[[ -z "$1" ]] && return 0
	local message=$1


	# If logging level is passed in as parameter then use that, otherwise default to NORMAL.
	local level="${2:-NORMAL}" 

	# Filter the loglevels
	if [[ "$LOGFILTER" != *$level* ]]; then
		return 0
	fi

	# Logfile is provided
	if [[ -n "$LOGFILE" ]]; then
		# Log into the $LOGFILE
		echo "$(date '+%F %T') - $(printf '%-6.6s' $level) - $message" >> "$LOGFILE"
	else
		# Log on the standart output
		echo "$(date '+%F %T') - $(printf '%-6.6s' $level) - $message"
	fi
}

debug() {
	log "$1" "DEBUG"
}

info() {
	log "$1" "INFO"
}

warning() {
	log "$1" "WARNING"
}

error() {
	log "$1" "ERROR"
}

