#!/usr/bin/env bash

# default config
read -rd '' config_def << 'EOF'
STEVENBLACK_URL="https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn/hosts"
CONFIG_DIR=/etc/host-gen
CONFIG=$CONFIG_DIR/config
HOST_ORIG=/etc/hosts
HOST_SRC_DIR=/etc/hosts.d
HOST_BAK_DIR=$HOST_SRC_DIR/backup
HOST_BAK=$HOST_BAK_DIR/hosts
HOST_NEW=$HOST_SRC_DIR/hosts.new
STEVENBLACK_SAVED=$HOST_SRC_DIR/01-stevenblack.hosts
STEVENBLACK_BAK=$HOST_BAK_DIR/01-stevenblack.hosts
EOF

main(){
    source <(echo "$config_def")
    if [[ -f $CONFIG ]]; then
        source $CONFIG
    else
        config_gen
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
    cleanup

}

config_gen(){
    mkdir -p $CONFIG_DIR
    echo "No config file found. Generating from default..."
    echo "$config_def" > $CONFIG
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