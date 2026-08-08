#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# Linux distribution helper.
#
# Provides a distro function that reads the Linux distribution identifier from
# an os-release file and prints it to stdout. The default source is
# /etc/os-release, but callers may pass an alternative file path for testing or
# other controlled environments.
# ------------------------------------------------------------------------------

# Prevent multiple sourcing
if [[ -n "${DISTRO_LOADED:-}" ]]; then
	# Return instead of exit to avoid terminating the calling script.
	return 0
fi

readonly DISTRO_LOADED=true

# ------------------------------------------------------------------------------
# Import dependencies
# ------------------------------------------------------------------------------

# Get current scripts absolute path
currentFilesPathIndex=$((${#BASH_SOURCE[@]} - 1))
CURRENT_SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[$currentFilesPathIndex]}")" && pwd)"
echo "The disro.sh script is located at: $CURRENT_SCRIPT_PATH"

# The "lib" folders relative path
LIB="$CURRENT_SCRIPT_PATH"

source "$CURRENT_SCRIPT_PATH/logger.sh"

# ------------------------------------------------------------------------------
# Public API: Functions intended for external use
# ------------------------------------------------------------------------------

# Prints the Linux distribution identifier from an os-release file.
function distro() {
	local os_release_file="${1:-/etc/os-release}"
	local key
	local value

	debug "Reading distro ID from: $os_release_file"

	if [[ ! -r "$os_release_file" ]]; then
		error "unable to read os-release file: $os_release_file"
		return 1
	fi

	while IFS='=' read -r key value; do
		[[ "$key" == "ID" ]] || continue

		value="${value%$'\r'}"
		value="${value#\"}"
		value="${value%\"}"

		if [[ -n "$value" ]]; then
			printf '%s\n' "$value"
			return 0
		fi
	done < "$os_release_file"

	error "distro ID not found in $os_release_file"
	return 1
}

# Execute the helper only when the file is run directly.
[[ "${BASH_SOURCE[0]}" == "$0" ]] && distro "$@"
