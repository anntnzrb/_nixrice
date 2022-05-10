                               __________

                                *NIXRICE

                                anntnzrb
                               __________


Table of Contents
_________________

1. intro
2. installation
.. 1. dependencies
.. 2. instructions
3. disclaimer
4. log
5. copying





1 intro
=======

  these /.files/ have accompanied me since /2019/-ish (under VC since
  2020), the files (scripts) are written with portability in mind,
  meaning they're meant to work across multiple [*nix distrubutions].


[*nix distrubutions] <https://0x0.st/HNfM>


2 installation
==============

  somewhere around early /2022/ i switched from a bare git repo to using
  [GNU Stow] to properly sync *.files*.


[GNU Stow] <https://www.gnu.org/software/stow/>

2.1 dependencies
~~~~~~~~~~~~~~~~

   dependencies  description
  -------------------------------------------------------------------------
   [Git]         (duh)
   [GNU Make]    automation tool that generates builds executable programs
   [GNU Stow]    tool that deploys these dotfiles


[Git] <https://git-scm.com/>

[GNU Make] <https://www.gnu.org/software/make/>

[GNU Stow] <https://www.gnu.org/software/stow/>


2.2 instructions
~~~~~~~~~~~~~~~~

  get the repo and `cd' into it:

  ,----
  | git clone --depth 1 'https://gitlab.com/anntnzrb/xnixrice.git' '/tmp/annt-rice'
  |
  | cd '/tmp/annt-rice'
  `----


  *OPTIONAL*: /you may take a look at the `Makefile' and add/remove the
  folders to sync/

  install:

  ,----
  | make install
  `----

  *NOTE*: /if an existing file is found `make' will throw an error and
   abort./

  uninstall:

  ,----
  | make clean
  `----

  update (re-link):

  ,----
  | make reload
  `----


3 disclaimer
============

  this repository serves as a laboratory. it's meant for experimentation
  and should be considered /unstable/, /biased/ and sometimes even
  /untested/.

  nevertheless feel free to take a look and learn from it, experimenting
  and sharing is always encouraged.


4 log
=====

  section designed to only track *very remarkable* stuff.

  /(descending by date)/

  *2022-05-08* - mass repo cleanup

  - due to bad practices, this repo was filled with large blobs of files
    by the extentions `{png,ttf,otf}' (stored a few wallpapers + fonts).
    *these blobs were pruned at the cost of the whole commit history
    being rewritten*.

  *2022-04-26* - switch to /GNU Stow/.

  - this repository literally emulated the structure of a `~/' directory
    prior to the switch.

  *2021-06-02* - License switch /GPLv2/ -> /GPLv3/.

  *2020-11-14* - /GNU Emacs/ is introduced.


5 copying
=========

  refer to the [COPYING] file for licensing information.

  unless otherwise noted, all code herein is distributed under the terms
  of the [GNU General Public License Version 3 or later].


[COPYING] <./COPYING>

[GNU General Public License Version 3 or later]
<https://www.gnu.org/licenses/gpl-3.0.en.html>
