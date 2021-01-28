
# Table of Contents

1.  [intro](#orge3c1dc4)
2.  [`~/.config/scripts`](#orgfcfd07d)
3.  [installation](#orgaf591a5)
    1.  [\*nix deployment scripts](#orge47b281)
4.  [license](#org5d73a81)



<a id="orge3c1dc4"></a>

# intro

these files are meant to work across multiple [\*nix distributions](https://0x0.st/HNfM), therefore
most scripts are written with the goal of not being
**[os/distro/software]**-dependant. aka *POSIX*-compliant.


<a id="orgfcfd07d"></a>

# `~/.config/scripts`

a quick peek of my scripts, used for setting up development environments,
mostly.

the main scripts can be found at [~/.local/bin](./.local/bin).

    ./.config/scripts
    ├── development/
    │   ├── langs/
    │   │   ├── android-dev*
    │   │   ├── c-lang*
    │   │   ├── haskell-lang*
    │   │   ├── java-lang*
    │   │   ├── json-lang*
    │   │   ├── markdown-lang*
    │   │   ├── perl-lang*
    │   │   ├── python-lang*
    │   │   ├── rust-lang*
    │   │   ├── sh-lang*
    │   │   └── tex-lang*
    │   ├── cheat-sheets*
    │   ├── nix-setup.sh*
    │   ├── virtualization*
    │   └── vscode-extensions*
    ├── fonts/
    │   └── figlet-extra-fonts*
    └── misc/
        ├── gaming-setup*
        └── vpn-setup*


<a id="orgaf591a5"></a>

# installation

you can `git clone` (alternatively manually download) this repo and copy the
contents you're interested in.

    git clone 'https://gitlab.com/anntnzrb/_nixrice.git'


<a id="orge47b281"></a>

## \*nix deployment scripts

[nds](https://gitlab.com/anntnzrb/nds) (*\*nix deployment scripts*) is used to install the base of my system, a
collection of scripts created by myself.


<a id="org5d73a81"></a>

# license

this repo is under the [GPL-2.0](https://0x0.st/HNVH) license, i encourage you to *experiment, /fork*,
*modify* & *share* this content.
