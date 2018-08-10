#!/usr/bin/env bash

is_sclib_imported 2> /dev/null ||
    SCLIB_PATH="/tmp/sclib.sh"
    SCLIB_GIT_RAW_URL="https://raw.githubusercontent.com/rajalokan/cloud-installer/master/scripts/sclib.sh"
    if [[ ! -f ${SCLIB_PATH} ]]; then
        wget ${SCLIB_GIT_RAW_URL} -O ${SCLIB_PATH}
    fi
    source ${SCLIB_PATH}

info_block "Preconfiguring Bootstraping dotfiles"

ansible_roles_path="${HOME}/.ansible/roles"
mkdir -p ${ansible_roles_path}

dotfiles_path="${ansible_roles_path}/dotfiles"
dotfiles_repo="https://github.com/rajalokan/ansible-role-dotfiles"

# Ensure git is installed
is_package_installed git || install_package git

if [[ ! -d ${dotfiles_path} ]]; then
    git clone ${dotfiles_repo} ${dotfiles_path}
fi

# Ensure latest ansible is installed
is_package_installed ansible || info_block "ansible not installed. Exiting"

pushd ${dotfiles_path} >/dev/null
    ansible-playbook -i "localhost," -c local playbook.yaml
popd
