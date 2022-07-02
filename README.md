# Table of Contents

1.  [preamble](#org0dca8b8)
2.  [intro](#orgfc99488)
3.  [installation](#org9072bfd)
    1.  [dependencies](#org98d985c)
    2.  [instructions](#org341c90f)
4.  [disclaimer](#orgeb8dc68)
5.  [log](#orgb08ea2d)
6.  [copying](#org34b8a2c)



<a id="org0dca8b8"></a>

# preamble

this file is created using *GNU Emacs' Org-Mode*, refer to `docs/` for the
source code; in there you can find different versions of this document.

this file gets generates in 2 extra formats:

-   **plain-text**
-   **markdown**


<a id="orgfc99488"></a>

# intro

these *.files* have accompanied me since *2019*-ish (under VC since *2020*),
all files/scripts have been written with portability in mind, meaning they're
meant to work across multiple [\*nix distrubutions](https://0x0.st/HNfM).


<a id="org9072bfd"></a>

# installation

the following instructions allow you to set up my `.files` with one simple
command, if you're only looking to copy them you may want to take a look at the
`./.roles/` folder instead.

**NOTE**: do not randomly execute the following commands as this can lead to
overwritten data; it is adviced to backup or attempt what comes in an isolated
environment.


<a id="org98d985c"></a>

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
<td class="org-left"><a href="https://repology.org/project/ansible/versions">ansible</a></td>
<td class="org-left">software deployment tool</td>
</tr>
</tbody>
</table>

**NOTE**: If you're on *Nix* take a look at `./default.nix`.


<a id="org341c90f"></a>

## instructions

unlock password manager vault before deployment so info can be retrieved:

    # my case for Bitwarden
    export BW_SESSION=$(bw unlock --raw)

deploy files with:

    ansible-pull -U 'https://git.sr.ht/~anntnzrb/_nixrice'

    # if above fails, clone & install manually
    git clone 'https://git.sr.ht/~anntnzrb/_nixrice' && cd '_nixrice'
    ansible-playbook -i localhost local.yml


<a id="orgeb8dc68"></a>

# disclaimer

this repository serves as a laboratory. it's meant for experimentation and
should be considered *unstable*, *biased* and sometimes even *untested*.

nevertheless feel free to take a look and learn from it, experimenting and
sharing is always encouraged.


<a id="orgb08ea2d"></a>

# log

section designed to only track **very remarkable** stuff.

*(descending by date)*

**2022-07-02** - switch to *Ansible*.

-   moved over to *ansible* as it is conceptually the same as *chezmoi* with extra
    features, allows extra customization as *chezmoi* aims to make it simple.

**2022-05-24** - *GNU Emacs* configurations removed.

-   ~(1 and 1/2) years posterior to introducing *GNU Emacs* along with these
    .files i farewell its configuration to honour it at its own repository.  as
    of this writing, this repo has become too polluted with Emacs commits which
    end up overshadowing the overall commit history only by a single piece of
    software; deploying should not be an issue with *chezmoi* anyways.

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


<a id="org34b8a2c"></a>

# copying

refer to the [COPYING](./COPYING) file for licensing information.

unless otherwise noted, all code herein is distributed under the terms of the
[GNU General Public License Version 3 or later](https://www.gnu.org/licenses/gpl-3.0.en.html).
