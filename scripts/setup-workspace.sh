#!/bin/bash


function GetanotherVersion {
    echo "Not Implemented"
}


# GetOSVersion
function GetOSVersion {

    # Figure out which vendor we are
    if [[ -x "`which sw_vers 2>/dev/null`" ]]; then
        # OS/X
        os_VENDOR=`sw_vers -productName`
        os_RELEASE=`sw_vers -productVersion`
        os_UPDATE=${os_RELEASE##*.}
        os_RELEASE=${os_RELEASE%.*}
        os_PACKAGE=""
        if [[ "$os_RELEASE" =~ "10.7" ]]; then
            os_CODENAME="lion"
        elif [[ "$os_RELEASE" =~ "10.6" ]]; then
            os_CODENAME="snow leopard"
        elif [[ "$os_RELEASE" =~ "10.5" ]]; then
            os_CODENAME="leopard"
        elif [[ "$os_RELEASE" =~ "10.4" ]]; then
            os_CODENAME="tiger"
        elif [[ "$os_RELEASE" =~ "10.3" ]]; then
            os_CODENAME="panther"
        else
            os_CODENAME=""
        fi
    elif [[ -x $(which lsb_release 2>/dev/null) ]]; then
        os_VENDOR=$(lsb_release -i -s)
        os_RELEASE=$(lsb_release -r -s)
        os_UPDATE=""
        os_PACKAGE="rpm"
        if [[ "Debian,Ubuntu,LinuxMint" =~ $os_VENDOR ]]; then
            os_PACKAGE="deb"
        elif [[ "SUSE LINUX" =~ $os_VENDOR ]]; then
            lsb_release -d -s | grep -q openSUSE
            if [[ $? -eq 0 ]]; then
                os_VENDOR="openSUSE"
            fi
        elif [[ $os_VENDOR == "openSUSE project" ]]; then
            os_VENDOR="openSUSE"
        elif [[ $os_VENDOR =~ Red.*Hat ]]; then
            os_VENDOR="Red Hat"
        fi
        os_CODENAME=$(lsb_release -c -s)
    elif [[ -r /etc/redhat-release ]]; then
        # Red Hat Enterprise Linux Server release 5.5 (Tikanga)
        # Red Hat Enterprise Linux Server release 7.0 Beta (Maipo)
        # CentOS release 5.5 (Final)
        # CentOS Linux release 6.0 (Final)
        # Fedora release 16 (Verne)
        # XenServer release 6.2.0-70446c (xenenterprise)
        # Oracle Linux release 7
        # CloudLinux release 7.1
        os_CODENAME=""
        for r in "Red Hat" CentOS Fedora XenServer CloudLinux; do
            os_VENDOR=$r
            if [[ -n "`grep \"$r\" /etc/redhat-release`" ]]; then
                ver=`sed -e 's/^.* \([0-9].*\) (\(.*\)).*$/\1\|\2/' /etc/redhat-release`
                os_CODENAME=${ver#*|}
                os_RELEASE=${ver%|*}
                os_UPDATE=${os_RELEASE##*.}
                os_RELEASE=${os_RELEASE%.*}
                break
            fi
            os_VENDOR=""
        done
        if [ "$os_VENDOR" = "Red Hat" ] && [[ -r /etc/oracle-release ]]; then
            os_VENDOR=OracleLinux
        fi
        os_PACKAGE="rpm"
    elif [[ -r /etc/SuSE-release ]]; then
        for r in openSUSE "SUSE Linux"; do
            if [[ "$r" = "SUSE Linux" ]]; then
                os_VENDOR="SUSE LINUX"
            else
                os_VENDOR=$r
            fi

            if [[ -n "`grep \"$r\" /etc/SuSE-release`" ]]; then
                os_CODENAME=`grep "CODENAME = " /etc/SuSE-release | sed 's:.* = ::g'`
                os_RELEASE=`grep "VERSION = " /etc/SuSE-release | sed 's:.* = ::g'`
                os_UPDATE=`grep "PATCHLEVEL = " /etc/SuSE-release | sed 's:.* = ::g'`
                break
            fi
            os_VENDOR=""
        done
        os_PACKAGE="rpm"
    # If lsb_release is not installed, we should be able to detect Debian OS
    elif [[ -f /etc/debian_version ]] && [[ $(cat /proc/version) =~ "Debian" ]]; then
        os_VENDOR="Debian"
        os_PACKAGE="deb"
        os_CODENAME=$(awk '/VERSION=/' /etc/os-release | sed 's/VERSION=//' | sed -r 's/\"|\(|\)//g' | awk '{print $2}')
        os_RELEASE=$(awk '/VERSION_ID=/' /etc/os-release | sed 's/VERSION_ID=//' | sed 's/\"//g')
    fi
    export os_VENDOR os_RELEASE os_UPDATE os_PACKAGE os_CODENAME
}

# Distro-agnostic function to tell if a package is installed
# is_package_installed package [package ...]
function is_package_installed {
    if [[ -z "$@" ]]; then
        return 1
    fi

    if [[ -z "$os_PACKAGE" ]]; then
        GetOSVersion
    fi

    if [[ "$os_PACKAGE" = "deb" ]]; then
        dpkg -s "$@" > /dev/null 2> /dev/null
    elif [[ "$os_PACKAGE" = "rpm" ]]; then
        rpm --quiet -q "$@"
    else
        exit_distro_not_supported "finding if a package is installed"
    fi
}

# Determine if current distribution is a Fedora-based distribution
# (Fedora, RHEL, CentOS, etc).
# is_fedora
function is_fedora {
    if [[ -z "$os_VENDOR" ]]; then
        GetOSVersion
    fi

    [ "$os_VENDOR" = "Fedora" ] || [ "$os_VENDOR" = "Red Hat" ] || \
        [ "$os_VENDOR" = "CentOS" ] || [ "$os_VENDOR" = "OracleLinux" ] || \
        [ "$os_VENDOR" = "CloudLinux" ]
}


# Determine if current distribution is a SUSE-based distribution
# (openSUSE, SLE).
# is_suse
function is_suse {
    if [[ -z "$os_VENDOR" ]]; then
        GetOSVersion
    fi

    [ "$os_VENDOR" = "openSUSE" ] || [ "$os_VENDOR" = "SUSE LINUX" ]
}


# Determine if current distribution is an Ubuntu-based distribution
# It will also detect non-Ubuntu but Debian-based distros
# is_ubuntu
function is_ubuntu {
    if [[ -z "$os_PACKAGE" ]]; then
        GetOSVersion
    fi
    [ "$os_PACKAGE" = "deb" ]
}

# Wrapper for ``yum`` to set proxy environment variables
# Uses globals ``OFFLINE``, ``*_proxy``, ``YUM``
# yum_install package [package ...]
function yum_install {
    [[ "$OFFLINE" = "True" ]] && return
    local sudo="sudo"
    [[ "$(id -u)" = "0" ]] && sudo="env"

    # The manual check for missing packages is because yum -y assumes
    # missing packages are OK.  See
    # https://bugzilla.redhat.com/show_bug.cgi?id=965567
    $sudo http_proxy="${http_proxy:-}" https_proxy="${https_proxy:-}" \
        no_proxy="${no_proxy:-}" \
        ${YUM:-yum} install -y "$@" 2>&1 | \
        awk '
            BEGIN { fail=0 }
            /No package/ { fail=1 }
            { print }
            END { exit fail }' || \
                die $LINENO "Missing packages detected"

    # also ensure we catch a yum failure
    if [[ ${PIPESTATUS[0]} != 0 ]]; then
        die $LINENO "${YUM:-yum} install failure"
    fi
}

# Wrapper for ``apt-get`` to set cache and proxy environment variables
# Uses globals ``OFFLINE``, ``*_proxy``
# apt_get operation package [package ...]
function apt_get {
    local xtrace=$(set +o | grep xtrace)
    set +o xtrace
    [[ "$OFFLINE" = "True" || -z "$@" ]] && return
    local sudo="sudo"
    [[ "$(id -u)" = "0" ]] && sudo="env"
    $xtrace
    $sudo DEBIAN_FRONTEND=noninteractive \
        http_proxy=${http_proxy:-} https_proxy=${https_proxy:-} \
        no_proxy=${no_proxy:-} \
        apt-get --option "Dpkg::Options::=--force-confold" --assume-yes "$@"
}

# Distro-agnostic package installer
# Uses globals ``NO_UPDATE_REPOS``, ``REPOS_UPDATED``, ``RETRY_UPDATE``
# install_package package [package ...]
function update_package_repo {
    NO_UPDATE_REPOS=${NO_UPDATE_REPOS:-False}
    REPOS_UPDATED=${REPOS_UPDATED:-False}
    RETRY_UPDATE=${RETRY_UPDATE:-False}

    if [[ "$NO_UPDATE_REPOS" = "True" ]]; then
        return 0
    fi

    if is_ubuntu; then
        local xtrace=$(set +o | grep xtrace)
        set +o xtrace
        if [[ "$REPOS_UPDATED" != "True" || "$RETRY_UPDATE" = "True" ]]; then
            # if there are transient errors pulling the updates, that's fine.
            # It may be secondary repositories that we don't really care about.
	    apt_get update  || /bin/true
            REPOS_UPDATED=True
        fi
        $xtrace
    fi
}

function real_install_package {
    if is_ubuntu; then
        apt_get install "$@"
    elif is_fedora; then
        yum_install "$@"
    elif is_suse; then
        zypper_install "$@"
    else
        exit_distro_not_supported "installing packages"
    fi
}

# Distro-agnostic package installer
# install_package package [package ...]
function install_package {
    update_package_repo
    real_install_package $@ || RETRY_UPDATE=True update_package_repo && real_install_package $@
}

# Change to $HOME
cd ${HOME}

BASE_DIR="${HOME:-}"
DOTFILES_DIR="${BASE_DIR}/.dotfiles"

# Install git
is_package_installed git || install_package git

# clone dotfiles if not present
if [ ! -d ${DOTFILES_DIR} ]; then
    git clone https://github.com/rajalokan/dotfiles.git ${DOTFILES_DIR}
fi

cd ${DOTFILES_DIR}
eval $(printf "%q\n" "${DOTFILES_DIR}/run.sh")
