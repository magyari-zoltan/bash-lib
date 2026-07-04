---
name: bash-script-test
description: This file contains instructions for writing tests for the library scripts.
---

# Code structure

1. Start with a shebang
2. Calculation of paths to sourced files. Example:

```bash
# Get current scripts absolute path
CURRENT_SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The "lib" folders relative path
LIB="$CURRENT_SCRIPT_PATH/../lib"
RES="$CURRENT_SCRIPT_PATH/../res"


# Import library scripts
source "$LIB/unit_test.sh"
source "$LIB/yaml_parser.sh"
```

3. Comes the cleanup section.

```bash
# ------------------------------------------------------------------------------
# Cleanup
# ------------------------------------------------------------------------------

function cleanup() {
	local exit_code=$?
	cleanup_test_env

	if [[ "$UNIT_TEST_FAILED_TESTS" -gt 0 ]]; then
		exit 1
	fi

	exit "$exit_code"
}


trap 'cleanup' EXIT

```

4. Global variable section

```bash
# ------------------------------------------------------------------------------
# Globbal variables
# ------------------------------------------------------------------------------
```

5. Test cases section

Mark the beginning with the following comment block:

```bash
# ------------------------------------------------------------------------------
# Test cases
# ------------------------------------------------------------------------------
```

Tests use `DESCRIBE`, `RUN`, `EXPECT_TO_BE_EQUAL`, `ENDTEST`, and other methods
from the `lib/unit_test.sh` to write tests.

Example:

```bash
DESCRIBE "The 'parse_line' parses a 'string' from the line and pushes it into the map."

stack=("device")
map=()

log_variable stack
log_variable map
RUN parse_line " /dev/sda " stack map
log_variable stack
log_variable map

expected="declare -A map=([device]=\"/dev/sda\" [device:type]=\"string\" )"
EXPECT_TO_BE_EQUAL "$expected" "$(declare -p map)" "The 'parse_line' parser did not create the expected map: $expected."

ENDTEST
```

Each test case ends with a separator line comment:

```bash
# ==============================================================================
```
