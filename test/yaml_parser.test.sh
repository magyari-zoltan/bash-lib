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
# Globbal variables
# ------------------------------------------------------------------------------

declare -a key_stack
declare -A map=()

# ------------------------------------------------------------------------------
# Test cases
# ------------------------------------------------------------------------------

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

# ==============================================================================

DESCRIBE "The 'parse_line' parses a 'numeric' from the line and pushes it into the map."

stack=("nr")
map=()

log_variable stack
log_variable map
RUN parse_line 42 stack map
log_variable stack
log_variable map

expected="declare -A map=([nr]=\"42\" [nr:type]=\"number\" )"
EXPECT_TO_BE_EQUAL "$expected" "$(declare -p map)" "The 'parse_line' parser did not create the expected map: $expected."


ENDTEST

# ==============================================================================

DESCRIBE "The 'parse_line' parses a 'boolean' from the line and pushes it into the map."

stack=("is_enabled")
map=()

log_variable stack
log_variable map
RUN parse_line true stack map
log_variable stack
log_variable map

expected="declare -A map=([is_enabled]=\"true\" [is_enabled:type]=\"boolean\" )"
EXPECT_TO_BE_EQUAL "$expected" "$(declare -p map)" "The 'parse_line' parser did not create the expected map: $expected."


ENDTEST

# ==============================================================================

DESCRIBE "The 'parse_line' parses a 'list of strings' from the line and pushes it into the map."

stack=("letters" "0")
map=()

log_variable stack
log_variable map
RUN parse_line " a,  b  , c" stack map
log_variable stack
log_variable map

expected="a"
EXPECT_TO_BE_EQUAL "$expected" "${map["letters[0]"]}" "The 'letters[0]' has not the expected value: $expected."
expected="string"
EXPECT_TO_BE_EQUAL "$expected" "${map["letters[0]:type"]}" "The 'letters[0]:type' has not the expected value: $expected."

expected="b"
EXPECT_TO_BE_EQUAL "$expected" "${map["letters[1]"]}" "The 'letters[1]' has not the expected value: $expected."
expected="string"
EXPECT_TO_BE_EQUAL "$expected" "${map["letters[1]:type"]}" "The 'letters[1]:type' has not the expected value: $expected."

expected="c"
EXPECT_TO_BE_EQUAL "$expected" "${map["letters[2]"]}" "The 'letters[2]' has not the expected value: $expected."
expected="string"
EXPECT_TO_BE_EQUAL "$expected" "${map["letters[2]:type"]}" "The 'letters[2]:type' has not the expected value: $expected."

ENDTEST

# ==============================================================================

DESCRIBE "The 'parse_line' parses a 'object' from the line and pushes it into the map."

object="car"
stack=()
map=()

log_variable stack
log_variable map
RUN parse_line "$object  :  " stack map
log_variable stack
log_variable map

expected="object"
EXPECT_TO_BE_EQUAL "$expected" "${map["$object:type"]}" "The '$object' does not have the the type: $expected."
expected="0"
EXPECT_TO_BE_EQUAL "$expected" "${map["$object:level"]}" "The '$object' obeject level does not equal to: $expected."

ENDTEST

# ==============================================================================

DESCRIBE "The 'parse_line' parses a second 'object' on the same level as the first one."

object1="engine"
object2="wheels"
stack=("$object1")
map=([$object1:type]="object" [$object1:level]="0" )

log_variable stack
log_variable map
RUN parse_line "$object2:" stack map
log_variable stack
log_variable map

expected="object"
EXPECT_TO_BE_EQUAL "$expected" "${map["$object2:type"]}" "The '$object2' does not have the the type: $expected."
expected="0"
EXPECT_TO_BE_EQUAL "$expected" "${map["$object2:level"]}" "The '$object2' object level does not equal to: $expected."

ENDTEST

# ==============================================================================

DESCRIBE "The 'parse_line' parses a second 'object' on higher level than the first one."

object1="car"
object2="engine"
stack=("$object1")
map=([$object1:type]="object" [$object1:level]="0" )

log_variable stack
log_variable map
RUN parse_line "  $object2:" stack map
log_variable stack
log_variable map

expected="object"
EXPECT_TO_BE_EQUAL "$expected" "${map["$object1.$object2:type"]}" "The '$object2' does not have the the type: $expected."
expected="2"
EXPECT_TO_BE_EQUAL "$expected" "${map["$object1.$object2:level"]}" "The '$object2' object level does not equal to: $expected."

ENDTEST

# ==============================================================================

DESCRIBE "The 'parse_line' parses a second 'object' on lover level than the first one."

object1="car"
object2="part"
object3="wheels"
object4="engine"
object5="door"
stack=("${object1}" "${object2}" "${object3}")
map=([${object1}:type]="object" [${object1}:level]="0" [${object1}.${object2}:type]="object" [${object1}.${object2}:level]="2" [${object1}.${object2}.${object3}:type]="object" [${object1}.${object2}.${object3}:level]="4" )

log_variable stack
log_variable map
RUN parse_line "  ${object4}:" stack map
log_variable stack
log_variable map

expected="object"
EXPECT_TO_BE_EQUAL "$expected" "${map[${object1}.${object4}:type]}" "The '$object4' does not have the the type: $expected."
expected="2"
EXPECT_TO_BE_EQUAL "$expected" "${map[${object1}.${object4}:level]}" "The '$object4' object level does not equal to: $expected."

stack=("${object1}" "${object2}" "${object3}")
map=([${object1}:type]="object" [${object1}:level]="0" [${object1}.${object2}:type]="object" [${object1}.${object2}:level]="2" [${object1}.${object2}.${object3}:type]="object" [${object1}.${object2}.${object3}:level]="4" )

log_variable stack
log_variable map
RUN parse_line "${object5}:" stack map
log_variable stack
log_variable map

expected="object"
EXPECT_TO_BE_EQUAL "$expected" "${map[${object5}:type]}" "The '$object5' does not have the the type: $expected."
expected="0"
EXPECT_TO_BE_EQUAL "$expected" "${map[${object5}:level]}" "The '$object5' object level does not equal to: $expected."

ENDTEST

# ==============================================================================

DESCRIBE "The 'parse_line' parses a 'property' from the line and pushes it into the map."

object1="car"
name="engine"
value="1.2"
stack=("$object1")
map=([$object1:type]="object" [$object1:level]="0" )

log_variable stack
log_variable map
RUN parse_line "  $name: $value" stack map
log_variable stack
log_variable map

expected="1.2"
EXPECT_TO_BE_EQUAL "$expected" "${map["$object1.$name"]}" "The '${name}' object value does not equal to: $expected."
expected="number"
EXPECT_TO_BE_EQUAL "$expected" "${map["$object1.$name:type"]}" "The '${name}' does not have the value: $expected."

ENDTEST

# ==============================================================================

DESCRIBE "The 'parse_line' parses a 'property' on the same level with the previous object from the line and pushes it into the map."

object1="car"
name="engine"
value="1.2"
stack=("$object1")
map=([$object1:type]="object" [$object1:level]="0" )

log_variable stack
log_variable map
RUN parse_line "$name: $value" stack map
log_variable stack
log_variable map

expected="1.2"
EXPECT_TO_BE_EQUAL "$expected" "${map["$name"]}" "The '${name}' object value does not equal to: $expected."
expected="number"
EXPECT_TO_BE_EQUAL "$expected" "${map["$name:type"]}" "The '${name}' does not have the value: $expected."

ENDTEST

# ==============================================================================

DESCRIBE "The 'parse_line' parses a 'property' on a lower level as the previous object from the line and pushes it into the map."

object1="car"
object2="engine"
name="type"
value="1.2"
stack=("$object1" "$object2")
map=([$object1:type]="object" [$object1:level]="0" [$object1.$object2:type]="object" [$object1.$object2:level]="2" )

log_variable stack
log_variable map
RUN parse_line "$name: $value" stack map
log_variable stack
log_variable map

expected="1.2"
EXPECT_TO_BE_EQUAL "$expected" "${map["$name"]}" "The '${name}' object value does not equal to: $expected."
expected="number"
EXPECT_TO_BE_EQUAL "$expected" "${map["$name:type"]}" "The '${name}' does not have the value: $expected."

ENDTEST

# ==============================================================================

DESCRIBE "The 'parse_line' parses an 'array' containing only '['."

name="cars"
stack=("garage" "building" "garage")
map=([garage:level]="0" [garage.building:level]="2" [garage.building.garage:level]="4" )

log_variable stack
log_variable map
RUN parse_line "  $name: [ " stack map
log_variable stack
log_variable map

expected="array"
EXPECT_TO_BE_EQUAL "$expected" "${map["garage.${name}:type"]}" "The '${name}' does not have the type: $expected."
expected="2"
EXPECT_TO_BE_EQUAL "$expected" "${map["garage.${name}:level"]}" "The '${name}' does not have the level: $expected."

expected="string"
EXPECT_TO_BE_EQUAL "$expected" "${map["garage.${name}[0]:type"]}" "The '${name}' does not have the type: $expected."
expected="2"
EXPECT_TO_BE_EQUAL "$expected" "${map["garage.${name}[0]:level"]}" "The '${name}' does not have the level: $expected."

ENDTEST

# ==============================================================================

DESCRIBE "The 'parse_line' parses an 'array' containing '[ value1, value2'."

name="cars"
stack=("garage" "building" "garage")
map=([garage:level]="0" [garage.building:level]="2" [garage.building.garage:level]="4" )

log_variable stack
log_variable map
RUN parse_line "  $name: [ value1, value2" stack map
log_variable stack
log_variable map

expected="array"
EXPECT_TO_BE_EQUAL "$expected" "${map["garage.${name}:type"]}" "The '${name}' does not have the type: $expected."
expected="2"
EXPECT_TO_BE_EQUAL "$expected" "${map["garage.${name}:level"]}" "The '${name}' does not have the level: $expected."

expected="string"
EXPECT_TO_BE_EQUAL "$expected" "${map["garage.${name}[0]:type"]}" "The '${name}[0]' does not have the type: $expected."
expected="2"
EXPECT_TO_BE_EQUAL "$expected" "${map["garage.${name}[0]:level"]}" "The '${name}[0]' does not have the level: $expected."
expected="value1"
EXPECT_TO_BE_EQUAL "$expected" "${map["garage.${name}[0]"]}" "The '${name}[0]' does not have the value: $expected."

expected="string"
EXPECT_TO_BE_EQUAL "$expected" "${map["garage.${name}[1]:type"]}" "The '${name}[1]' does not have the type: $expected."
expected="2"
EXPECT_TO_BE_EQUAL "$expected" "${map["garage.${name}[1]:level"]}" "The '${name}[1]' does not have the level: $expected."
expected="value2"
EXPECT_TO_BE_EQUAL "$expected" "${map["garage.${name}[1]"]}" "The '${name}[1]' does not have the value: $expected."

ENDTEST

# ==============================================================================

DESCRIBE "The 'parse_line' parses an 'array' containing '[ value1, value2]'."

name="cars"
stack=("garage" "building" "garage")
map=([garage:level]="0" [garage.building:level]="2" [garage.building.garage:level]="4" )

log_variable stack
log_variable map
RUN parse_line "  $name: [ value1, value2]" stack map
log_variable stack
log_variable map

expected="array"
EXPECT_TO_BE_EQUAL "$expected" "${map["garage.${name}:type"]}" "The '${name}' does not have the type: $expected."
expected="2"
EXPECT_TO_BE_EQUAL "$expected" "${map["garage.${name}:level"]}" "The '${name}' does not have the level: $expected."

expected="string"
EXPECT_TO_BE_EQUAL "$expected" "${map["garage.${name}[0]:type"]}" "The '${name}[0]' does not have the type: $expected."
expected="2"
EXPECT_TO_BE_EQUAL "$expected" "${map["garage.${name}[0]:level"]}" "The '${name}[0]' does not have the level: $expected."
expected="value1"
EXPECT_TO_BE_EQUAL "$expected" "${map["garage.${name}[0]"]}" "The '${name}[0]' does not have the value: $expected."

ENDTEST

# ==============================================================================

DESCRIBE "The 'parse_line' parses an 'array' containing ' value1, value2]'."

name="cars"
stack=("garage" "cars" "0")
map=([garage:level]="0" [garage.cars:level]="2" [garage.cars[0]:level]="2" ) 

log_variable stack
log_variable map
RUN parse_line "    value1, value2]" stack map
log_variable stack
log_variable map

expected="2"
EXPECT_TO_BE_EQUAL "$expected" "${map["garage.${name}:level"]}" "The '${name}' does not have the level: $expected."

expected="string"
EXPECT_TO_BE_EQUAL "$expected" "${map["garage.${name}[0]:type"]}" "The '${name}[0]' does not have the type: $expected."
expected="2"
EXPECT_TO_BE_EQUAL "$expected" "${map["garage.${name}[0]:level"]}" "The '${name}[0]' does not have the level: $expected."
expected="value1"
EXPECT_TO_BE_EQUAL "$expected" "${map["garage.${name}[0]"]}" "The '${name}[0]' does not have the value: $expected."

expected="string"
EXPECT_TO_BE_EQUAL "$expected" "${map["garage.${name}[1]:type"]}" "The '${name}[1]' does not have the type: $expected."
expected="2"
EXPECT_TO_BE_EQUAL "$expected" "${map["garage.${name}[1]:level"]}" "The '${name}[1]' does not have the level: $expected."
expected="value2"
EXPECT_TO_BE_EQUAL "$expected" "${map["garage.${name}[1]"]}" "The '${name}[1]' does not have the value: $expected."

ENDTEST

# ==============================================================================

DESCRIBE "The 'parse_line' parses an 'array item' '- value'."

name="cars"
car="toyota"
stack=("$name")
map=([$name:level]="0" [$name:type]="object" ) 

log_variable stack
log_variable map
RUN parse_line "  - toyota" stack map
log_variable stack
log_variable map

expected="0"
EXPECT_TO_BE_EQUAL "$expected" "${map["${name}:level"]}" "The '${name}' does not have the level: $expected."
expected="array"
EXPECT_TO_BE_EQUAL "$expected" "${map["${name}:type"]}" "The '${name}' does not have the type: $expected."

expected="string"
EXPECT_TO_BE_EQUAL "$expected" "${map["${name}[0]:type"]}" "The '${name}[0]' does not have the type: $expected."
expected="2"
EXPECT_TO_BE_EQUAL "$expected" "${map["${name}[0]:level"]}" "The '${name}[0]' does not have the level: $expected."
expected="$car"
EXPECT_TO_BE_EQUAL "$expected" "${map["${name}[0]"]}" "The '${name}[0]' does not have the value: $expected."

ENDTEST

# ==============================================================================

DESCRIBE "The 'parse_line' parses an 'array item' '- car: toyota'."

name="cars"
car="toyota"
stack=("$name")
map=([$name:level]="0" ) 

log_variable stack
log_variable map
RUN parse_line "  - car: toyota" stack map
log_variable stack
log_variable map

expected="0"
EXPECT_TO_BE_EQUAL "$expected" "${map["${name}:level"]}" "The '${name}' does not have the level: $expected."
expected="array"
EXPECT_TO_BE_EQUAL "$expected" "${map["${name}:type"]}" "The '${name}' does not have the type: $expected."

expected="index"
EXPECT_TO_BE_EQUAL "$expected" "${map["${name}[0]:type"]}" "The '${name}[0]' does not have the type: $expected."
expected="2"
EXPECT_TO_BE_EQUAL "$expected" "${map["${name}[0]:level"]}" "The '${name}[0]' does not have the level: $expected."

expected="$car"
EXPECT_TO_BE_EQUAL "$expected" "${map["${name}[0].car"]}" "The '${name}[0].car' does not have the value: $expected."
expected="string"
EXPECT_TO_BE_EQUAL "$expected" "${map["${name}[0].car:type"]}" "The '${name}[0].car' does not have the type: $expected."

ENDTEST

# ==============================================================================

DESCRIBE "Parse the 'res/disks.yaml' file."

declare -A map=() 

RUN parse_yaml "../res/disks.yaml" map
log_variable map

expected="array"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks:type]}" "The 'disks' entry should have type '$expected'."
expected="1"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks:length]}" "The 'disks' entry should have length '$expected'."

expected="index"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0]:type]}" "The 'disks[0]' entry should have type '$expected'."
expected="2"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0]:level]}" "The 'disks[0]' entry should have level '$expected'."

expected="/dev/sda"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].device]}" "The 'disks[0].device' value should be '$expected'."
expected="string"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].device:type]}" "The 'disks[0].device' type should be '$expected'."

expected="gpt"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].table]}" "The 'disks[0].table' value should be '$expected'."
expected="string"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].table:type]}" "The 'disks[0].table' type should be '$expected'."

expected="true"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].wipe]}" "The 'disks[0].wipe' value should be '$expected'."
expected="boolean"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].wipe:type]}" "The 'disks[0].wipe' type should be '$expected'."

expected="array"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions:type]}" "The 'disks[0].partitions' entry should have type '$expected'."
expected="3"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions:length]}" "The 'disks[0].partitions' entry should have length '$expected'."

expected="index"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[0]:type]}" "The 'disks[0].partitions[0]' entry should have type '$expected'."
expected="6"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[0]:level]}" "The 'disks[0].partitions[0]' entry should have level '$expected'."
expected="string"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[0].name:type]}" "The 'disks[0].partitions[0].name' type should be '$expected'."
expected="512M"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[0].size]}" "The 'disks[0].partitions[0].size' value should be '$expected'."
expected="string"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[0].size:type]}" "The 'disks[0].partitions[0].size' type should be '$expected'."
expected="EFI System"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[0].type]}" "The 'disks[0].partitions[0].type' value should be '$expected'."
expected="string"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[0].type:type]}" "The 'disks[0].partitions[0].type' type should be '$expected'."
expected="vfat"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[0].filesystem]}" "The 'disks[0].partitions[0].filesystem' value should be '$expected'."
expected="string"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[0].filesystem:type]}" "The 'disks[0].partitions[0].filesystem' type should be '$expected'."
expected="EFI"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[0].label]}" "The 'disks[0].partitions[0].label' value should be '$expected'."
expected="string"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[0].label:type]}" "The 'disks[0].partitions[0].label' type should be '$expected'."
expected="/boot/efi"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[0].mount_point]}" "The 'disks[0].partitions[0].mount_point' value should be '$expected'."
expected="string"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[0].mount_point:type]}" "The 'disks[0].partitions[0].mount_point' type should be '$expected'."

expected="index"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[1]:type]}" "The 'disks[0].partitions[1]' entry should have type '$expected'."
expected="6"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[1]:level]}" "The 'disks[0].partitions[1]' entry should have level '$expected'."
expected="string"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[1].name:type]}" "The 'disks[0].partitions[1].name' type should be '$expected'."
expected="50G"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[1].size]}" "The 'disks[0].partitions[1].size' value should be '$expected'."
expected="string"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[1].size:type]}" "The 'disks[0].partitions[1].size' type should be '$expected'."
expected="Linux filesystem"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[1].type]}" "The 'disks[0].partitions[1].type' value should be '$expected'."
expected="string"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[1].type:type]}" "The 'disks[0].partitions[1].type' type should be '$expected'."
expected="object"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[1].encryption:type]}" "The 'disks[0].partitions[1].encryption' entry should have type '$expected'."
expected="8"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[1].encryption:level]}" "The 'disks[0].partitions[1].encryption' entry should have level '$expected'."
expected="luks"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[1].encryption.type]}" "The 'disks[0].partitions[1].encryption.type' value should be '$expected'."
expected="string"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[1].encryption.type:type]}" "The 'disks[0].partitions[1].encryption.type' type should be '$expected'."
expected="cryptroot"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[1].encryption.mapping]}" "The 'disks[0].partitions[1].encryption.mapping' value should be '$expected'."
expected="string"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[1].encryption.mapping:type]}" "The 'disks[0].partitions[1].encryption.mapping' type should be '$expected'."
expected="ext4"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[1].filesystem]}" "The 'disks[0].partitions[1].filesystem' value should be '$expected'."
expected="string"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[1].filesystem:type]}" "The 'disks[0].partitions[1].filesystem' type should be '$expected'."
expected="ROOT"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[1].label]}" "The 'disks[0].partitions[1].label' value should be '$expected'."
expected="string"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[1].label:type]}" "The 'disks[0].partitions[1].label' type should be '$expected'."
expected="/"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[1].mount_point]}" "The 'disks[0].partitions[1].mount_point' value should be '$expected'."
expected="string"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[1].mount_point:type]}" "The 'disks[0].partitions[1].mount_point' type should be '$expected'."

expected="index"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[2]:type]}" "The 'disks[0].partitions[2]' entry should have type '$expected'."
expected="6"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[2]:level]}" "The 'disks[0].partitions[2]' entry should have level '$expected'."
expected="string"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[2].name:type]}" "The 'disks[0].partitions[2].name' type should be '$expected'."
expected="rest"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[2].size]}" "The 'disks[0].partitions[2].size' value should be '$expected'."
expected="string"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[2].size:type]}" "The 'disks[0].partitions[2].size' type should be '$expected'."
expected="Linux filesystem"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[2].type]}" "The 'disks[0].partitions[2].type' value should be '$expected'."
expected="string"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[2].type:type]}" "The 'disks[0].partitions[2].type' type should be '$expected'."
expected="object"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[2].encryption:type]}" "The 'disks[0].partitions[2].encryption' entry should have type '$expected'."
expected="8"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[2].encryption:level]}" "The 'disks[0].partitions[2].encryption' entry should have level '$expected'."
expected="luks"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[2].encryption.type]}" "The 'disks[0].partitions[2].encryption.type' value should be '$expected'."
expected="string"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[2].encryption.type:type]}" "The 'disks[0].partitions[2].encryption.type' type should be '$expected'."
expected="crypthome"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[2].encryption.mapping]}" "The 'disks[0].partitions[2].encryption.mapping' value should be '$expected'."
expected="string"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[2].encryption.mapping:type]}" "The 'disks[0].partitions[2].encryption.mapping' type should be '$expected'."
expected="ext4"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[2].filesystem]}" "The 'disks[0].partitions[2].filesystem' value should be '$expected'."
expected="string"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[2].filesystem:type]}" "The 'disks[0].partitions[2].filesystem' type should be '$expected'."
expected="HOME"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[2].label]}" "The 'disks[0].partitions[2].label' value should be '$expected'."
expected="string"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[2].label:type]}" "The 'disks[0].partitions[2].label' type should be '$expected'."
expected="/home"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[2].mount_point]}" "The 'disks[0].partitions[2].mount_point' value should be '$expected'."
expected="string"
EXPECT_TO_BE_EQUAL "$expected" "${map[disks[0].partitions[2].mount_point:type]}" "The 'disks[0].partitions[2].mount_point' type should be '$expected'."

ENDTEST

# ==============================================================================

