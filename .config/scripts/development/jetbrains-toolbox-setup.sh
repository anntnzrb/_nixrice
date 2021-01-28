#!/usr/bin/env bash

# jetbrains-toolbox-setup.sh --- JetBrains Toolbox Setup

# Commentary:

# This installation script is Distro-agnostic, does not depend on the package
# manager.

# References: https://www.jetbrains.com/toolbox-app/

# Code:

# -----------------------------------------------------------------------------
# preamble
# -----------------------------------------------------------------------------

# source utilities
# shellcheck disable=SC1090
. "${LIBSHUTILS:?}/sys-utils"

# -----------------------------------------------------------------------------
# main
# -----------------------------------------------------------------------------

# check if running with elevated priviledges; elevate if not
! is_su && elevate_privs "$0" "$@"

user_agent=('User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.115 Safari/537.36')

url=$(curl 'https://data.services.jetbrains.com//products/releases?code=TBA&latest=true&type=release' -H 'Origin: https://www.jetbrains.com' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: en-US,en;q=0.8' -H "${user_agent[@]}" -H 'Accept: application/json, text/javascript, */*; q=0.01' -H 'Referer: https://www.jetbrains.com/toolbox/download/' -H 'Connection: keep-alive' -H 'DNT: 1' --compressed | grep -Po '"linux":.*?[^\\]",' | awk -F ':' '{print $3,":"$4}' | sed 's/[", ]//g')

file="${url##*/}"
dest="/tmp/${file}"

printf "\n\e[94mDownloading Toolbox files \e[39m\n"
wget -cO "${dest}" "${url}" --read-timeout=5 --tries=0
printf "\n\e[32mDownload complete!\e[39m\n"
dir="/opt/jetbrains-toolbox"
printf "\n\e[94mInstalling to %s\e[39m\n" "${dir}"
mkdir "${dir}" 2>/dev/null && tar -xzf "${dest}" -C "${dir}" --strip-components=1 ||
	    printf "\n\e[32mJetbrains Toolbox already installed!...Skipping\e[39m\n" &&
	        exit 1

chmod -R 755 "${dir}"
touch "${dir}/jetbrains-toolbox.sh"
printf "#!/bin/bash\n" >>"${dir}/jetbrains-toolbox.sh"
printf "%s/jetbrains-toolbox" "${dir}" >>"${dir}/jetbrains-toolbox.sh"

ln -s "${dir}/jetbrains-toolbox.sh" "/usr/local/bin/jetbrains-toolbox"
chmod -R 755 "/usr/local/bin/jetbrains-toolbox"
rm "${dest}"
printf "\n\e[32mDone.\e[39m\n"
