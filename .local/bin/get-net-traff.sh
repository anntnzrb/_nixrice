#!/bin/sh

# get-net-traff.sh --- Get current network traffic
# Author: Luke Smith
# Tweaked by anntnzrb

# Shows how much data has been received (RX) or transmitted (TX) since the
# previous time this script ran. So if it's run every second, gives network
# traffic per second.

update() {
    # **
    # * Updates the received (RX) and transmitted (TX) data given a class
    # *

    # sum all the bytes
    sum=0
    for arg; do
        # shellcheck disable=2086
        # these are numbers, not strings
        read -r i < ${arg}
        sum=$(( sum + i ))

        unset -v arg
    done

    cache=/tmp/${1##*/}
    test -f "${cache}" && read -r old < "${cache}" || old=0
    printf "%d\\n" "${sum}" > "${cache}"
    printf "%d\\n" $(( sum - old ))

    # cleanup
    unset -v sum old cache
}

rx=$(update /sys/class/net/[ew]*/statistics/rx_bytes)
tx=$(update /sys/class/net/[ew]*/statistics/tx_bytes)

# shellcheck disable=2046
# shellcheck disable=2086
# these are numbers, not strings
printf "%4sB%4sB\\n" $(numfmt --to=iec ${rx}) $(numfmt --to=iec ${tx})
