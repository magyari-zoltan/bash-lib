#!/bin/bash

# Get current scripts absolute path
CURRENT_SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The "test" folders relative path
readonly TEST="$CURRENT_SCRIPT_PATH"

# Import test files
source "$TEST/debug.test.sh"
source "$TEST/logger.test.sh"
source "$TEST/stack.test.sh"
