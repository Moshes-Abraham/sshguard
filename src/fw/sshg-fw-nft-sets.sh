#!/bin/sh
# sshg-fw-nft-sets
# This file is part of SSHGuard.

CMD_NFT=nft

NFT_TABLE=sshguard
NFT_CHAIN=blacklist
NFT_SET=attackers

proto() {
    if [ "6" = "$1" ]; then
        echo ip6
    else
	echo ip
    fi
}

run_nft() {
    ${CMD_NFT} $1 $(proto $3) "${NFT_TABLE}" "$2" > /dev/null 2>&1
}

fw_init() {
    run_nft "add table" "" 4
    run_nft "add table" "" 6

    run_nft "add chain" "${NFT_CHAIN}"' { type filter hook input priority -10 ; }' 4
    run_nft "add chain" "${NFT_CHAIN}"' { type filter hook input priority -10 ; }' 6

    # Create sets
    run_nft "add set" "${NFT_SET} { type ipv4_addr; flags interval; }" 4
    run_nft "add set" "${NFT_SET} { type ipv6_addr; flags interval; }" 6

    # Rule to drop sets' IP
    run_nft "add rule" "${NFT_CHAIN} ip saddr @${NFT_SET} drop" 4
    run_nft "add rule" "${NFT_CHAIN} ip6 saddr @${NFT_SET} drop" 6
}

fw_block() {
    if [ $2 -eq 4 ]; then
        blocklist="$blocklist, $1/$3"
    else
        blocklist6="$blocklist6, $1/$3"
    fi
    if [ ! $batch_enabled ] || [ $(( $SECONDS - $lastblock )) -ge $window ]; then
        if [ "$blocklist" ]; then
            blocklist=${blocklist:2}
            run_nft "add element" "${NFT_SET} { $blocklist }" 4
            blocklist=''
        fi
        if [ "$blocklist6" ]; then
            blocklist6=${blocklist6:2}
            run_nft "add element" "${NFT_SET} { $blocklist6 }" 6
            blocklist6=''
        fi
        lastblock=$SECONDS
    fi
}

fw_release() {
    if [ $2 -eq 4 ]; then
        releaselist="$releaselist, $1/$3"
    else
        releaselist6="$releaselist6, $1/$3"
    fi
    if [ ! $batch_enabled ] || [ $(( $SECONDS - $lastrelease )) -ge $window ]; then
        if [ "$releaselist" ]; then
            releaselist=${releaselist:2}
            run_nft "delete element" "${NFT_SET} { $releaselist }" 4
            releaselist=''
        fi
        if [ "$releaselist6" ]; then
            releaselist6=${releaselist6:2}
            run_nft "delete element" "${NFT_SET} { $releaselist6 }" 6
            releaselist6=''
        fi
        lastrelease=$SECONDS
    fi
}

fw_flush() {
    fw_fin
    fw_init
}

fw_fin() {
    # Remove tables
    run_nft "delete table" "" 4
    run_nft "delete table" "" 6
}
