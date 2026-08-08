#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# Bash command requirement helper.
#
# Provides a require function that verifies whether a Bash command is available
# in PATH. If the command is missing, the function reads distro-aware package
# metadata from YAML and tries to install the matching package before failing.
# ------------------------------------------------------------------------------

# Prevent multiple sourcing
if [[ -n "${REQUIRE_LOADED:-}" ]]; then
	# Return instead of exit to avoid terminating the calling script.
	return 0
fi

readonly REQUIRE_LOADED=true

# ------------------------------------------------------------------------------
# Import dependencies
# ------------------------------------------------------------------------------

# Get current scripts absolute path
CURRENT_SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The "lib" folders relative path
LIB="$CURRENT_SCRIPT_PATH"

source "$LIB/distro.sh"
source "$LIB/yaml_parser.sh"

# ------------------------------------------------------------------------------
# Internal API: Functions intended for internal use
# ------------------------------------------------------------------------------

# Reads the distro-specific install command from the YAML metadata.
function get_command() {
	local -n metadataRef="$1"
	local distroName="$2"
	local key="package_manager.${distroName}.install"

	printf '%s\n' "${metadataRef[$key]:-}"
}

# Reads the distro-specific package name for a command from the YAML metadata.
function get_package() {
	local -n metadataRef="$1"
	local distroName="$2"
	local commandName="$3"
	local package_key="package_manager.${distroName}.app.${commandName}"

	printf '%s\n' "${metadataRef[$package_key]:-$commandName}"
}

# Reads the distro-specific install script for a command from the YAML metadata.
function get_install_script() {
	local -n metadataRef="$1"
	local distroName="$2"
	local commandName="$3"
	local script_key="package_manager.${distroName}.app.${commandName}.script"

	printf '%s\n' "${metadataRef[$script_key]:-}"
}

# Resolves a possibly relative script path against the YAML file directory.
function resolve_script_path() {
	local yamlFile="$1"
	local scriptPath="$2"

	if [[ "$scriptPath" = /* ]]; then
		printf '%s\n' "$scriptPath"
		return 0
	fi

	local yamlDir="${yamlFile%/*}"
	[[ -n "$yamlDir" ]] || yamlDir="."
	yamlDir="$(cd "$yamlDir" && pwd)"
	printf '%s/%s\n' "$yamlDir" "$scriptPath"
}

# Tries to install a missing command using distro-aware package metadata.
function install_missing_command() {
	local commandName="$1"
	local yaml_file="$2"

	local -A packageMetadata=()
	local -a installCmdAndArgs=()

    # Check if the YAML file is provided when a command is missing
	if [[ -z "$yaml_file" ]]; then
		echo "ERROR: require needs a YAML file when a command is missing." >&2
		return 1
	fi

    # Determine the current Linux distribution using the distro function
	local distroName="$(distro)" || return 1

    # Check if the YAML file is readable before attempting to parse it
	if [[ ! -r "$yaml_file" ]]; then
		echo "ERROR: unable to read YAML file: $yaml_file" >&2
		return 1
	fi
	parse_yaml "$yaml_file" packageMetadata

    # Retrieve the package name for the given command and distribution from the parsed metadata
	local packageName="$(get_package packageMetadata "$distroName" "$commandName")"
	local installScript="$(get_install_script packageMetadata "$distroName" "$commandName")"

    # Retrieve the install command for the given command and distribution
	local installCommand="$(get_command packageMetadata "$distroName")"
	if [[ -z "$installCommand" ]]; then
		echo "ERROR: install command not found for distro: $distroName" >&2
		return 1
	fi

    # If a custom install script is defined then use it instead of the package manager.
	if [[ -n "$installScript" ]]; then
		local resolvedScript="$(resolve_script_path "$yaml_file" "$installScript")" || return 1

		if [[ ! -x "$resolvedScript" ]]; then
			echo "ERROR: install script is not executable: $resolvedScript" >&2
			return 1
		fi

		if ! REQUIRE_TARGET_COMMAND="$commandName" "$resolvedScript" "$commandName"; then
			echo "ERROR: failed to install package for command: $commandName" >&2
			return 1
		fi

		return 0
	fi

    # Split the install command into an array to handle commands with arguments.
	read -r -a installCmdAndArgs <<< "$installCommand"

    # Attempt to install the package for the missing command.
	if ! "${installCmdAndArgs[@]}" "$packageName"; then
		echo "ERROR: failed to install package for command: $commandName" >&2
		return 1
	fi

}

# ------------------------------------------------------------------------------
# Public API: Functions intended for external use
# ------------------------------------------------------------------------------

# Verifies that the given command can be resolved by Bash, installing it if needed.
function require() {
	local commandName="$1"
	local yaml_file="${2:-}"

	if [[ $# -ne 2 || -z "$commandName" || -z "$yaml_file" ]]; then
		echo "ERROR: require expects a command name and a YAML file." >&2
		return 1
	fi

	if [[ ! -r "$yaml_file" ]]; then
		echo "ERROR: unable to read YAML file: $yaml_file" >&2
		return 1
	fi

    # Verify if the command is already available in PATH
	if command -v -- "$commandName" >/dev/null 2>&1; then
		return 0
	fi

    # If the command is missing, attempt to install it using the provided YAML file
    install_missing_command "$commandName" "$yaml_file" || return 1

    # Verify again if the command is now available after installation
	if command -v -- "$commandName" >/dev/null 2>&1; then
		return 0
	fi

	echo "ERROR: required command not found after installation: $commandName" >&2
	return 1
}

# Execute the helper only when the file is run directly.
[[ "${BASH_SOURCE[0]}" == "$0" ]] && require "$@"
