#!/bin/bash

# Get current scripts absolute path
CURRENT_SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The "lib" folders relative path
LIB="$CURRENT_SCRIPT_PATH/../lib"


# Import library scripts
source "$LIB/unit_test.sh"
source "$LIB/yaml_parser.sh"

# ------------------------------------------------------------------------------
# Cleanup
# ------------------------------------------------------------------------------

function cleanup() {
	cleanup_test_env
}

trap 'cleanup' EXIT

# ------------------------------------------------------------------------------
# Test cases
# ------------------------------------------------------------------------------

DESCRIBE "If no input file argument is given, then return error code 1"

RUN parse_yaml
ret_val=$?
expected=1
EXPECT_TO_BE_EQUAL "$expected" "$ret_val" "The method did not return: $expected."
copy_stderr_to output
expected="Error: Missing input file."
EXPECT_TO_BE_EQUAL "$expected" "$output" "The standard error is expected to be '$expected'."
log_variable ret_val

ENDTEST

# ==============================================================================

DESCRIBE "If more than 2 arguments are passed, then return error code 2"

RUN parse_yaml "arg1" "arg2" "arg3"
ret_val=$?
expected=2
EXPECT_TO_BE_EQUAL "$expected" "$ret_val" "The method did not return: $expected."
copy_stderr_to output
expected="Error: Too many arguments."
EXPECT_TO_BE_EQUAL "$expected" "$output" "The standard error is expected to be '$expected'."
log_variable ret_val

ENDTEST

# ==============================================================================

DESCRIBE "If the input file does not exist, then return error code 3"

RUN parse_yaml "non_existing_file.yaml"
ret_val=$?
expected=3
EXPECT_TO_BE_EQUAL "$expected" "$ret_val" "The method did not return: $expected."
copy_stderr_to output
expected="Error: Input file 'non_existing_file.yaml' does not exist."
EXPECT_TO_BE_EQUAL "$expected" "$output" "The standard error is expected to be '$expected'."
log_variable ret_val

ENDTEST

# ==============================================================================

DESCRIBE "If a valid input file is given without an output variable name, then return error code 4"

RUN parse_yaml "../res/disks.yaml"
ret_val=$?
expected=4
EXPECT_TO_BE_EQUAL "$expected" "$ret_val" "The method did not return: $expected."
copy_stderr_to output
expected="Error: Missing output associative array variable name."
EXPECT_TO_BE_EQUAL "$expected" "$output" "The standard error is expected to be '$expected'."
log_variable ret_val

ENDTEST

# ==============================================================================

DESCRIBE "If the output variable does not exist, then return error code 5"

RUN parse_yaml "../res/disks.yaml" non_existing_var
ret_val=$?
expected=5
EXPECT_TO_BE_EQUAL "$expected" "$ret_val" "The method did not return: $expected."
copy_stderr_to output
expected="Error: The output variable 'non_existing_var' does not exist."
EXPECT_TO_BE_EQUAL "$expected" "$output" "The standard error is expected to be '$expected'."
log_variable ret_val

ENDTEST

# ===============================================================================

DESCRIBE "If the output variable exists but is not an associative array, then return error code 5"

incorrect_type_var="I am a string variable"
RUN parse_yaml "../res/disks.yaml" incorrect_type_var
ret_val=$?
expected=5
EXPECT_TO_BE_EQUAL "$expected" "$ret_val" "The method did not return: $expected."
copy_stderr_to output
expected="Error: The output variable 'incorrect_type_var' is not an associative array."
EXPECT_TO_BE_EQUAL "$expected" "$output" "The standard error is expected to be '$expected'."
log_variable ret_val
unit_test_log_outputs

declare -A associative_array_var
RUN parse_yaml "../res/disks.yaml" associative_array_var
ret_val=$?
expected=0
EXPECT_TO_BE_EQUAL "$expected" "$ret_val" "The method did not return: $expected."
log_variable associative_array_var
unset associative_array_var

ENDTEST 

# ==============================================================================

DESCRIBE "It should correctly parse res/disks.yaml into an associative array"

declare -A disks_map
RUN parse_yaml "../res/disks.yaml" disks_map
ret_val=$?
expected=0
EXPECT_TO_BE_EQUAL "$expected" "$ret_val" "The method did not return: $expected."

expected=27
actual=${#disks_map[@]}
EXPECT_TO_BE_EQUAL "$expected" "$actual" "The parsed associative array does not contain the expected number of entries."

EXPECT_TO_BE_EQUAL "1" "${disks_map['disks.length']}" "The parsed disks length is incorrect."
EXPECT_TO_BE_EQUAL "/dev/sda" "${disks_map['disks[0].device']}" "The parsed device value is incorrect."
EXPECT_TO_BE_EQUAL "gpt" "${disks_map['disks[0].table']}" "The parsed table value is incorrect."
EXPECT_TO_BE_EQUAL "true" "${disks_map['disks[0].wipe']}" "The parsed wipe value is incorrect."
EXPECT_TO_BE_EQUAL "3" "${disks_map['disks[0].partitions.length']}" "The parsed partitions length is incorrect."
EXPECT_TO_BE_EQUAL "EFI" "${disks_map['disks[0].partitions[0].name']}" "The parsed EFI partition name is incorrect."
EXPECT_TO_BE_EQUAL "512M" "${disks_map['disks[0].partitions[0].size']}" "The parsed EFI partition size is incorrect."
EXPECT_TO_BE_EQUAL "EFI System" "${disks_map['disks[0].partitions[0].type']}" "The parsed EFI partition type is incorrect."
EXPECT_TO_BE_EQUAL "vfat" "${disks_map['disks[0].partitions[0].filesystem']}" "The parsed EFI partition filesystem is incorrect."
EXPECT_TO_BE_EQUAL "EFI" "${disks_map['disks[0].partitions[0].label']}" "The parsed EFI partition label is incorrect."
EXPECT_TO_BE_EQUAL "/boot/efi" "${disks_map['disks[0].partitions[0].mount_point']}" "The parsed EFI partition mount point is incorrect."
EXPECT_TO_BE_EQUAL "root" "${disks_map['disks[0].partitions[1].name']}" "The parsed root partition name is incorrect."
EXPECT_TO_BE_EQUAL "50G" "${disks_map['disks[0].partitions[1].size']}" "The parsed root partition size is incorrect."
EXPECT_TO_BE_EQUAL "Linux filesystem" "${disks_map['disks[0].partitions[1].type']}" "The parsed root partition type is incorrect."
EXPECT_TO_BE_EQUAL "luks" "${disks_map['disks[0].partitions[1].encryption.type']}" "The parsed root partition encryption type is incorrect."
EXPECT_TO_BE_EQUAL "cryptroot" "${disks_map['disks[0].partitions[1].encryption.mapping']}" "The parsed root partition encryption mapping is incorrect."
EXPECT_TO_BE_EQUAL "ext4" "${disks_map['disks[0].partitions[1].filesystem']}" "The parsed root partition filesystem is incorrect."
EXPECT_TO_BE_EQUAL "ROOT" "${disks_map['disks[0].partitions[1].label']}" "The parsed root partition label is incorrect."
EXPECT_TO_BE_EQUAL "/" "${disks_map['disks[0].partitions[1].mount_point']}" "The parsed root partition mount point is incorrect."
EXPECT_TO_BE_EQUAL "home" "${disks_map['disks[0].partitions[2].name']}" "The parsed home partition name is incorrect."
EXPECT_TO_BE_EQUAL "rest" "${disks_map['disks[0].partitions[2].size']}" "The parsed home partition size is incorrect."
EXPECT_TO_BE_EQUAL "Linux filesystem" "${disks_map['disks[0].partitions[2].type']}" "The parsed home partition type is incorrect."
EXPECT_TO_BE_EQUAL "luks" "${disks_map['disks[0].partitions[2].encryption.type']}" "The parsed home partition encryption type is incorrect."
EXPECT_TO_BE_EQUAL "crypthome" "${disks_map['disks[0].partitions[2].encryption.mapping']}" "The parsed home partition encryption mapping is incorrect."
EXPECT_TO_BE_EQUAL "ext4" "${disks_map['disks[0].partitions[2].filesystem']}" "The parsed home partition filesystem is incorrect."
EXPECT_TO_BE_EQUAL "HOME" "${disks_map['disks[0].partitions[2].label']}" "The parsed home partition label is incorrect."
EXPECT_TO_BE_EQUAL "/home" "${disks_map['disks[0].partitions[2].mount_point']}" "The parsed home partition mount point is incorrect."

unset disks_map

ENDTEST

# ===============================================================================
