# \*nixrice

## Disclaimer

This repository serves as a laboratory. It is meant for experimentation and
should be considered _unstable_, _biased_ and sometimes even _untested_.

Nevertheless feel free to take a look and learn from it, experimenting and
sharing is encouraged.

## Introduction

The journey begins around _2019_-ish, back when I was a complete novice in the
_\*nix_ world. The way I used to manage my configurations originally was by
emulating the `~/` directory structure in the git repository; plain `cp`.
_Luke Smith_ was the individual who introduced me the _\*nix_ world via his
[humurous](https://www.youtube.com/watch?v=DB6UWGeNePk),
[sarcastic](https://www.youtube.com/watch?v=GJ_v31qktSk) yet
[informational](https://www.youtube.com/watch?v=NzD2UdQl5Gc) videos hosted on
[his YouTube channel](https://www.youtube.com/@LukeSmithxyz/videos),
also hosted at any _libre-whatever_ platform. More on this on the
[Acknoledgments](#acknoledgments) section.

> The following _.files_ have accompanied me since _2019_-ish and have been under
> **vc** since _2020_.

**NOTE**: Consider reading the [Disclaimer](#disclaimer) section.

## Dotfile Configuration Systems (stow, chezmoi, ansible, ...)

After some time using a traditional approach to manage my configurations I went
on and tried [GNU Stow](https://www.gnu.org/software/stow), which is a symlink
farm manager. It was nice being able to edit the managed configuration files
the normal way to also affecting the source files.

_Stow_ did not last long before I tried [chezmoi](https://www.chezmoi.io) for
even less time. It offered me everything _Stow_ did but with the added benefit
of being able to use placeholders and templates, among other few things.

I settled using [Ansible]([https://www.ansible.com) for a while, which is a
configuration management tool developed by **RedHat**. This convinced me to
believe this project was more solid than the previously mentioned ones, because
of **RedHat** being a big company. And in fact, it is true, until this day I
still recommend using _Ansible_ even though I do not use it anymore.

I transformed my whole configuration into _Ansible_ playbooks, which gave a lot
of flexibility and the ability to not only manage my configurations, but also
to install some programs. This ended up reducing a lot manual intervention I
had to deal with previously. To accomplish this, I followed _LearnLinuxTV_'s
excellent
[playlist]([https://youtube.com/playlist?list=PLT98CRl2KxKEUHie1m24-wkyHpEsa4Y70&si=O5xxvPiCyK_C1m7P) on the matter.

Around mid-late _2022_ I entered the world of [NixOS](https://nixos.org),
( ... ) [**TO BE CONTINUED**]

> I encourage the reader to browse through this repository's commit history to see
> how the structured of it has evolved over time.

## Acknowledgments

### People

- [Luke Smith](https://github.com/lukesmithxyz)
- [Derek Taylor (DistroTube)](https://www.youtube.com/@DistroTube)
- [Protesilaos Stavrou](https://www.youtube.com/@protesilaos)
- [David Wilson (SystemCrafters)](https://www.youtube.com/@SystemCrafters)
- [Brodie Robertson](https://www.youtube.com/@BrodieRobertson)
- [Jake Hamilton](https://www.youtube.com/@jakehamiltondev)
- [Suraj Kushwah (bugswriter)](https://www.youtube.com/@bugswriter_)
- [Gavin Freeborn](https://www.youtube.com/@GavinFreeborn)
- [gotbletu](https://www.youtube.com/@gotbletu)

### Resources

- [xero's dotfiles](https://github.com/xero/dotfiles)
- [Luke Smith's dotfiles](https://github.com/lukesmithxyz/voidrice)
- [Derek Taylor's dotfiles](https://gitlab.com/dwt1/dotfiles)
- [David Wilson's dotfiles](https://github.com/daviwil/dotfiles)
- [Henrik Lissner's dotfiles](https://github.com/hlissner/dotfiles)
- [Jake Hamilton's dotfiles](https://github.com/jakehamilton/config)
- [Austin Horstman's dotfiles](https://github.com/khaneliman/khanelinix)

## COPYING

Refer to the [COPYING](./COPYING) file for licensing information.

Unless otherwise noted, all code herein is distributed under the terms of the
[GNU General Public License Version 3 or later](https://www.gnu.org/licenses/gpl-3.0.en.html).
