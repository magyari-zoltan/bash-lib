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
echo "The 'require.sh' script is located at: $CURRENT_SCRIPT_PATH"

# The "lib" folders relative path
LIB="$CURRENT_SCRIPT_PATH"

source "$LIB/distro.sh"
source "$LIB/logger.sh"
source "$LIB/yaml_parser.sh"

# ------------------------------------------------------------------------------
# Internal API: Functions intended for internal use
# ------------------------------------------------------------------------------

# Reads the distro-specific install command from the YAML metadata.
function get_command() {
	local -n metadataRef="$1"
	local distroName="$2"
	local key="package_manager.${distroName}.install"

	debug "Resolving install command for distro: $distroName"
	printf '%s\n' "${metadataRef[$key]:-}"
}

# Reads the distro-specific package name for a command from the YAML metadata.
function get_package() {
	local -n metadataRef="$1"
	local distroName="$2"
	local commandName="$3"
	local package_key="package_manager.${distroName}.app.${commandName}"

	debug "Resolving package name for command: $commandName on distro: $distroName"
	printf '%s\n' "${metadataRef[$package_key]:-$commandName}"
}

# Reads the distro-specific install script for a command from the YAML metadata.
function get_install_script() {
	local -n metadataRef="$1"
	local distroName="$2"
	local commandName="$3"
	local script_key="package_manager.${distroName}.app.${commandName}.script"

	debug "Resolving install script for command: $commandName on distro: $distroName"
	printf '%s\n' "${metadataRef[$script_key]:-}"
}

# Resolves a possibly relative script path against the YAML file directory.
function resolve_script_path() {
	local yamlFile="$1"
	local scriptPath="$2"

	debug "Resolving install script path: $scriptPath"

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

	info "Command not found, trying to install: $commandName"

	if [[ -z "$yaml_file" ]]; then
		error "require needs a YAML file when a command is missing."
		return 1
	fi

	debug "Detecting current Linux distribution"
	local distroName="$(distro)" || return 1

	if [[ ! -r "$yaml_file" ]]; then
		error "unable to read YAML file: $yaml_file"
		return 1
	fi
	info "Parsing package metadata from: $yaml_file"
	parse_yaml "$yaml_file" packageMetadata

	local packageName="$(get_package packageMetadata "$distroName" "$commandName")"
	local installScript="$(get_install_script packageMetadata "$distroName" "$commandName")"
	debug "Resolved package name: $packageName"
	debug "Resolved install script: ${installScript:-<none>}"

	local installCommand="$(get_command packageMetadata "$distroName")"
	if [[ -z "$installCommand" ]]; then
		error "install command not found for distro: $distroName"
		return 1
	fi
	debug "Resolved package manager command: $installCommand"

	if [[ -n "$installScript" ]]; then
		local resolvedScript="$(resolve_script_path "$yaml_file" "$installScript")" || return 1

		if [[ ! -x "$resolvedScript" ]]; then
			error "install script is not executable: $resolvedScript"
			return 1
		fi

		info "Running custom install script: $resolvedScript"
		if ! REQUIRE_TARGET_COMMAND="$commandName" "$resolvedScript" "$commandName"; then
			error "failed to install package for command: $commandName"
			return 1
		fi

		info "Installed command via custom script: $commandName"
		return 0
	fi

	read -r -a installCmdAndArgs <<< "$installCommand"
	debug "Split install command into ${#installCmdAndArgs[@]} parts"

	info "Running package manager for: $packageName"
	if ! "${installCmdAndArgs[@]}" "$packageName"; then
		error "failed to install package for command: $commandName"
		return 1
	fi

	info "Installed command via package manager: $commandName"
}

# ------------------------------------------------------------------------------
# Public API: Functions intended for external use
# ------------------------------------------------------------------------------

# Verifies that the given command can be resolved by Bash, installing it if needed.
function require() {
	local commandName="$1"
	local yaml_file="${2:-}"

	debug "Validating require arguments for: $commandName"
	if [[ $# -ne 2 || -z "$commandName" || -z "$yaml_file" ]]; then
		error "require expects a command name and a YAML file."
		return 1
	fi

	if [[ ! -r "$yaml_file" ]]; then
		error "unable to read YAML file: $yaml_file"
		return 1
	fi

	info "Checking availability of command: $commandName"
	if command -v -- "$commandName" >/dev/null 2>&1; then
		info "Command already available: $commandName"
		return 0
	fi

	debug "Command is missing: $commandName"
	install_missing_command "$commandName" "$yaml_file" || return 1

	if command -v -- "$commandName" >/dev/null 2>&1; then
		info "Command became available after installation: $commandName"
		return 0
	fi

	error "required command not found after installation: $commandName"
	return 1
}
