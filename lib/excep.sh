#!/bin/bash

#######################################
# Display an error message when the user input is invalid.
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
excep::err() {
  printf "$(basename $0): $1\n" >&2
}
