#!/usr/bin/env bash

checkFileName() {
    if [ -z "$1" ]; then
        echo "The File Name Kan not Empty!"
        exit 1
    fi
}

checkFile() {
    if [ ! -f "$1" ];then
        read -p "the file does not exists; do you shure make the $1 file? [y|n]: " -a mk

        if [ "$mk" == 'y' ]; then
            "$2" "$1"
        fi
    fi
}
