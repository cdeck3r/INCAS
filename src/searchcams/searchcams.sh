#!/bin/bash
set -e -u

#
# Search IP Cameras in the IP address range
# It outputs the IP address in dotted decimal format
# on the stdout for logging.
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
SCRIPT_NAME_WO_EXT=$(basename "${SCRIPT_NAME%.*}")

# common stuff
# shellcheck source=/INCAS/src/include/funcs.sh
source "${SCRIPT_DIR}/../include/funcs.sh"

# variables
MYIP=${1-}
MYNETMASK=${2-}
CONF="${SCRIPT_DIR}/../config.yml"
# TODO: use yq to parse config.yml
LOG_DIR=$(grep log_dir "${CONF}" | tr -d':' -f2 | xargs)
LOG_FILE="${LOG_DIR}/${SCRIPT_NAME_WO_EXT}.log"

#####################################################
# Include Helper functions
#####################################################

log_echo_file() {
    local level=$1
    local msg=$2

    log_echo "${level}" "${msg}" >>"${LOG_FILE}"
}

usage() {
    echo "Usage: ${SCRIPT_NAME} [IP address netmask]"
    echo " "
    echo "IP address in dotted decimal form"
    echo "netmask in dotted decimal"
}

checkParams() {
    local p1=$1
    local p2=$2

    if [[ ! -z "${p1}" ]]; then
        if [[ -z "${p2}" ]]; then
            echo "Missing parameter netmask"
            usage
            exit 1
        else
            # return params
            echo "${p1} ${p2}"
        fi
    fi
}

# Source: https://stackoverflow.com/a/10768196

# param: integer
dec2ip() {
    local ip dec=$1
    local delim=''
    for e in {3..0}; do
        ((octet = dec / (256 ** e)))
        ((dec -= octet * 256 ** e))
        ip+=$delim$octet
        delim=.
    done
    printf '%s\n' "$ip"
}

# Param: IP address in dotted decimal form
ip2dec() {
    local ip=$1
    local a b c d

    IFS=. read -r a b c d <<<"$ip"
    printf '%d' "$((a * 256 ** 3 + b * 256 ** 2 + c * 256 + d))"
}

# Return lowest and highest IP address in the network
#
# Params:
# IP address in dotted decimal form
# netmask  in dotted decimal form
calcNetworkIPs() {
    local ip=$1
    local netmask=$2
    #local network broadcast
    local firstIP lastIP

    # Source: https://stackoverflow.com/a/43878141
    IFS=. read -r i1 i2 i3 i4 <<<"$ip"
    IFS=. read -r m1 m2 m3 m4 <<<"$netmask"
    #network="$((i1 & m1)).$((i2 & m2)).$((i3 & m3)).$((i4 & m4))"
    #broadcast="$((i1 & m1 | 255 - m1)).$((i2 & m2 | 255 - m2)).$((i3 & m3 | 255 - m3)).$((i4 & m4 | 255 - m4))"
    firstIP="$((i1 & m1)).$((i2 & m2)).$((i3 & m3)).$(((i4 & m4) + 1))"
    lastIP="$((i1 & m1 | 255 - m1)).$((i2 & m2 | 255 - m2)).$((i3 & m3 | 255 - m3)).$(((i4 & m4 | 255 - m4) - 1))"

    echo "${firstIP}" "${lastIP}"
}

# Return IP and netmask
getIPNetmask() {
    # Source: https://stackoverflow.com/a/42082822
    ft_local=$(awk '$1=="Local:" {flag=1} flag' <<<"$(</proc/net/fib_trie)")
    for IF in /sys/class/net/*; do
        IF=$(basename "${IF}")
        networks=$(awk '$1=="'"$IF"'" && $3=="00000000" && $8!="FFFFFFFF" {printf $2 $8 "\n"}' <<<"$(</proc/net/route)")

        for net_hex in $networks; do
            net_dec=$(awk '{gsub(/../, "0x& "); printf "%d.%d.%d.%d\n", $4, $3, $2, $1}' <<<"${net_hex}")
            mask_dec=$(awk '{gsub(/../, "0x& "); printf "%d.%d.%d.%d\n", $8, $7, $6, $5}' <<<"${net_hex}")
            #awk '/'$net_dec'/{flag=1} /32 host/{flag=0} flag {a=$2} END {print "'$IF':\t" a "\n\t'$mask_dec'\n"}' <<< "$ft_local"
            # shellcheck disable=SC2086
            awk '/'$net_dec'/{flag=1} /32 host/{flag=0} flag {a=$2} END {print a " '$mask_dec'"}' <<<"$ft_local"
        done
    done
}

# Probe a given IP for an IP camera.
# Always returns successfully.
# Params:
# IP address in dotted decimal
probeIPC() {
    local IP=$1

    # Idea:
    # - connect to IP
    # - if successful (HTTP Code 200), test for snapshot
    C1_CMD=$(curl -s --connect-timeout 1 -I "http://${IP}" | head -n 1 | cut -d' ' -f2)

    [ ! -z "${C1_CMD}" ] && [ "${C1_CMD}" -eq 200 ] && {

        C2_CMD=$(curl -s --connect-timeout 1 -I "http://${IP}/cgi-bin/snapshot.cgi" | head -n 1 | cut -d' ' -f2)

        [ "${C2_CMD}" -eq 401 ] && {
            log_echo_file "INFO" "Potential IP camera found: ${IP}"
            echo "Potential IP camera found: ${IP}"
        }
    }
    return 0
}

#####################################################
# Main program
#####################################################

[[ -d "${LOG_DIR}" ]] || {
    log_echo_file "ERROR" "Directory expected to exist: ${LOG_DIR}"
    exit 1
}

if [[ ! -z "${MYIP}" ]] && [[ -z "${MYNETMASK}" ]]; then
    echo "Missing parameter netmask"
    usage
    exit 1
fi

ip_netmask_from_cli=$(checkParams "${MYIP}" "${MYNETMASK}")
if [[ -z "${ip_netmask_from_cli}" ]]; then
    log_echo_file "INFO" "No CLI params given. Detecting IP and netmask"
    read -r ip netmask < <(getIPNetmask)
else
    log_echo_file "INFO" "Take parameters from CLI"
    read -r ip netmask < <(printf '%s\n' "$ip_netmask_from_cli")
fi

log_echo_file "INFO" "IP: ${ip}"
log_echo_file "INFO" "Netmask: ${netmask}"
read -r firstIP lastIP < <(calcNetworkIPs "${ip}" "${netmask}")

firstIPdec=$(ip2dec "${firstIP}")
lastIPdec=$(ip2dec "${lastIP}")

log_echo_file "INFO" "Scan range...$((lastIPdec - firstIPdec + 1)) IP addresses"
log_echo_file "INFO" "From IP: ${firstIP}; To IP: ${lastIP}"

# loop through IP address range
for ((i = firstIPdec; i <= lastIPdec; i++)); do
    IP=$(dec2ip "${i}")
    num_ip=$((i - firstIPdec))
    every_tenth_ip=$((num_ip % 10))
    probeIPC "${IP}"
    if [[ "${every_tenth_ip}" -eq 0 ]]; then
        log_echo_file "INFO" "Tested ${num_ip} IPs. Current address: ${IP}"
    fi

done

((num_ip = i - firstIPdec))
log_echo_file "INFO" "Testing ${num_ip} IPs. Current address: ${IP}"

exit 0
