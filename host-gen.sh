#!/usr/bin/env bash

# default config
# read -rd '' config_def << 'EOF'
# STEVENBLACK_URL="https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn/hosts"
CONFIG_DIR=/etc/host-gen
CONFIG=$CONFIG_DIR/config
HOST_ORIG=/etc/hosts
HOST_SAVE_DIR=/etc/hosts.d
HOST_BAK_DIR=$HOST_SAVE_DIR/backup
HOST_BAK=$HOST_BAK_DIR/hosts
HOST_NEW=$HOST_SAVE_DIR/hosts.new
# STEVENBLACK_SAVED=$HOST_SAVE_DIR/01-stevenblack.hosts
# STEVENBLACK_BAK=$HOST_BAK_DIR/01-stevenblack.hosts
# EOF
declare -A SRC_BUILTIN
SRC_BUILTIN[name]="StevenBlack"
SRC_BUILTIN[url]="https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn/hosts"
SRC_BUILTIN[priority]=0

main() {
    source <(echo "$config_def")
    parse_opts "$@"
    mkdir -p "$HOST_BAK_DIR"
    cp "$HOST_ORIG" "$HOST_BAK"
    echo "Fetching StevenBlack hosts..."
    fetch_url
    if [[ $(hash_equal "$STEVENBLACK_SAVED" "$STEVENBLACK_BAK") == "true" ]]; then
        echo "StevenBlack source is up to date."
    fi
    echo "Merging hosts..."
    merge_hosts
    if [[ $(hash_equal "$HOST_NEW" "$HOST_BAK") == "true" ]]; then
        echo "Hosts are up to date."
    else
        echo "Hosts are out of date. Updating..."
        cp "$HOST_NEW" "$HOST_ORIG"
        echo "Hosts updated."
    fi
    cleanup

}

parse_opts() {
    # Check the commandline flags early for '--config|-c' and load it.
    [[ "$*" != *--config* && "$*" != *-c* ]] && config_check
    while [[ "$1" ]]; do
        case $1 in
        --config | -c)
            shift
            CONFIG=$1
            source "$CONFIG"
            ;;
        --custom_url | -u)
            shift
            STEVENBLACK_URL=$1
            ;;
        --host_output | -o)
            shift
            HOST_ORIG=$1
            ;;
        --host_save_dir | -s)
            shift
            HOST_SAVE_DIR=$1
            ;;
        --host_backup_dir | -b)
            shift
            HOST_BAK_DIR=$1
            ;;
        --help | --usage | -h)
            echo "Usage: $0 [--config|-c <config_file>] [--custom_url|-u <url>] [--host_output|-o <host_file>] [--host_src_dir|-s <host_src_dir>] [--host_backup_dir|-b <host_backup_dir>] [--help|--usage|-h]"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--config|-c <config_file>] [--custom_url|-u <url>] [--host_output|-o <host_file>] [--host_src_dir|-s <host_src_dir>] [--host_backup_dir|-b <host_backup_dir>] [--help|--usage|-h]"
            exit 1
            ;;
        esac
        shift
    done
}

# parse_config(){
#     # Parse a toml file into a bash associative array.
#     # Usage: parse_config <file> <array_name>
#     # Does NOT work, kept here if I ever get around to fixing it
#     local config_file=$1
#     local config_array=$2
#     if [[ -f $config_file ]]; then
#         declare -A "$config_array"
#         local key value line section
#         while read -r line; do
#             if [[ $line =~ ^\[.*\]$ ]]; then
#                 section=${line#\[}
#                 section=${section%\]}
#                 declare -A "$config_array"["$section"]
#             elif [[ $line =~ ^\s*# ]]; then
#                 continue
#             elif [[ $line =~ ^\s*$ ]]; then
#                 continue
#             else
#                 key=${line%% =*}
#                 value=${line#*= }
#                 eval "$config_array"["$section"]["$key"]="$value"
#             fi
#         done < "$config_file"
#     fi

# }

parse_config_yq() {
    # Parse a toml file using tomlq, a binary provided by the 'yq' package.
    local config_file=$1
    if [[ -f $config_file ]]; then
        if [[ -z $config_file ]]; then
            return 1
        else
            :
            if [[ $(tomlq ".global" "$config_file") != "null" ]]; then
                local line key val
                while read -r line; do
                    key=${line%% =*}
                    val=${line#*= }
                    if [[ $key =~ _DIR ]]; then
                        val=${line//\"/}
                    fi
                    eval "$key"="$val"
                done <"$(tomlq -t ".global" "$config_file")"
            fi
            if [[ $(tomlq ".src" "$config_file") != "null" ]]; then
                if [[ $(tomlq ".src.builtin" "$config_file") != "null" ]]; then
                    local line key val
                    while read -r line; do
                        key=${line%% =*}
                        val=${line#*= }
                        eval SRC_BUILTIN["$key"]="$val"
                    done <"$(tomlq -t ".src.builtin" "$config_file")"
                fi
                if [[ $(tomlq ".src.custom" "$config_file") != "null" ]]; then
                    local index_str
                    index_str=$(tomlq -t ".src.custom" "$config_file" | grep "\[[0-99]\]" | sed -e 's/\[//g' -e 's/\]//g')
                    for index in $index_str; do
                        if [[ $(tomlq ".src.custom.$index" "$config_file") != "null" ]]; then
                            local custom_arrayname
                            custom_arrayname="SRC_CUSTOM_$index"
                            declare -A "$custom_arrayname"
                            local line key val
                            while read -r line; do
                                key=${line%% =*}
                                val=${line#*= }
                                eval "$custom_arrayname"["$key"]="$val"
                            done <"$(tomlq -t "src.custom.$index" "$config_file")"
                        fi
                    done
                fi
            fi
        fi
    fi
}

config_check() {
    if [[ -f $CONFIG ]]; then
        source "$CONFIG"
    else
        mkdir -p "$CONFIG_DIR"
        echo "No config file found. Generating from default..."
        echo "$config_def" >"$CONFIG"
        echo "Config file generated."
    fi
}

fetch_url() {
    curl -s "$STEVENBLACK_URL" -o "$STEVENBLACK_SAVED"
}

hash_equal() {
    if [[ -f $1 ]] && [[ -f $2 ]]; then
        if [[ $(sha256sum "$1" | cut -d ' ' -f 1) == $(sha256sum "$2" | cut -d ' ' -f 1) ]]; then
            echo "true"
        else
            echo "false"
        fi
    fi
}

merge_hosts() {
    find "$HOST_SAVE_DIR" -type f -name "[0-9][0-9]-*.hosts" -exec sh -c 'cat $1 > $HOST_NEW' shell {} \;
}

cleanup() {
    mv "$STEVENBLACK_SAVED" "$STEVENBLACK_BAK"
    rm "$HOST_NEW"
}

main "$@"
