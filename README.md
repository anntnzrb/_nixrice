# Table of Contents

1.  [preamble](#org5488a8b)
2.  [intro](#org27fab30)
3.  [installation](#org76eedc0)
    1.  [dependencies](#org82d5db5)
    2.  [instructions](#org613a4cf)
4.  [disclaimer](#org62ab583)
5.  [log](#org8b7d15c)
6.  [copying](#org0d09cfc)



<a id="org5488a8b"></a>

# preamble

this file is originally created using *GNU Emacs' Org-Mode*, refer to `./docs/`
for the source code; you may also do so if you're reading thru a Markdown/Org
renderer.

this file generates this *README* in 2 extra formats:

-   **plain-txt** (`ascii`) `./docs/README.txt`
-   **markdown** `./README`


<a id="org27fab30"></a>

# intro

these *.files* have accompanied me since *2019*-ish (under VC since *2020*),
all files/scripts have been written with portability in mind, meaning they're
meant to work across multiple [\*nix distrubutions](https://0x0.st/HNfM).


<a id="org76eedc0"></a>

# installation

the following instructions allow you to set up my `.files` with one simple
command, if you're only looking to copy them you may want to take a look at the
`./.files/` folder instead.

**NOTE**: do not randomly execute the following command as this can lead to data
overwritten; it is adviced to backup or attempt what comes in an isolated
environment.


<a id="org82d5db5"></a>

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
<td class="org-left">*<a href="https://www.chezmoi.io/">chezmoi</a></td>
<td class="org-left">cross-platform dotfile manager</td>
</tr>
</tbody>
</table>

\\\* can be installed on-the-fly, refer to link.


<a id="org613a4cf"></a>

## instructions

the following command will clone this repository and place it under
`~/.local/share/chezmoi/`.

    chezmoi init --ssh -a 'git@gitlab.com:anntnzrb/xnixrice.git'

    # alternative via https
    chezmoi init -a 'https://gitlab.com/anntnzrb/xnixrice.git'


<a id="org62ab583"></a>

# disclaimer

this repository serves as a laboratory. it's meant for experimentation and
should be considered *unstable*, *biased* and sometimes even *untested*.

nevertheless feel free to take a look and learn from it, experimenting and
sharing is always encouraged.


<a id="org8b7d15c"></a>

# log

section designed to only track **very remarkable** stuff.

*(descending by date)*

**2022-05-14** - switch to *chezmoi*.

-   after a few weeks with *GNU Stow* i started having issues with *symlinks* all
    over my `~/`.

-   there are quite a few reasons why *chezmoi* is a superior system than *Stow*,
    to name a few: the template system, secrets, etc&#x2026;; still does the job
    though and would stick to it if i didn't this better alternative.

**2022-05-08** - mass repo cleanup.

-   due to bad practices, this repo was filled with large blobs of files
    by the extentions `{png,ttf,otf}` (stored a few wallpapers + fonts).  **these
    blobs were pruned at the cost of the whole commit history being rewritten**.

**2022-04-26** - switch to *GNU Stow*.

-   this repository literally emulated the structure of a `~/` directory
    prior to the switch.

**2021-06-02** - License switch *GPLv2* -> *GPLv3*.

**2020-11-14** - *GNU Emacs* is introduced.


<a id="org0d09cfc"></a>

# copying

refer to the [COPYING](./COPYING) file for licensing information.

unless otherwise noted, all code herein is distributed under the terms of the
[GNU General Public License Version 3 or later](https://www.gnu.org/licenses/gpl-3.0.en.html).
