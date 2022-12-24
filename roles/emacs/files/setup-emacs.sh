#!/bin/sh

# setup-emacs --- Emacs from source setup

# Commentary:

# Installs GNU Emacs from source.

# References: https://github.com/emacs-mirror/emacs

# Code:

# -----------------------------------------------------------------------------
# variables
# -----------------------------------------------------------------------------

branch='emacs-28.2'
clone_dir="/usr/src/emacs-${branch}"
deps_file='pkgs.txt'

# generic flags
flags="--with-native-compilation \
--with-mailutils \
--with-sound=yes \
--without-compress-install"

# g-stuff
flags="${flags} --without-gsettings \
--without-gconf"

# shaping-text related stuff
# disabling the following forces using Harfbuzz
flags="${flags} --with-harfbuzz \
--without-libotf \
--without-m17n-flt"

# windowing system
flags="${flags} --with-x-toolkit=gtk3 \
--with-xwidgets \
--without-xaw3d"

# -----------------------------------------------------------------------------
# functions
# -----------------------------------------------------------------------------

err() {
    case ${#} in
    0) printf '' >&2 ;;
    *)
        printf '%s\n' "${@}" >&2
        ;;
    esac
}

git_clone_emacs() {
	git clone --depth 1 --single-branch --no-tags --branch "${branch}" \
        "${1}" "${clone_dir}"
}

# -----------------------------------------------------------------------------
# main
# -----------------------------------------------------------------------------

# root check
test `id -u` -ne 0 && err 'Not running as root.' && exit 1

# install dependencies
pkg_deps=`cat "${deps_file}" | sed '/^#/d ; /^$/d' | tr '\n' ' '`
test -z "${pkg_deps}" && err 'Could not parse dependencies file.' && exit 1
apt install -y ${pkg_deps}

invoke_dir=`pwd`

git_clone_emacs 'https://github.com/emacs-mirror/emacs'
cd "${clone_dir}" || { err 'Cannot cd into dir.' && exit 1; }

# configure & install
./autogen.sh && ./configure ${flags}
make -j`nproc` && make -j`nproc` install

# finally return
cd "${invoke_dir}" || { err 'Cannot cd into dir.' && exit 1; }

exit 0
