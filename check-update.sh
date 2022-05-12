#!/usr/bin/env bash

STEVENBLACK_URL="https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn/hosts"
CONFIG=$HOME/.config/host-gen/config
CONFIG_ALT=/etc/host-gen/config
HOST_ORIG=/etc/hosts
HOST_SRC_DIR=/etc/hosts.d
HOST_BAK_DIR=$HOST_SRC_DIR/backup
HOST_BAK=$HOST_BAK_DIR/hosts
HOST_NEW=$HOST_SRC_DIR/hosts.new
STEVENBLACK_SAVED=$HOST_SRC_DIR/01-stevenblack.hosts
STEVENBLACK_BAK=$HOST_BAK_DIR/01-stevenblack.hosts

main(){
    config_type=$(get_config_type)
    if [[ $config_type != "non-existent" ]]; then
        load_config $config_type
    fi
    mkdir -p $HOST_BAK_DIR
    cp $HOST_ORIG $HOST_BAK
    echo "Fetching StevenBlack hosts..."
    fetch_url
    if [[ $(hash_equal $STEVENBLACK_SAVED $STEVENBLACK_BAK) == "true" ]]; then
        echo "StevenBlack source is up to date."
    fi
    echo "Merging hosts..."
    merge_hosts
    if [[ $(hash_equal $HOST_NEW $HOST_BAK) == "true" ]]; then
        echo "Hosts are up to date."
    else
        echo "Hosts are out of date. Updating..."
        cp $HOST_NEW $HOST_ORIG
        echo "Hosts updated."
    fi

}

get_config_type(){
    if [[ -f $CONFIG ]]; then
        echo "user"
    elif [[ -f $CONFIG_ALT ]]; then
        echo "global"
    else
        echo "non-existent"
    fi
}

load_config(){
    if [[ $1 == "user" ]]; then
        source $CONFIG
    elif [[ $1 == "global" ]]; then
        source $CONFIG_ALT
    fi
}

fetch_url(){
    curl -s $STEVENBLACK_URL -o $STEVENBLACK_SAVED
}

hash_equal(){
    if [[ -f $1 ]] && [[ -f $2 ]]; then
        if [[ $(sha256sum $1 | cut -d ' ' -f 1) == $(sha256sum $2 | cut -d ' ' -f 1) ]]; then
            echo "true"
        else
            echo "false"
        fi
    fi
}

merge_hosts(){
    find $HOST_SRC_DIR -type f -name "[0-9][0-9]-*.hosts" -exec cat {} > $HOST_NEW \;
}

cleanup(){
    mv $STEVENBLACK_SAVED $STEVENBLACK_BAK
    rm $HOST_NEW
}

main "$@"