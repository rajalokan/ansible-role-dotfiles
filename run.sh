#!/bin/bash

#set -o xtrace

DIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)

source ${DIR}/functions-common

function backup_if_present(){
    if [ -L $1 ]; then
        echo "Deleting link $1"
        rm $1
    elif [[ -f $1 ]] || [[ -d $2 ]]; then
        echo "Backing up $1 to $1.bak.$(date +"%d_%m_%Y_%H%M%S")"
        mv $1 $1.bak.$(date +"%d_%m_%Y_%H%M%S")
    fi
}

function setup_bash() {
    backup_if_present ${HOME}/.bashrc
    is_ubuntu && backup_if_present ${HOME}/.profile || backup_if_present ${HOME}/.bash_profile
    backup_if_present ${HOME}/.bash_aliases
    GetOSVersion
    is_ubuntu && `ln -s ${DIR}/files/bash/${os_VENDOR}/${os_RELEASE}/bashrc ${HOME}/.bashrc; ln -s ${DIR}/files/bash/${os_VENDOR}/${os_RELEASE}/profile ${HOME}/.profile` || `ln -s ${DIR}/files/bash/${os_VENDOR}/${os_RELEASE}/bashrc ${HOME}/.bashrc; ln -s ${DIR}/files/bash/${os_VENDOR}/${os_RELEASE}/profile ${HOME}/.bash_profile`
    backup_if_present ${HOME}/.bashrc_okan && ln -s ${DIR}/files/bash/bashrc_okan ${HOME}/.bashrc_okan
    backup_if_present ${HOME}/.bash_aliases && ln -s ${DIR}/files/bash/bash_aliases ${HOME}/.bash_aliases
    . ${HOME}/.bashrc
    echo "Successfully setup bash"
    echo "*************************************************************"
}

function setup_vim(){
    is_package_installed vim || install_package vim

    backup_if_present ${HOME}/.vimrc
    backup_if_present ${HOME}/.vim

    ln -s ${DIR}/files/vim ${HOME}/.vim
    ln -s ${DIR}/files/vim/vimrc ${HOME}/.vimrc

    mkdir -p ${DIR}/files/vim/bundle
    if [ ! -d ${DIR}/files/vim/bundle/Vundle.vim ]; then
        git clone https://github.com/gmarik/Vundle.vim.git ${DIR}/files/vim/bundle/Vundle.vim
    fi;

    vim +PluginInstall +qall > /dev/null
    echo $'\n' > /dev/null

    if [ -d ${HOME}/.vim/.vim ]; then
        rm -rf ${HOME}/.vim/.vim; \
    fi;

    echo "Successfully installed and setup vim"
    echo "*************************************************************"
}

function setup_git(){
    is_package_installed git || install_package git

    backup_if_present ${HOME}/.gitconfig
    backup_if_present ${HOME}/.gitignore

    ln -s ${DIR}/files/git/gitconfig ${HOME}/.gitconfig
    ln -s ${DIR}/files/git/gitignore ${HOME}/.gitignore

    echo "Successfully installed and setup git"
    echo "*************************************************************"
}

function setup_python(){
    is_package_installed curl || install_package curl

    if ! type "pip" > /dev/null 2>&1; then
	echo "Installing PiP"
        curl -kL https://bootstrap.pypa.io/get-pip.py | sudo -H python; \
    fi

    sudo -H pip install -U pip
    is_ubuntu && install_package python-dev || install_package python-devel

    pip freeze > ${HOME}/.pip_orig

    pip install --user requests virtualenv
    #echo "Successfully installed and setup python"
    #echo "*************************************************************"
}

function setup_tmux(){
    is_package_installed tmux || install_package tmux
    backup_if_present ${HOME}/.tmux.conf && ln -s ${DIR}/files/tmux/tmux.conf ${HOME}/.tmux.conf

    echo "Successfully installed and setup tmux"
    echo "*************************************************************"
}

function setup_others() {
    is_ubuntu && setup_others_ubuntu || setup_others_fedora
}

function setup_others_ubuntu() {
    sudo apt-get -y update && sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade
    sudo apt-get -y install git mosh linux-image-generic-lts-utopic make htop libffi-dev libssl-dev
    pip install -U --user pip requests pyopenssl ndg-httpsclient pyasn1
}

function setup_others_fedora() {
    sudo yum -y update && sudo yum -y upgrade
    sudo yum groupinstall -y "Development Tools"
    sudo yum install -y mosh openssl-devel libffi-devel
    sudo -H pip install -U pip requests pyopenssl ndg-httpsclient pyasn1
}

setup_bash
setup_vim
setup_git
setup_python
setup_tmux
setup_others
