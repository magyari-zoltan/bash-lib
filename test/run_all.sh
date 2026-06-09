#!/bin/bash

# Get current scripts absolute path
readonly RUN_ALL_SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The "test" folders relative path
readonly TEST="$RUN_ALL_SCRIPT_PATH"

# Import test files
source "$TEST/debug.test.sh"
