# Bash helper functions

The **bash-lib** is a collection of reusable Bash helper functions and scripts.

The intended method of use is as a **Git submodule**. The reason for separating it
into a dedicated repository is to enable the centralized development and
maintenance of reusable components, while allowing any desired version of the
library to be used across multiple projects.

## `debug.sh`

Enables and disables Bash trace mode (`set -x`) for debugging script execution.

**Usage**

```bash
source lib/debug.sh
debug_on
debug_off
```

**Functions**

- `debug_on` — turns on trace mode when `DEBUG` is `1`.
- `debug_off` — turns off trace mode when `DEBUG` is `0`.

**Parameters**

- None.
- Uses the global `DEBUG` flag (`0` = disabled, `1` = enabled).

## `error_handler.sh`

Provides strict error handling and prints a helpful stack trace when a Bash command fails.

**Usage**

```bash
source lib/error_handler.sh
enable_error_handler
# run commands
disable_error_handler
```

**Functions**

- `enable_error_handler` — enables `set -Eeuo pipefail` and installs an `ERR` trap.
- `disable_error_handler` — disables the trap and turns strict mode off.

## `logger.sh`

Writes timestamped log messages to stdout or to a log file, with optional level filtering.

**Usage**

```bash
source lib/logger.sh
log "Build started"
warning "Something looks odd"
error "Something failed"
```

**Functions**

- `log message [level]` — logs a message with an optional level.
- `debug message` — logs a `DEBUG` message.
- `info message` — logs an `INFO` message.
- `warning message` — logs a `WARNING` message.
- `error message` — logs an `ERROR` message.

**Parameters**

- `message` — text to log.
- `level` — optional log level, default is `NORMAL`.
- Uses the global `LOGGING`, `LOGFILE`, and `LOGFILTER` variables.

## `stack.sh`

Implements a simple Bash array-based stack using namerefs.

**Usage**

```bash
source lib/stack.sh
stack=(car train)
stack_push stack airplane
stack_pop stack value
```

**Functions**

- `stack_size stack_ref` — returns the number of items.
- `stack_is_empty stack_ref` — returns `0` for empty stacks and `1` otherwise.
- `stack_push stack_ref value` — pushes a value on top of the stack.
- `stack_pop stack_ref value_ref` — pops the top value into a variable.
- `stack_top stack_ref value_ref` — reads the top value without removing it.

**Parameters**

- `stack_ref` — name of the Bash array variable.
- `value_ref` — name of the output variable.
- `value` — value to push.

## `type.sh`

Detects the type of Bash variables and raw values.

**Usage**

```bash
source lib/type.sh
type my_var
type_of_value "42"
```

**Returns**

- `type` prints one of these values: `array`, `associative map`, `nameref`, `number`, `boolean`, `string`, or `undefined`.
- For unknown or unset variables, it prints `undefined` and returns exit code `1`.
- `type_of_value` prints `number`, `boolean`, or `string` and returns exit code `0`.

**Functions**

- `type var_name` — returns the type of a variable.
- `type_of_value value` — returns the type of a literal value.

**Examples**

```bash
source lib/type.sh

declare -a items=(car train)
declare -A map=([car]=vehicle)
declare -n ref=value
value=42
flag=true
text=hello

# Prints: array
type items

# Prints: associative map
type map

# Prints: nameref
type ref

# Prints: number
type value

# Prints: boolean
type flag

# Prints: string
type text

# Prints: undefined and returns 1
unset missing_value
type missing_value

# Prints: number
type_of_value "42"

# Prints: boolean
type_of_value "false"

# Prints: string
type_of_value "car"
```

**Parameters**

- `var_name` — name of the variable to inspect.
- `value` — literal value to classify.

## `unit_test.sh`

A tiny Bash test framework used by the repository's test suite.

**Usage**

```bash
source lib/unit_test.sh
DESCRIBE "Example"
RUN echo "hello"
copy_stdout_to output
EXPECT_TO_BE_EQUAL "hello" "$output" "Unexpected output."
ENDTEST
```

**Functions**

- `DESCRIBE description` — starts a new test case.
- `RUN command [args...]` — runs a command and captures stdout/stderr.
- `RUNBG command [args...]` — runs a command in the background.
- `EXPECT_TO_BE_EQUAL expected actual message` — compares two values.
- `EXPECT ...` — evaluates a shell test expression.
- `FAIL message` — marks the current test as failed.
- `ENDTEST` — finalizes the current test case.
- `copy_stdout_to var_ref`, `copy_stderr_to var_ref`, `copy_from_to src var_ref` — copy captured output into variables.
- `cleanup_test_env` — removes temporary test artifacts.

**Parameters**

- Most functions take a small number of positional arguments.
- Output-copy helpers expect a variable name passed by reference.

## `yaml_parser.sh`

Parses simple YAML files into a Bash associative array and stores metadata such as type, level, and array length.

**Usage**

```bash
source lib/yaml_parser.sh
declare -A map=()
parse_yaml "res/disks.yaml" map
```

**Example YAML**

```yaml
disks:
  - device: /dev/sda
    table: gpt
    wipe: true

    partitions:
      - name: EFI
        size: 512M
        type: EFI System
        filesystem: vfat
        label: EFI
        mount_point: /boot/efi
```

**Example associative array**

```bash
declare -A map=(
  ["disks:type"]="array"
  ["disks:length"]="1"
  ["disks[0]:type"]="index"
  ["disks[0].device"]="/dev/sda"
  ["disks[0].device:type"]="string"
  ["disks[0].table"]="gpt"
  ["disks[0].table:type"]="string"
  ["disks[0].wipe"]="true"
  ["disks[0].wipe:type"]="boolean"
)
```

**Functions**

- `parse_yaml file map_ref` — parses a YAML file into an associative array.

**Parameters**

- `file` — path to the YAML file.
- `map_ref` — name of the associative array receiving the parsed data.

## Directory Structure

- doc: Documentation related to the scripts, including system designs and other project documentation.
- lib: The reusable library code. This is the part intended to be used by other projects.
- res: Test resources and sample data used by the test suite.
- test: Tests written for the library code.
