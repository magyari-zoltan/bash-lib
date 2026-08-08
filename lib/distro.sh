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
# Public API: Functions intended for external use
# ------------------------------------------------------------------------------

# Prints the Linux distribution identifier from an os-release file.
function distro() {
	local os_release_file="${1:-/etc/os-release}"
	local key
	local value

	if [[ ! -r "$os_release_file" ]]; then
		echo "ERROR: unable to read os-release file: $os_release_file" >&2
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

	echo "ERROR: distro ID not found in $os_release_file" >&2
	return 1
}

# Execute the helper only when the file is run directly.
[[ "${BASH_SOURCE[0]}" == "$0" ]] && distro "$@"
