# Table of Contents

1.  [preamble](#org8309553)
2.  [intro](#org55ce043)
3.  [installation](#org47ba2a6)
    1.  [dependencies](#orgef2dc22)
    2.  [instructions](#org4c6e944)
4.  [disclaimer](#org0a813bb)
5.  [log](#org219ac9f)
6.  [copying](#org8762456)



<a id="org8309553"></a>

# preamble

this file is originally created using *GNU Emacs' Org-Mode*, refer to `./docs/`
for the source code; you may also do so if you're reading thru a Markdown/Org
renderer.

this file generates this *README* in 2 extra formats:

-   **plain-txt** (`ascii`) `./docs/README.txt`
-   **markdown** `./README`


<a id="org55ce043"></a>

# intro

these *.files* have accompanied me since *2019*-ish (under VC since *2020*),
all files/scripts have been written with portability in mind, meaning they're
meant to work across multiple [\*nix distrubutions](https://0x0.st/HNfM).


<a id="org47ba2a6"></a>

# installation

the following instructions allow you to set up my `.files` with one simple
command, if you're only looking to copy them you may want to take a look at the
`./.files/` folder instead.

**NOTE**: do not randomly execute the following command as this can lead to data
overwritten; it is adviced to backup or attempt what comes in an isolated
environment.


<a id="orgef2dc22"></a>

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


<a id="org4c6e944"></a>

## instructions

unlock password manager vault before `chezmoi init` so it's not needed to
re-enter the passsword a bigillion times:

    # my case for Bitwarden
    bw unlock
    export BW_SESSION="..."

the following command will clone this repository and place it under
`~/.local/share/chezmoi/`.

    chezmoi init --ssh -a 'git@gitlab.com:anntnzrb/xnixrice'

    # or via https
    chezmoi init -a 'https://gitlab.com/anntnzrb/xnixrice'

after the password manager prompt your keys should be imported, but they're not
added yet&#x2026;

    eval `ssh-agent -s`           # enable ssh-agent
    ssh-add ~/.ssh/my_key_id_type # add whichever keys to use
    ssh -T git@github.com         # test keys (github is just an example)


<a id="org0a813bb"></a>

# disclaimer

this repository serves as a laboratory. it's meant for experimentation and
should be considered *unstable*, *biased* and sometimes even *untested*.

nevertheless feel free to take a look and learn from it, experimenting and
sharing is always encouraged.


<a id="org219ac9f"></a>

# log

section designed to only track **very remarkable** stuff.

*(descending by date)*

**2022-05-14** - switch to *chezmoi*.

-   after a few weeks with *GNU Stow* i started having issues with *symlinks* all
    over my `~/`. other than that there are quite a few reasons why *chezmoi* is
    a superior system than *Stow*, to name a few: the template system, secrets,
    etc&#x2026;; still does the job though and would stick to it if i didn't this
    better alternative.

**2022-05-08** - mass repo cleanup.

-   due to bad practices, this repo was filled with large blobs of files
    by the extentions `{png,ttf,otf}` (stored a few wallpapers + fonts).  **these
    blobs were pruned at the cost of the whole commit history being rewritten**.

**2022-04-26** - switch to *GNU Stow*.

-   this repository emulated the structure of a `~/` directory
    prior to the switch.

**2021-06-02** - License switch *GPLv2* -> *GPLv3*.

**2020-11-14** - *GNU Emacs* is introduced.


<a id="org8762456"></a>

# copying

refer to the [COPYING](./COPYING) file for licensing information.

unless otherwise noted, all code herein is distributed under the terms of the
[GNU General Public License Version 3 or later](https://www.gnu.org/licenses/gpl-3.0.en.html).
