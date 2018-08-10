#!/usr/bin/env bash

is_sclib_imported 2> /dev/null ||
    SCLIB_PATH="/tmp/sclib.sh"
    SCLIB_GIT_RAW_URL="https://raw.githubusercontent.com/rajalokan/cloud-installer/master/scripts/sclib.sh"
    if [[ ! -f ${SCLIB_PATH} ]]; then
        wget ${SCLIB_GIT_RAW_URL} -O ${SCLIB_PATH}
    fi
    source ${SCLIB_PATH}

info_block "Preconfiguring Bootstraping dotfiles"

dotfiles_temp_path="/tmp/okanstack/"
dotfiles_repo="https://github.com/rajalokan/okanstack"
if [[ ! -d ${dotfiles_temp_path} ]]; then
    git clone ${dotfiles_repo} ${dotfiles_temp_path}
fi

# Install ansible
is_package_installed git || install_package git

pushd ${dotfiles_temp_path}/ansible/ >/dev/null
    ansible-playbook -i "localhost," -c local playbook.yaml
popd
