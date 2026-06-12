#!/bin/bash

# Get current scripts absolute path
CURRENT_SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The "lib" folders relative path
LIB="$CURRENT_SCRIPT_PATH/../lib"


# Import library scripts
source "$LIB/unit_test.sh"
source "$LIB/logger.sh"

# ------------------------------------------------------------------------------
# Cleanup
# ------------------------------------------------------------------------------

function cleanup() {
	cleanup_test_env
}

trap 'cleanup' EXIT

# ------------------------------------------------------------------------------
# Test cases
# ------------------------------------------------------------------------------

DESCRIBE "Test if all the filter methods are working"

function test_all_filter_methods() {
	LOGFILTER="DEBUG | NORMAL | INFO | WARNING | ERROR"

	debug "This is a DEBUG message."
	log "This is a NORMAL message."
	info "This is an INFO message."
	warning "This is a WARNING message."
	error "This is an ERROR message."
}

RUN test_all_filter_methods

copy_stdout_to output
output=$(echo "$output" | sed -E 's/^[0-9-]{10} [0-9:]{8} - //')

expected="DEBUG  - This is a DEBUG message.
NORMAL - This is a NORMAL message.
INFO   - This is an INFO message.
WARNIN - This is a WARNING message.
ERROR  - This is an ERROR message."

EXPECT_TO_BE_EQUAL "$expected" "$output" "The output is not the expected one" 

ENDTEST

# ==============================================================================

DESCRIBE "Test LOGFILTER"

underline="-------------------"
function test_LOGFILTER() {
	local log_levels=("DEBUG" "NORMAL" "INFO" "WARNING" "ERROR")

	for log_level in "${log_levels[@]}"; do
		echo -e "LOGFILTER=\"$log_level\"\n$underline"

		LOGFILTER="$log_level"

		debug "This is a DEBUG message."
		log "This is a NORMAL message."
		info "This is an INFO message."
		warning "This is a WARNING message."
		error "This is an ERROR message."

        echo
	done
}

RUN test_LOGFILTER

copy_stdout_to output
output=$(echo "$output" | sed -E 's/^[0-9-]{10} [0-9:]{8} - //')

expected="LOGFILTER=\"DEBUG\"
$underline
DEBUG  - This is a DEBUG message.

LOGFILTER=\"NORMAL\"
$underline
NORMAL - This is a NORMAL message.

LOGFILTER=\"INFO\"
$underline
INFO   - This is an INFO message.

LOGFILTER=\"WARNING\"
$underline
WARNIN - This is a WARNING message.

LOGFILTER=\"ERROR\"
$underline
ERROR  - This is an ERROR message."

EXPECT_TO_BE_EQUAL "$expected" "$output" "The output is not the expected one"

ENDTEST

# ==============================================================================

DESCRIBE "The LOGGING=0 disables the logging completely"

function test_disable_logging() {
    LOGGING=0

	LOGFILTER="DEBUG | NORMAL | INFO | WARNING | ERROR"

	debug "This is a DEBUG message."
	log "This is a NORMAL message."
	info "This is an INFO message."
	warning "This is a WARNING message."
	error "This is an ERROR message."

    LOGGING=1
}

RUN test_disable_logging

copy_stdout_to output
output=$(echo "$output" | sed -E 's/^[0-9-]{10} [0-9:]{8} - //')

expected=""

EXPECT_TO_BE_EQUAL "$expected" "$output" "The output is not the expected one"

ENDTEST

# ==============================================================================

DESCRIBE "Redirect logging into a fajl with LOGFILE=\"logfile.log\""

function test_redirect_logging_into_logfile() {
    LOGFILE="logfile.log"
	LOGFILTER="DEBUG | NORMAL | INFO | WARNING | ERROR"

	debug "This is a DEBUG message."
	log "This is a NORMAL message."
	info "This is an INFO message."
	warning "This is a WARNING message."
	error "This is an ERROR message."
}

RUN test_redirect_logging_into_logfile

copy_from_to "$LOGFILE" output
output=$(echo "$output" | sed -E 's/^[0-9-]{10} [0-9:]{8} - //')

expected="DEBUG  - This is a DEBUG message.
NORMAL - This is a NORMAL message.
INFO   - This is an INFO message.
WARNIN - This is a WARNING message.
ERROR  - This is an ERROR message."

EXPECT_TO_BE_EQUAL "$expected" "$output" "The output is not the expected one" 

ENDTEST "$LOGFILE"

# ==============================================================================
