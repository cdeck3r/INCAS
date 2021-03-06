#!/bin/bash

#
# Common functions to include in scripts
#
# Author: cdeck3r
#

#
# draws a horizontal line
#
# src:  https://wiki.bash-hackers.org/snipplets/print_horizontal_line#the_parameter_expansion_way
#
hr_old() {
    local start=$'\e(0' end=$'\e(B' line='qqqqqqqqqqqqqqqq'
    local cols=${COLUMNS:-$(tput cols)}
    ((cols -= 2)) # modified for use in tap's diag function
    while ((${#line} < cols)); do line+="$line"; done
    printf '%s%s%s\n' "$start" "${line:0:cols}" "$end"
}

#
# src: https://wiki.bash-hackers.org/snipplets/print_horizontal_line#a_line_across_the_entire_width_of_the_terminal
#
hr() {
    local cols=${COLUMNS:-$(tput cols)}
    ((cols -= 2)) # modified for use in tap's diag function
    printf '%*s\n' "${COLUMNS:-$cols}" '' | tr ' ' -
}

# requires tap-functions.sh
tool_check() {
    # check for required tools avail from shell
    TOOLS=('yq' 'tr' 'wc' 'date' 'uniq' 'watch' 'at' 'atq' 'atrm')
    for t in "${TOOLS[@]}"; do
        # check for installed program
        # Source: https://stackoverflow.com/a/677212
        command -v "${t}" >/dev/null 2>&1 || { BAIL_OUT "Tool not found: $t"; }
    done
    return 0
}

# tests for tools and pings the MQTT broker
precheck() {
    local skip_check=$1

    skip "${skip_check}" "No pre-check required" || {
        diag "${HR}"
        diag "Check pre-requisites"
        diag "${HR}"
        okx tool_check

        diag "${HR}"
        diag "${GREEN}[SUCCESS]${NC} - All fine."
        diag "${HR}"
        diag " "
    }
}
