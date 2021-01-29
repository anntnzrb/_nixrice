
# Table of Contents

1.  [intro](#org2dc78c3)
2.  [`~/.config/scripts`](#org9ac37bb)
3.  [installation](#org677c04a)
    1.  [\*nix deployment scripts](#org0cb5814)
4.  [license](#orgdba45cb)



<a id="org2dc78c3"></a>

# intro

these files are meant to work across multiple [\*nix distributions](https://0x0.st/HNfM), therefore
most scripts are written with the goal of not being
**[os/distro/software]**-dependant. aka *POSIX*-compliant.


<a id="org9ac37bb"></a>

# `~/.config/scripts`

a quick peek of my scripts, used for setting up development environments,
mostly.

the main scripts can be found at [~/.local/bin](./.local/bin).

    ./.config/scripts
    ├── development/
    │   ├── langs/
    │   │   ├── android-dev*
    │   │   ├── c-lang.sh*
    │   │   ├── haskell-lang*
    │   │   ├── java-lang.sh*
    │   │   ├── json-lang*
    │   │   ├── kotlin-lang.sh*
    │   │   ├── markdown-lang*
    │   │   ├── perl-lang*
    │   │   ├── python-lang.sh*
    │   │   ├── rust-lang*
    │   │   ├── sh-lang*
    │   │   └── tex-lang*
    │   ├── cheat-sheets*
    │   ├── jetbrains-toolbox-setup.sh*
    │   ├── nix-setup.sh*
    │   ├── sdkman-setup.sh*
    │   ├── virtualization*
    │   └── vscode-extensions*
    ├── fonts/
    │   └── figlet-extra-fonts*
    └── misc/
        ├── gaming-setup*
        └── vpn-setup*


<a id="org677c04a"></a>

# installation

you can `git clone` (alternatively manually download) this repo and copy the
contents you're interested in.

    git clone 'https://gitlab.com/anntnzrb/_nixrice.git'


<a id="org0cb5814"></a>

## \*nix deployment scripts

[nds](https://gitlab.com/anntnzrb/nds) (*\*nix deployment scripts*) is used to install the base of my system, a
collection of scripts created by myself.


<a id="orgdba45cb"></a>

# license

this repo is under the [GPL-2.0](https://0x0.st/HNVH) license, i encourage you to *experiment, /fork*,
*modify* & *share* this content.
