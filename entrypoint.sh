#!/bin/bash
#
# Preprocesses action inputs, before handing off to TrueSTUDIO's `headless.sh`
# to compile the project(s) specified.

# Enable extended pattern matching operators
shopt -s globstar extglob

# Normalises each path in an array of paths.
# Arguments:
#   Reference to the array of paths to normalise
function normalise {
  local -n array=$1
  count=${#array[@]}

  for ((i = 0; i < count; i++)); do
    array[i]=$(realpath ${array[i]})
  done
}

# Prepends each entry in a string array with another string, followed by a
# space.
# Arguments:
#   String to prepend each array entry with
#   Reference to the array to modify
function prepend_with {
  local -n array=$2
  count=${#array[@]}

  for ((i = 0; i < count; i++)); do
    array[i]="$1 ${array[i]}"
  done
}

read -a projects <<< $(echo $INPUT_PROJECT)

normalise projects
prepend_with "-import" projects

headless.sh -data /tmp/truestudio ${projects[@]} -build "$INPUT_BUILD"

