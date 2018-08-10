#!/usr/bin/env bash

if [[ $# < 1 ]]; then
    echo "Please pass a deployment type. Exiting Now.."
    exit 0
fi

TYPE=${1}

case ${TYPE} in
    'vagrant')
        echo "vagrant"
        ;;
    'cloud')
        echo "cloud"
        ;;
    'laptop')
        echo "laptop"
        ;;
    *)
        echo "Invalid entry"
        exit 0
        ;;
esac
