#!/bin/sh
# sshg-fw-ipfw
# This file is part of SSHGuard.

IPFW_TABLE=22

fw_init() {
    # Starting in FreeBSD 11, tables must first be created.
    ipfw table ${IPFW_TABLE} create 2>/dev/null || \
        ipfw table ${IPFW_TABLE} list > /dev/null
}

fw_block() {
    # collect IPs in blocklist
    blocklist="$blocklist,$1/$3"
    # flush blocklist to backend if batch mode is not enabled or $window seconds have elapsed
    if [ -z "$batch_enabled" ] || [ $(( $SECONDS - $lastblock )) -ge $window ]; then
        blocklist=${blocklist#,}
        ipfw -q table ${IPFW_TABLE} add $blocklist
        blocklist=''
        lastblock=$SECONDS
    fi
}

fw_release() {
    # collect IPs in releaselist
    releaselist="$releaselist,$1/$3"
    # flush blocklist to backend if batch mode is not enabled or $window seconds have elapsed
    if [ -z "$batch_enabled" ] || [ $(( $SECONDS - $lastrelease )) -ge $window ]; then
        releaselist=${releaselist#,}
        ipfw -q table ${IPFW_TABLE} delete $releaselist
        releaselist=''
        lastrelease=$SECONDS
    fi
}

fw_flush() {
    ipfw table ${IPFW_TABLE} flush
}

fw_fin() {
    ipfw table ${IPFW_TABLE} destroy 2>/dev/null
}
