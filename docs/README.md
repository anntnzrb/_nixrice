# Table of Contents

1.  [intro](#orgf8f984d)
2.  [installation](#orgb2cfffc)
    1.  [dependencies](#orgec54cea)
    2.  [instructions](#org6343d38)
3.  [disclaimer](#org34d8fc6)
4.  [log](#org2261d7a)
5.  [copying](#orgc4874b6)



<a id="orgf8f984d"></a>

# intro

these *.files* have accompanied me since *2019*-ish (under VC since 2020), the
files (scripts) are written with portability in mind, meaning they're meant to
work across multiple [\*nix distrubutions](https://0x0.st/HNfM).


<a id="orgb2cfffc"></a>

# installation

somewhere around early *2022* i switched from a bare git repo to using [GNU Stow](https://www.gnu.org/software/stow/)
to properly sync **.files**.


<a id="orgec54cea"></a>

## dependencies

<table border="2" cellspacing="0" cellpadding="6" rules="groups" frame="hsides">


<colgroup>
<col  class="org-left" />

<col  class="org-left" />
</colgroup>
<thead>
<tr>
<th scope="col" class="org-left">dependencies</th>
<th scope="col" class="org-left">description</th>
</tr>
</thead>

<tbody>
<tr>
<td class="org-left"><a href="https://git-scm.com/">Git</a></td>
<td class="org-left">(duh)</td>
</tr>


<tr>
<td class="org-left"><a href="https://www.gnu.org/software/make/">GNU Make</a></td>
<td class="org-left">automation tool that generates builds executable programs</td>
</tr>


<tr>
<td class="org-left"><a href="https://www.gnu.org/software/stow/">GNU Stow</a></td>
<td class="org-left">tool that deploys these dotfiles</td>
</tr>
</tbody>
</table>


<a id="org6343d38"></a>

## instructions

get the repo and `cd` into it:

    git clone --depth 1 'https://gitlab.com/anntnzrb/xnixrice.git' '/tmp/annt-rice'

    cd '/tmp/annt-rice'

**OPTIONAL**: *you may take a look at the `Makefile` and add/remove the folders
to sync*

install:

    make install

**NOTE**: *if an existing file is found `make` will throw an error and abort.*

uninstall:

    make clean

update (re-link):

    make reload


<a id="org34d8fc6"></a>

# disclaimer

this repository serves as a laboratory. it's meant for experimentation and
should be considered *unstable*, *biased* and sometimes even *untested*.

nevertheless feel free to take a look and learn from it, experimenting and
sharing is always encouraged.


<a id="org2261d7a"></a>

# log

section designed to only track **very remarkable** stuff.

*(descending by date)*

**2022-05-08** - mass repo cleanup

-   due to bad practices, this repo was filled with large blobs of files
    by the extentions `{png,ttf,otf}` (stored a few wallpapers + fonts).  **these
    blobs were pruned at the cost of the whole commit history being rewritten**.

**2022-04-26** - switch to *GNU Stow*.

-   this repository literally emulated the structure of a `~/` directory
    prior to the switch.

**2021-06-02** - License switch *GPLv2* -> *GPLv3*.

**2020-11-14** - *GNU Emacs* is introduced.


<a id="orgc4874b6"></a>

# copying

refer to the [COPYING](./COPYING) file for licensing information.

unless otherwise noted, all code herein is distributed under the terms of the
[GNU General Public License Version 3 or later](https://www.gnu.org/licenses/gpl-3.0.en.html).
