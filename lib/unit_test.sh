#!/bin/bash

# ------------------------------------------------------------------------------
# Library
#
# Minimal shell unit test helpers for describing test cases, checking
# expectations, capturing script output into log files, and cleaning up
# temporary test artifacts.
# ------------------------------------------------------------------------------

# Prevent multiple sourcing
if [[ -n "${UNIT_TEST_LOADED:-}" ]]; then
	# Return instead of exit to avoid terminating the calling script.
	return 0 
fi

readonly UNIT_TEST_LOADED=true

# ------------------------------------------------------------------------------
# Internal API: Functions intended for use within this library
# ------------------------------------------------------------------------------

readonly UNIT_TEST_SCRIPT_STDERR="unit_test_script_stderr.log"
readonly UNIT_TEST_SCRIPT_STDOUT="unit_test_script_sdtout.log"
readonly UNIT_TEST_EXECUTION_LOG="test_execution.log"

# Empties the unit test execution log file
> "$UNIT_TEST_EXECUTION_LOG"

function unit_test_log() {
	# Does nothing if no arguments.
	[[ $# -gt 0 ]] || return 0

	# If it gets one argument it expects to be the text and not an option.
	[[ $# -eq 1 ]] && [[ "$1" != --* ]] && \
	printf '%s\n' "$1" | tee -a "$UNIT_TEST_EXECUTION_LOG"

	# If gets two arguments then if the first is the --only-logfile option and
	# then second should be the text. It prints the text only into the log file.
	[[ $# -eq 2 ]] && [[ "$1" == "--only-logfile" ]] && \
	printf '%s\n' "$2" >> "$UNIT_TEST_EXECUTION_LOG"

	# If gets two arguments then if the first is the --only-stdout option and
	# then second should be the text. It prints the text only to the stdout.
	[[ $# -eq 2 ]] && [[ "$1" == "--only-stdout" ]] && \
	printf '%s\n' "$2" 

	# In any other case the method does nothing.
	return 0
}

# Logs both the std output and the error output and other logfiles 
# into the UNIT_TEST_EXECUTION_LOG logfile if they are passed in as
# input parameters.
function unit_test_log_outputs() {
	local other_logfiles=("$@")

	if [[ $# -eq 0 ]]; then
		log_output="$(cat $UNIT_TEST_SCRIPT_STDOUT)"
		if [[ -n "$log_output" ]]; then
			unit_test_log --only-logfile ""
			unit_test_log --only-logfile "----------------------------------"
			unit_test_log --only-logfile "Standard output:"
			unit_test_log --only-logfile "----------------------------------"
			unit_test_log --only-logfile ""
			unit_test_log --only-logfile "$log_output"
		fi

		log_output="$(cat $UNIT_TEST_SCRIPT_STDERR)"
		if [[ -n "$log_output" ]]; then
			unit_test_log --only-logfile ""
			unit_test_log --only-logfile "----------------------------------"
			unit_test_log --only-logfile "Error output:"
			unit_test_log --only-logfile "----------------------------------"
			unit_test_log --only-logfile ""
			unit_test_log --only-logfile "$log_output"
		fi
	else
		for log_file in "${other_logfiles[@]}"; do
			if [[ -s "$log_file" ]]; then
				log_output="$(cat $log_file)"
				unit_test_log --only-logfile ""
				unit_test_log --only-logfile "----------------------------------"
				unit_test_log --only-logfile "$log_file:"
				unit_test_log --only-logfile "----------------------------------"
				unit_test_log --only-logfile ""
				unit_test_log --only-logfile "$log_output"
			fi

            [[ -f "$log_file" ]] && rm "$log_file"
		done
	fi

	return 0
}

# ------------------------------------------------------------------------------
# Public API: Functions intended for external use
# ------------------------------------------------------------------------------

# Removes the stdout/stderr log files created during test execution.
function cleanup_test_env() {
	# Remove error log file
	if [ -f "$UNIT_TEST_SCRIPT_STDERR" ]; then
		rm "$UNIT_TEST_SCRIPT_STDERR"
	fi

	# Test outout file
	if [ -f "$UNIT_TEST_SCRIPT_STDOUT" ]; then
		rm "$UNIT_TEST_SCRIPT_STDOUT"
	fi
}

# Copies the stdout into the first argument
function copy_stdout_to() {
	local -n stdout=$1
	stdout=$(< "$UNIT_TEST_SCRIPT_STDOUT")
}

# Copies the stderr into the first argument
function copy_stderr_to() {
	local -n stderr=$1
	stderr=$(< "$UNIT_TEST_SCRIPT_STDERR")
}

# Copies the content of a given file passed in as the first argument
# into the second argument
function copy_from_to() {
    local srcFile=$1
	local -n target=$2
	target=$(< "$srcFile")
}


TESTNO=0

# Starts a new test case, increments its index, and prints its description.
function DESCRIBE() {
	description="$1"

	TESTNO=$((TESTNO+1))
	unit_test_log --only-logfile ""
	unit_test_log --only-logfile "================================================================================"
	unit_test_log "$TESTNO. Test: $description"

}

# Evaluates a condition and prints an error message if the check fails.
function EXPECT() {
	message="${@: -1}"

	if ! test "${@:1:$#-1}"; then
		unit_test_log --only-stdout "ERROR: $message"
		return 1
	fi

	return 0
}

# Compares the first two arguments, if not equal then prints an error message 
function EXPECT_TO_BE_EQUAL() {
	expected="$1"
	actual="$2"
	message="$3"

	if [[ "$expected" != "$actual" ]] then
		unit_test_log --only-stdout "ERROR: $message"
		return 1
	fi

	return 0
}

# Prints an explicit test failure in a consistent format.
function FAIL() {
	message="$1"
	unit_test_log --only-stdout "ERROR: $message"
}

# Runs a script and redirects standard outputs into separate log files.
function RUN() {
	script="$1"; shift

	args="$@"
	unit_test_log --only-logfile ""
	unit_test_log --only-logfile ">_ $script $args"

	"$script" "$@" > "$UNIT_TEST_SCRIPT_STDOUT" 2> "$UNIT_TEST_SCRIPT_STDERR"
	retval=$?

	return $retval
}

# Runs a script in the background and redirects standard outputs into separate log files.
RUNBG_PID=""
function RUNBG() {
	local script="$1"; shift

	unit_test_log --only-logfile ""
	unit_test_log --only-logfile ">_ $script $@ &"

	# Enable Bash job control mode.
	# Enables the management of background processes.
	set -m 

	# Executes the command received as a parameter together with its arguments.
	# Redirects the script’s standard output and error output to log files.
	"$script" "$@" > "$UNIT_TEST_SCRIPT_STDOUT" 2> "$UNIT_TEST_SCRIPT_STDERR" &
	RUNBG_PID=$!

	# Disables Bash job control mode.
	set +m

	# Based on measurements, it takes approximately 11 ms for the script
	# to reach the point where it creates the SIGINT trap. Therefore, 
	# I wait 30 ms to make sure the trap is definitely in place.
	sleep 0.03
}

function ENDTEST() {
	unit_test_log_outputs "$@"
}
