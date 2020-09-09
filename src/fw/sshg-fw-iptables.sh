#!/bin/sh
# sshg-fw-iptables
# This file is part of SSHGuard.

run_iptables() {
    cmd=iptables
    if [ "6" = "$2" ]; then
        cmd=ip6tables
    fi

    # Check if iptables supports the '-w' flag.
    if $cmd -w -V >/dev/null 2>&1; then
        $cmd -w $1
    else
        $cmd $1
    fi
}

fw_init() {
    run_iptables "-L -n"
}

fw_block() {
    # collect IPs in blocklist
    if [ $2 -eq 4 ]; then
        blocklist="$blocklist,$1/$3"
    else
        blocklist6="$blocklist6,$1/$3"
    fi
    # flush blocklist to backend if batch mode is not enabled or $window seconds have elapsed
    if [ -z "$batch_enabled" ] || [ $(( $SECONDS - $lastblock )) -ge $window ]; then
        if [ -n "$blocklist" ]; then
            blocklist=${blocklist#,}
            run_iptables "-I sshguard -s $blocklist -j DROP" 4
            blocklist=''
        fi
        if [ -n "$blocklist6" ]; then
            blocklist6=${blocklist6#,}
            run_iptables "-I sshguard -s $blocklist6 -j DROP" 6
            blocklist6=''
        fi
        lastblock=$SECONDS
    fi
}

fw_release() {
    # collect IPs in releaselist
    if [ $2 -eq 4 ]; then
        releaselist="$releaselist,$1/$3"
    else
        releaselist6="$releaselist6,$1/$3"
    fi
    # flush releaselist to backend if batch mode is not enabled or $window seconds have elapsed
    if [ -z "$batch_enabled" ] || [ $(( $SECONDS - $lastrelease )) -ge $window ]; then
        if [ -n "$releaselist" ]; then
            releaselist=${releaselist#,}
            run_iptables "-D sshguard -s $releaselist -j DROP" 4
            releaselist=''
        fi
        if [ -n "$releaselist6" ]; then
            releaselist6=${releaselist6#,}
            run_iptables "-D sshguard -s $releaselist6 -j DROP" 6
            releaselist6=''
        fi
        lastrelease=$SECONDS
    fi
}

fw_flush() {
    run_iptables "-F sshguard" 4
    run_iptables "-F sshguard" 6
}

fw_fin() {
    :
}
