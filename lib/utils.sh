#!/bin/bash
#
# A library of util functions.

# Convert string from kebab case to snake case.
utils::kebab_to_snake() {
  echo $1 | sed s/-/_/
}

# Get the current date and time expressed according to ISO 8601.
utils::timestamp() {
  date +"%Y-%m-%dT%H:%M:%S"
}

# Convert a number of seconds to the ISO 8601 standard.
utils::secs_to_iso_8601() {
  printf "%dh:%dm:%ds" $(($1 / 3600)) $(($1 % 3600 / 60)) $(($1 % 60))
}
