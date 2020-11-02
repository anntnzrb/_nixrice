<!-- markdownlint-disable MD013 MD037 -->

# \*nixrice

**dotfiles** || **home folder**

## table of contents

- [\*nixrice](#nixrice)
  - [table of contents](#table-of-contents)
  - [intro](#intro)
  - [timeline](#timeline)
  - [software](#software)
  - [installation](#installation)
  - [license](#license)

## intro

these files are meant to work across multiple
[\*nix distributions](https://0x0.st/HNfM), therefore most scripts are written
with the goal of not being [os/distro/software]-dependant

i tend to re-install my os a lot, this leads me not only to have everything
pre-configured already but also to have a way of installing all the software
i normally use with their corresponding configuration files as soon as
possible. check [installation](#installation) for extra info

## software

this table displays _most_ of the programs i have configuration files for:

| software           | name                                    |
| ------------------ | --------------------------------------- |
|                    | **shell**                               |
| terminal emulator  | _st_ ([external](https://0x0.st/8b4q))  |
| :arrow_up:         | _alacritty_                             |
| shell              | _zsh_                                   |
|                    | **graphical**                           |
| window manager     | _dwm_ ([external](https://0x0.st/X869)) |
| :arrow_up:         | _i3_                                    |
| :arrow_up:         | _spectrwm_                              |
| compositor         | _picom/compton_                         |
| browser            | _qutebrowser_                           |
| notifications      | _dunst_                                 |
|                    | **files/text/docs/editors**             |
| text editor        | _[n]vi[m]_                              |
| :arrow_up:         | _vscod[e/ium]_                          |
| file manager       | _PCManFM_                               |
| pdf viewer         | _zathura_                               |
| language formatter | _uncrustify_                            |
|                    | **miscellaneous**                       |
| key-binds          | _sxhkd_                                 |
| tmux               | _tmux_                                  |
| sys-[monitor/info] | _neofetch_                              |
| :arrow_up:         | _bottom_                                |

**note**: names described above are just the official given names of the
software; package names varies depending on the `*nix` distribution

## installation

these _.files_ may be installed using [uarbs](https://0x0.st/X86L), please
refer to the linked repo for instructions

you can also `git clone` (alternatively manually download) this repo and
copy the contents you're interested in

```console
git clone https://github.com/anntnzrb/_nixrice.git
```

## license

this repo is under the [GPL-2.0](https://0x0.st/HNVH) license, i encourage you
to _experiment_, _fork_, _modify_ & _share_, this content
