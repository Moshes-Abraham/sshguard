#!/bin/sh
# sshg-fw-firewalld
# This file is part of SSHGuard.

FIREW_CMD="firewall-cmd --quiet"

fw_init() {
    ${FIREW_CMD} --query-rich-rule="rule family=ipv6 source ipset=sshguard6 drop" || {
      ${FIREW_CMD} --permanent --new-ipset="sshguard6" --type="hash:net" --option="family=inet6"
      ${FIREW_CMD} --permanent --add-rich-rule="rule family=ipv6 source ipset=sshguard6 drop"
    }
    ${FIREW_CMD} --query-rich-rule="rule family=ipv4 source ipset=sshguard4 drop" || {
      ${FIREW_CMD} --permanent --new-ipset="sshguard4" --type="hash:net" --option="family=inet"
      ${FIREW_CMD} --permanent --add-rich-rule="rule family=ipv4 source ipset=sshguard4 drop"
    }
    ${FIREW_CMD} --reload
}

fw_block() {
    # collect IPs in blocklist
    if [ $2 -eq 4 ]; then
        blocklist="$blocklist --add-entry=$1/$3"
    else
        blocklist6="$blocklist6 --add-entry=$1/$3"
    fi
    # flush blocklist to backend if batch mode is not enabled or $window seconds have elapsed
    if [ -z "$batch_enabled" ] || [ $(( $SECONDS - $lastblock )) -ge $window ]; then
        if [ -n "$blocklist" ]; then
            ${FIREW_CMD} --ipset="sshguard4" $blocklist
            blocklist=''
        fi
        if [ -n "$blocklist6" ]; then
            ${FIREW_CMD} --ipset="sshguard6" $blocklist6
            blocklist6=''
        fi
        lastblock=$SECONDS
    fi
}

fw_release() {
    # collect IPs in releaselist
    if [ $2 -eq 4 ]; then
        releaselist="$releaselist --add-entry=$1/$3"
    else
        releaselist6="$releaselist6 --add-entry=$1/$3"
    fi
    # flush releaselist to backend if batch mode is not enabled or $window seconds have elapsed
    if [ -z "$batch_enabled" ] || [ $(( $SECONDS - $lastrelease )) -ge $window ]; then
        if [ -n "$releaselist" ]; then
            ${FIREW_CMD} --ipset="sshguard4" $releaselist
            releaselist=''
        fi
        if [ -n "$releaselist6" ]; then
            ${FIREW_CMD} --ipset="sshguard6" $releaselist6
            releaselist6=''
        fi
        lastrelease=$SECONDS
    fi
}

fw_flush() {
    ${FIREW_CMD} --reload
}

fw_fin() {
    :
}
