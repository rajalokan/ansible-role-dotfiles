#!/usr/bin/env bash

DOTFILES_GIT_REPO="https://github.com/rajalokan/dotfiles.git"
DOTFILES_DIR="/tmp/dotfiles"


is_sclib_imported 2> /dev/null ||
    SCLIB_PATH="/tmp/sclib.sh"
    SCLIB_GIT_RAW_URL="https://raw.githubusercontent.com/rajalokan/cloud-installer/master/scripts/sclib.sh"
    if [[ ! -f ${SCLIB_PATH} ]]; then
        wget ${SCLIB_GIT_RAW_URL} -O ${SCLIB_PATH}
    fi
    source ${SCLIB_PATH}

info_block "Preconfiguring Bootstraping dotfiles"
_log "Upgrading system packages"
is_ubuntu \
    && { \
        sudo apt-get update; \
        sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade; \
    } \
    || sudo yum -y update

# Install git
is_package_installed git || install_package git

# clone dotfiles if not present
if [ ! -d ${DOTFILES_DIR} ]; then
    _log "Cloning dotfiles at ${DOTFILES_DIR}"
    git clone ${DOTFILES_GIT_REPO} ${DOTFILES_DIR}
fi


function setup_bash() {
    info_block "Setting up bash"
    backup_if_present ${HOME}/.bashrc
    is_ubuntu && backup_if_present ${HOME}/.profile || backup_if_present ${HOME}/.bash_profile
    backup_if_present ${HOME}/.bash_aliases
    GetOSVersion

    is_ubuntu \
        && { \
            cp "${DOTFILES_DIR}/files/bash/${os_VENDOR,,}/${os_RELEASE}/bashrc" "${HOME}/.bashrc"; \
            cp "${DOTFILES_DIR}/files/bash/${os_VENDOR,,}/${os_RELEASE}/profile" "${HOME}/.profile"; \
        } \
        || { \
            cp "${DOTFILES_DIR}/files/bash/${os_VENDOR,,}/bashrc" "${HOME}/.bashrc"; \
            cp "${DOTFILES_DIR}/files/bash/${os_VENDOR,,}/bash_profile" "${HOME}/.bash_profile"; }

    backup_if_present ${HOME}/.bashrc_okan \
        && cp "${DOTFILES_DIR}/files/bash/bashrc_okan" "${HOME}/.bashrc_okan"

    backup_if_present ${HOME}/.bash_aliases \
        && cp "${DOTFILES_DIR}/files/bash/bash_aliases" "${HOME}/.bash_aliases"

    _log "Successfully setup bash"
    _log "------------------------------------------------------------------------------------------------------------"
}

function setup_vim(){
    info_block "Setting up vim"
    is_ubuntu && VIM_PACKAGE_NAME="vim" || VIM_PACKAGE_NAME="vim-enhanced"
    is_package_installed ${VIM_PACKAGE_NAME} || install_package ${VIM_PACKAGE_NAME}

    backup_if_present ${HOME}/.vimrc \
        && cp "${DOTFILES_DIR}/files/vim/vimrc" "${HOME}/.vimrc"

    backup_if_present ${HOME}/.vim \
        && cp -r "${DOTFILES_DIR}/files/vim" "${HOME}/.vim"

    mkdir -p ${HOME}/.vim/bundle

    if [ ! -d ${HOME}/.vim/bundle/Vundle.vim ]; then
        git clone https://github.com/gmarik/Vundle.vim.git ${HOME}/.vim/bundle/Vundle.vim
    fi;

    vim +PluginInstall +qall > /dev/null
    echo $'\n' > /dev/null

    if [ -d ${HOME}/.vim/vim ]; then
        rm -rf ${HOME}/.vim/vim; \
    fi;

    _log "Successfully installed and setup vim"
    _log "------------------------------------------------------------------------------------------------------------"
}

function setup_git(){
    info_block "Setting up git"

    is_package_installed git || install_package git

    backup_if_present ${HOME}/.gitconfig \
        && cp ${DOTFILES_DIR}/files/git/gitconfig ${HOME}/.gitconfig

    backup_if_present ${HOME}/.gitignore \
        && cp ${DOTFILES_DIR}/files/git/gitignore ${HOME}/.gitignore

    _log "Successfully installed and setup git"
    _log "------------------------------------------------------------------------------------------------------------"
}

function setup_python(){
    info_block "Setting up python"

    is_package_installed curl || install_package curl

    if ! type "pip" > /dev/null 2>&1; then
	    _log "Installing PiP"
        curl -kL https://bootstrap.pypa.io/get-pip.py | sudo -H python; \
    fi

    sudo -H pip install -U pip
    is_ubuntu && install_package python-dev || install_package python-devel

    pip freeze > ${HOME}/.pip_orig

    _log "Successfully installed and setup python"
    _log "------------------------------------------------------------------------------------------------------------"
}

function setup_tmux(){
    info_block "Setting up tmux"
    is_package_installed tmux || install_package tmux
    backup_if_present ${HOME}/.tmux.conf \
        && cp "${DOTFILES_DIR}/files/tmux/tmux.conf" "${HOME}/.tmux.conf"

    _log "Successfully installed and setup tmux"
    _log "------------------------------------------------------------------------------------------------------------"
}

setup_bash
setup_vim
setup_git
setup_python
setup_tmux

info_block "Bootstrap successful"
