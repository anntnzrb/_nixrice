                               __________

                                *NIXRICE

                                anntnzrb
                               __________


Table of Contents
_________________

1. preamble
2. intro
3. installation
.. 1. dependencies
.. 2. instructions
4. disclaimer
5. log
6. copying





1 preamble
==========

  this file is originally created using /GNU Emacs' Org-Mode/, refer to
  `./docs/' for the source code; you may also do so if you're reading
  thru a Markdown/Org renderer.

  this file generates this /README/ in 2 extra formats:

  - *plain-txt* (`ascii') `./docs/README.txt'
  - *markdown* `./README'


2 intro
=======

  these /.files/ have accompanied me since /2019/-ish (under VC since
  /2020/), all files/scripts have been written with portability in mind,
  meaning they're meant to work across multiple [*nix distrubutions].


[*nix distrubutions] <https://0x0.st/HNfM>


3 installation
==============

  the following instructions allow you to set up my `.files' with one
  simple command, if you're only looking to copy them you may want to
  take a look at the `./.files/' folder instead.

  *NOTE*: do not randomly execute the following command as this can lead
  to data overwritten; it is adviced to backup or attempt what comes in
  an isolated environment.


3.1 dependencies
~~~~~~~~~~~~~~~~

   dependencies  description
  ----------------------------------------------
   *[chezmoi]    cross-platform dotfile manager

  \* can be installed on-the-fly, refer to link.


[chezmoi] <https://www.chezmoi.io/>


3.2 instructions
~~~~~~~~~~~~~~~~

  unlock password manager vault before `chezmoi init' so it's not needed
  to re-enter the passsword a bigillion times:

  ,----
  | # my case for Bitwarden
  | bw login
  | bw unlock
  | export BW_SESSION="..."
  `----

  the following command will clone this repository and place it under
  `~/.local/share/chezmoi/'.

  ,----
  | chezmoi init --ssh -a 'git@gitlab.com:anntnzrb/xnixrice'
  |
  | # or via https
  | chezmoi init -a 'https://gitlab.com/anntnzrb/xnixrice'
  `----


4 disclaimer
============

  this repository serves as a laboratory. it's meant for experimentation
  and should be considered /unstable/, /biased/ and sometimes even
  /untested/.

  nevertheless feel free to take a look and learn from it, experimenting
  and sharing is always encouraged.


5 log
=====

  section designed to only track *very remarkable* stuff.

  /(descending by date)/

  *2022-05-14* - switch to /chezmoi/.

  - after a few weeks with /GNU Stow/ i started having issues with
    /symlinks/ all over my `~/'. other than that there are quite a few
    reasons why /chezmoi/ is a superior system than /Stow/, to name a
    few: the template system, secrets, etc...; still does the job though
    and would stick to it if i didn't this better alternative.

  *2022-05-08* - mass repo cleanup.

  - due to bad practices, this repo was filled with large blobs of files
    by the extentions `{png,ttf,otf}' (stored a few wallpapers + fonts).
    *these blobs were pruned at the cost of the whole commit history
    being rewritten*.

  *2022-04-26* - switch to /GNU Stow/.

  - this repository emulated the structure of a `~/' directory prior to
    the switch.

  *2021-06-02* - License switch /GPLv2/ -> /GPLv3/.

  *2020-11-14* - /GNU Emacs/ is introduced.


6 copying
=========

  refer to the [COPYING] file for licensing information.

  unless otherwise noted, all code herein is distributed under the terms
  of the [GNU General Public License Version 3 or later].


[COPYING] <./COPYING>

[GNU General Public License Version 3 or later]
<https://www.gnu.org/licenses/gpl-3.0.en.html>
