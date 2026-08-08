#!/usr/bin/env bash

# Get current scripts absolute path
TEST_SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The "lib" and "res" folders relative path
LIB="$TEST_SCRIPT_PATH/../lib"
RES="$TEST_SCRIPT_PATH/../res"


# Import library scripts
source "$LIB/unit_test.sh"
source "$LIB/require.sh"

# ------------------------------------------------------------------------------
# Cleanup
# ------------------------------------------------------------------------------

TMP_DIR="$(mktemp -d)"

function cleanup() {
	local exit_code=$?
	cleanup_test_env
	rm -rf "$TMP_DIR"

	if [[ "$UNIT_TEST_FAILED_TESTS" -gt 0 ]]; then
		exit 1
	fi

	exit "$exit_code"
}


trap 'cleanup' EXIT

# ------------------------------------------------------------------------------
# Mocks
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Create directory structure for the fake package manager and installed 
# commands.
# ------------------------------------------------------------------------------
INSTALLED_BIN="$TMP_DIR/installed-bin"
LOG_DIR="$TMP_DIR/log"
BIN_DIR="$TMP_DIR/bin"

mkdir -p "$INSTALLED_BIN" "$LOG_DIR" "$BIN_DIR" 

# Export the directories so that they can be used in the tests.
export INSTALLED_BIN
export LOG_DIR

# ------------------------------------------------------------------------------
# Create wrapper scripts for the commands that will be used in the tests.
# ------------------------------------------------------------------------------
function mock_command() {
	local file="$1"
	local target="$2"

	cat > "$file" <<EOF
#!/usr/bin/env bash
exec "$target" "\$@"
EOF

	"$CHMOD_BIN" +x "$file"
}

RM_BIN="$(command -v rm)"
CHMOD_BIN="$(command -v chmod)"
TEE_BIN="$(command -v tee)"
CAT_BIN="$(command -v cat)"
SED_BIN="$(command -v sed)"
DIRNAME_BIN="$(command -v dirname)"
BASH_BIN="$(command -v bash)"
MKDIR_BIN="$(command -v mkdir)"

mock_command "$BIN_DIR/bash" "$BASH_BIN"
cat > "$BIN_DIR/sudo" <<EOF
#!/usr/bin/env bash
exec "\$@"
EOF
"$CHMOD_BIN" +x "$BIN_DIR/sudo"
mock_command "$BIN_DIR/tee" "$TEE_BIN"
mock_command "$BIN_DIR/cat" "$CAT_BIN"
mock_command "$BIN_DIR/rm" "$RM_BIN"
mock_command "$BIN_DIR/sed" "$SED_BIN"
mock_command "$BIN_DIR/dirname" "$DIRNAME_BIN"
mock_command "$BIN_DIR/mkdir" "$MKDIR_BIN"
mock_command "$BIN_DIR/chmod" "$CHMOD_BIN"

# ------------------------------------------------------------------------------
# Create a fake package manager script that simulates installing packages and
# logs the install commands.
# ------------------------------------------------------------------------------
function mock_package_manager() {
	local file="$1"

	cat > "$file" <<EOF
#!/usr/bin/env bash

set -euo pipefail

if [[ "\${REQUIRE_INSTALL_FAIL:-0}" == "1" ]]; then
	exit 1
fi

package="\${*: -1}"
target="\${REQUIRE_TARGET_COMMAND:-\$package}"

cat > "\$INSTALLED_BIN/\$target" <<'EOI'
#!/usr/bin/env bash
exit 0
EOI

"$CHMOD_BIN" +x "\$INSTALLED_BIN/\$target"
printf '%s %s\n' "\${0##*/}" "\$*" >> "\$LOG_DIR/install.log"
EOF

	"$CHMOD_BIN" +x "$file"
}

mock_package_manager "$BIN_DIR/apt-get"
mock_package_manager "$BIN_DIR/pacman"

# ------------------------------------------------------------------------------
# Creates a custom require.yaml file that defines a custom install script for 
# the current distro. The custom install script will simulate the installation 
# of a command and log the execution to a custom script log file. The custom 
# install script will be executed by the require command when the command is 
# missing and a custom script is defined in the require.yaml file.
# ------------------------------------------------------------------------------
function create_yaml_with_custom_script() {
    local yaml_file="$1"
    local distroName="$2"
    local appName="$3"

    cat > "$yaml_file" <<EOF
package_manager:
  $distroName:
    install: $(get_distro_specific_installer)
    app:
      __bash_lib_custom_script_command__:
        script: $distroName/install/$appName.sh
EOF
}

# ------------------------------------------------------------------------------
# Creates a custom install script that simulates the installation of a command
# and logs the execution to a custom script log file. The custom install script
# will be executed by the require command when the command is missing and a
# custom script is defined in the require.yaml file.
# ------------------------------------------------------------------------------
function create_custom_install_script() {
    local appName="$1"

    # Create a custom install script for the current distro. The custom install script
    # will simulate the installation of a command and log the execution to a custom
    # script log file. The custom install script will be executed by the require
    # command when the command is missing and a custom script is defined in the
    # require.yaml file.
    custom_script_dir="$TMP_DIR/$distro_name/install"
    script_file="$custom_script_dir/$appName.sh"

    mkdir -p "$custom_script_dir"

	cat > "$script_file" <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

target="${REQUIRE_TARGET_COMMAND:-}"
if [[ -z "$target" ]]; then
	exit 1
fi

cat > "$INSTALLED_BIN/$target" <<'EOI'
#!/usr/bin/env bash
exit 0
EOI

chmod +x "$INSTALLED_BIN/$target"
printf '%s %s\n' "${0##*/}" "$*" >> "$LOG_DIR/custom-script.log"
EOF

	chmod +x "$script_file"
}

# ------------------------------------------------------------------------------
# Returns the contents of the install log file if it exists, otherwise returns 
# an empty string. The log files is created by the mock package manager scripts 
# to record the install commands that were executed during the tests.
# ------------------------------------------------------------------------------
function get_install_log_contents() {
	if [[ -f "$LOG_DIR/install.log" ]]; then
		cat "$LOG_DIR/install.log"
	fi
}
 
# ------------------------------------------------------------------------------
# Gets the current install command based on the detected distro. This is used to
# verify that the require command calls the correct package manager during the
# tests.
# ------------------------------------------------------------------------------
function get_distro_specific_installer() {
	case "$(distro)" in
		debian) printf '%s' 'apt-get install -y' ;;
		arch) printf '%s' 'pacman -S --noconfirm' ;;
		*)
			printf '%s' 'unsupported'
			return 1
			;;
	esac
}

export PATH="$BIN_DIR:$INSTALLED_BIN"

# ------------------------------------------------------------------------------
# Test cases
# ------------------------------------------------------------------------------

DESCRIBE "The require command returns 0 for existing commands."

# The require command should return 0 when the specified command is already
# available in the PATH. The require.yaml file is provided to simulate a scenario
# where the command is mapped to a package, but since the command already exists,
# no installation should occur.
RUN require bash "$RES/require.yaml"
ret_val=$?
copy_stderr_to stderr_output

EXPECT_TO_BE_EQUAL "0" "$ret_val" "The return value should be '0' for existing commands."
EXPECT_TO_BE_EQUAL "" "$stderr_output" "No error output is expected for existing commands."
EXPECT_TO_BE_EQUAL "" "$(get_install_log_contents)" "No install should happen when the command already exists."

ENDTEST

# ==============================================================================

DESCRIBE "The require script succeeds when executed directly for an existing command."

RUN bash "$LIB/require.sh" bash "$RES/require.yaml"
ret_val=$?
copy_stderr_to stderr_output

EXPECT_TO_BE_EQUAL "0" "$ret_val" "The script should return '0' when it is executed directly for an existing command."
EXPECT_TO_BE_EQUAL "" "$stderr_output" "No error output is expected for direct execution with an existing command."

ENDTEST

# ==============================================================================

DESCRIBE "The require command installs a mapped package when the command is missing."

# Get the expected install command based on the detected distro. This is used to
# verify that the require command calls the correct package manager during the
# tests.
#
# Example expected install commands for different distros:
# apt-get install -y util-linux
# pacman -S --noconfirm util-linux
expected_installer="$(get_distro_specific_installer)"

# Clear the install log before running the require command to ensure that we 
# only capture the install command for this test.
#
# The install log is created by the mock package manager scripts to record the
# install commands that were executed during the tests.
: > "$LOG_DIR/install.log"

# Run the require command for a command that is mapped to a package in the
# require.yaml file. The mock package manager will simulate the installation of
# the package and log the install command to the install log file.
#
# The REQUIRE_TARGET_COMMAND environment variable is set to the command name
# that is being required. This allows the mock package manager to create a fake
# installed command with the same name as the required command.
REQUIRE_TARGET_COMMAND="fdisk" RUN require fdisk "$RES/require.yaml"
ret_val=$?
copy_stderr_to stderr_output

EXPECT_TO_BE_EQUAL "0" "$ret_val" "The return value should be '0' after installing the mapped package."
EXPECT_TO_BE_EQUAL "" "$stderr_output" "No error output is expected after a successful install."
EXPECT_TO_BE_EQUAL "${expected_installer} util-linux" "$(get_install_log_contents)" "The package manager should be called with the mapped package."

# Verify that the installed command is now available on the PATH.
command -v fdisk >/dev/null 2>&1
ret_val=$?
EXPECT_TO_BE_EQUAL "0" "$ret_val" "The installed command should be visible on PATH."

ENDTEST

# ==============================================================================

DESCRIBE "The require command installs the command name as the package when no mapping exists."

# Clear the install log before running the require command to ensure that we only
# capture the install command for this test.
: > "$LOG_DIR/install.log"

# Run the require command for a command that is not mapped to a package in the
# require.yaml file. The mock package manager will simulate the installation of
# the package and log the install command to the install log file.
#
# The REQUIRE_TARGET_COMMAND environment variable is set to the command name
# that is being required. This allows the mock package manager to create a fake
# installed command with the same name as the required command.
REQUIRE_TARGET_COMMAND="__bash_lib_fallback_missing_command__" RUN require "__bash_lib_fallback_missing_command__" "$RES/require.yaml"
ret_val=$?
copy_stderr_to stderr_output

EXPECT_TO_BE_EQUAL "0" "$ret_val" "The return value should be '0' after installing the fallback package."
EXPECT_TO_BE_EQUAL "" "$stderr_output" "No error output is expected after a successful fallback install."
EXPECT_TO_BE_EQUAL "${expected_installer} __bash_lib_fallback_missing_command__" "$(get_install_log_contents)" "The package manager should be called with the command name."

# Verify that the installed command is now available on the PATH.
command -v __bash_lib_fallback_missing_command__ >/dev/null 2>&1
ret_val=$?
EXPECT_TO_BE_EQUAL "0" "$ret_val" "The installed command should be visible on PATH."

ENDTEST

# ==============================================================================

DESCRIBE "The require command runs a custom install script when one is defined."

# Get the current distro name to create a custom require.yaml file that defines a
# custom install script for the current distro. 
distro_name="$(distro)"

# Create a custom require.yaml file that defines a custom install script for the
# current distro. The custom install script will simulate the installation of a
# command and log the execution to a custom script log file.
appName="nodejs"
custom_yaml="$TMP_DIR/custom-require.yaml"
create_yaml_with_custom_script "$custom_yaml" "$distro_name" "$appName"

# Create a custom install script that simulates the installation of a command
# and logs the execution to a custom script log file. The custom install script
# will be executed by the require command when the command is missing and a
# custom script is defined in the require.yaml file.
create_custom_install_script "$appName"

# Clear the install log before running the require command to ensure that we only
# capture the install command for this test.
: > "$LOG_DIR/install.log"

# Run the require command for a command that is mapped to a custom install script
# in the custom require.yaml file. The custom install script will simulate the
# installation of the command and log the execution to a custom script log file.
#
# The REQUIRE_TARGET_COMMAND environment variable is set to the command name that
# is being required. This allows the custom install script to create a fake 
# installed command with the same name as the required command.
REQUIRE_TARGET_COMMAND="__bash_lib_custom_script_command__" RUN require "__bash_lib_custom_script_command__" "$custom_yaml"
ret_val=$?
copy_stderr_to stderr_output

EXPECT_TO_BE_EQUAL "0" "$ret_val" "The return value should be '0' after running the custom install script."
EXPECT_TO_BE_EQUAL "" "$stderr_output" "No error output is expected after a successful custom script install."
EXPECT_TO_BE_EQUAL "" "$(get_install_log_contents)" "The package manager should not be used when a custom script is defined."
EXPECT_TO_BE_EQUAL "nodejs.sh __bash_lib_custom_script_command__" "$(cat "$LOG_DIR/custom-script.log")" "The custom script should be executed for the command."

# Verify that the installed command is now available on the PATH.
command -v __bash_lib_custom_script_command__ >/dev/null 2>&1
ret_val=$?
EXPECT_TO_BE_EQUAL "0" "$ret_val" "The installed command should be visible on PATH."

ENDTEST

# ==============================================================================

DESCRIBE "The require command returns 1 on an unsupported distro."

# Save the original distro implementation so the test can override it safely.
original_distro_backup="$(declare -f distro)"

# Force an unsupported distro name for this test case.
function distro() {
	printf '%s\n' 'fedora'
}

# Clear the install log before running the require command. This ensures that we
# only capture the install command for this test.
: > "$LOG_DIR/install.log"

# Run require against a distro that is not present in the YAML metadata.
RUN require "__bash_lib_unsupported_missing_command__" "$RES/require.yaml"
ret_val=$?
copy_stderr_to stderr_output

# The command should fail with a distro-specific error and no install attempt.
EXPECT_TO_BE_EQUAL "1" "$ret_val" "The return value should be '1' for an unsupported distro."
EXPECT_TO_BE_EQUAL "ERROR: install command not found for distro: fedora" "$stderr_output" "The error message should mention the unsupported distro."
EXPECT_TO_BE_EQUAL "" "$(get_install_log_contents)" "No install should happen when the distro is unsupported."

# Restore the original distro implementation for the remaining tests.
eval "$original_distro_backup"

ENDTEST

# ==============================================================================

DESCRIBE "The require command returns 1 when the install command fails."

# Clear the install log before running the require command to ensure that we only
# capture the install command for this test.
: > "$LOG_DIR/install.log"

# Run the require command for a command that is not mapped to a package in the
# require.yaml file. The mock package manager will simulate a failed installation
# by returning a non-zero exit code. The require command should return 1 and
# print an error message to stderr. 
#
# The REQUIRE_INSTALL_FAIL environment variable is set to 1 to simulate a failed
# installation. The REQUIRE_TARGET_COMMAND environment variable is set to the
# command name that is being required. This allows the mock package manager to
# create a fake installed command with the same name as the required command.
REQUIRE_INSTALL_FAIL=1 RUN require "__bash_lib_failing_missing_command__" "$RES/require.yaml"
ret_val=$?
copy_stderr_to stderr_output
REQUIRE_INSTALL_FAIL=0

EXPECT_TO_BE_EQUAL "1" "$ret_val" "The return value should be '1' when installation fails."
EXPECT_TO_BE_EQUAL "ERROR: failed to install package for command: __bash_lib_failing_missing_command__" "$stderr_output" "The error message should mention the failed command."

ENDTEST

# ==============================================================================

DESCRIBE "The require command returns 1 when no argument is provided."

# Run the require command without any arguments. The require command should
# return 1 and print an error message to stderr indicating that both required
# arguments are missing.
RUN require
ret_val=$?
copy_stderr_to stderr_output

EXPECT_TO_BE_EQUAL "1" "$ret_val" "The return value should be '1' when no command name is provided."
EXPECT_TO_BE_EQUAL "ERROR: require expects a command name and a YAML file." "$stderr_output" "The error message should explain the missing arguments."

ENDTEST

# ==============================================================================

DESCRIBE "The require command returns 1 when the command argument is empty."

# Run the require command with an empty command name and a valid YAML file.
RUN require "" "$RES/require.yaml"
ret_val=$?
copy_stderr_to stderr_output

EXPECT_TO_BE_EQUAL "1" "$ret_val" "The return value should be '1' when the command argument is empty."
EXPECT_TO_BE_EQUAL "ERROR: require expects a command name and a YAML file." "$stderr_output" "The error message should explain that both arguments are required."

ENDTEST

# ==============================================================================

DESCRIBE "The require command returns 1 when the YAML file argument is missing."

# Run the require command with only the command name. The command should fail
# because the YAML file is required for missing-command installation.
RUN require bash
ret_val=$?
copy_stderr_to stderr_output

EXPECT_TO_BE_EQUAL "1" "$ret_val" "The return value should be '1' when the YAML file argument is missing."
EXPECT_TO_BE_EQUAL "ERROR: require expects a command name and a YAML file." "$stderr_output" "The error message should explain that both arguments are required."

ENDTEST

# ==============================================================================

DESCRIBE "The require command returns 1 when the YAML file argument is empty."

# Run the require command with a valid command name but no YAML file path.
RUN require bash ""
ret_val=$?
copy_stderr_to stderr_output

EXPECT_TO_BE_EQUAL "1" "$ret_val" "The return value should be '1' when the YAML file argument is empty."
EXPECT_TO_BE_EQUAL "ERROR: require expects a command name and a YAML file." "$stderr_output" "The error message should explain that both arguments are required."

ENDTEST

# ==============================================================================

DESCRIBE "The require command returns 1 when the YAML file path does not exist."

# Run the require command with a YAML path that does not exist.
RUN require bash "$TMP_DIR/missing-require.yaml"
ret_val=$?
copy_stderr_to stderr_output

EXPECT_TO_BE_EQUAL "1" "$ret_val" "The return value should be '1' when the YAML file path does not exist."
EXPECT_TO_BE_EQUAL "ERROR: unable to read YAML file: $TMP_DIR/missing-require.yaml" "$stderr_output" "The error message should mention the missing YAML file path."

ENDTEST

# ==============================================================================

DESCRIBE "The require command returns 1 when too many arguments are provided."

# Run the require command with an extra positional argument. The command should
# fail because it only accepts a command name and a YAML file path.
RUN require bash "$RES/require.yaml" extra
ret_val=$?
copy_stderr_to stderr_output

EXPECT_TO_BE_EQUAL "1" "$ret_val" "The return value should be '1' when too many arguments are provided."
EXPECT_TO_BE_EQUAL "ERROR: require expects a command name and a YAML file." "$stderr_output" "The error message should explain that only two arguments are allowed."

ENDTEST

# ==============================================================================
