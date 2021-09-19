#!/bin/bash
set -e -u

#
# Discover IP Cameras using avahi
#
# Author: cdeck3r
#

# Params: none

# Exit codes
# 1 if pre-cond not fulfilled
# 2 if script breaks

# this directory is the script directory
SCRIPT_DIR="$(
    cd "$(dirname "$0")" || exit
    pwd -P
)"
cd "$SCRIPT_DIR" || exit
# shellcheck disable=SC2034
SCRIPT_NAME=$0

# variables

#####################################################
# Include Helper functions
#####################################################

# ..

#####################################################
# Main program
#####################################################

exit 0
