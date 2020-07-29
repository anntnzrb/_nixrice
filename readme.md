<!-- markdownlint rules -->
<!-- markdownlint-disable MD013 -->
<!-- markdownlint-disable MD037 -->

# \*nixrice

**dotfiles**;

_literally my home folder?..._

## table of contents

- [\*nixrice](#nixrice)
  - [intro](#intro)
  - [timeline](#timeline)
  - [software](#software)
  - [installation](#installation)
  - [license](#license)

## intro

these files are meant to work across multiple
[\*nix distributions](https://0x0.st/HNfM), therefore most scripts are written
with the goal of not being [os/distro/software]-dependant

## timeline

**[_Jun-2020_]**
as of June 2020, i've moved back to [Void](https://0x0.st/HNff), i'm planning
to stay here as long as the package manager doesn't let me down, still think
[xbps](https://0x0.st/XZLN) is more intuitive to manage in comparison to
[pacman](https://0x0.st/XZLZ)

**[_Sep-2019+_]**
~~i mainly use [Arch](https://0x0.st/oGEz) nowadays, but i've lived in the
[Void](https://0x0.st/HNff) for a while in the past; i plan on returning tho~~

i tend to re-install my os a lot, this leads me not only to have everything
pre-configured already but also to have a way of installing all the software
i normally use with their corresponding configuration files as soon as
possible. check [installation](#installation) for extra info

## software

this table displays _most_ of the programs i have configuration files for

| software           | name                                    | :first_quarter_moon: |
| ------------------ | --------------------------------------- | -------------------- |
|                    | **shell**                               |                      |
| terminal emulator  | _st_ ([external](https://0x0.st/8b4q))  | :large_blue_circle:  |
| :arrow_up:         | _alacritty_                             | :red_circle:         |
| shell              | _zsh_                                   | :large_blue_circle:  |
|                    | **graphical**                           |                      |
| window manager     | _dwm_ ([external](https://0x0.st/X869)) | :large_blue_circle:  |
| :arrow_up:         | _i3_                                    | :red_circle:         |
| :arrow_up:         | _spectrwm_                              | :red_circle:         |
| compositor         | _picom/compton_                         | :large_blue_circle:  |
| browser            | _qutebrowser_                           | :large_blue_circle:  |
| notifications      | _dunst_                                 | :large_blue_circle:  |
|                    | **files/text/docs/editors**             |                      |
| text editor        | _[n]vi[m]_                              | :large_blue_circle:  |
| :arrow_up:         | _vscod[e/ium]_                          | :red_circle:         |
| file manager       | _PCManFM_                               | :large_blue_circle:  |
| pdf viewer         | _zathura_                               | :large_blue_circle:  |
| language formatter | _uncrustify_                            | :large_blue_circle:  |
|                    | **miscellaneous**                       |                      |
| key-binds          | _sxhkd_                                 | :large_blue_circle:  |
| tmux               | _tmux_                                  | :large_blue_circle:  |
| sys-info tool      | _neofetch_                              | :large_blue_circle:  |

**note**: names described above are just the official given names of the
software; package names varies depending on the `GNU/Linux` distribution

- :first_quarter_moon: represents the status of the program

  - :large*blue_circle: the program's \_config* **is** currently being:
    - used
    - updated
  - :red*circle: the program's \_config* **is not** currently being used:

    - _may_ be outdated \*
    - _may_ not be installed on my system anymore

  - not because i'm not using **_x_** program anymore means the configuration
    files will not work; if i'm leaving the configuration file is most likely
    because i may return to use mentioned software

## installation

this _.files_ may be installed using [uarbs](https://0x0.st/X86L), please refer
to the linked repo for instructions

you can also `git clone` (alternatively manually download) this repo and
copy the contents you're interested in

```console
git clone https://github.com/anntnzrb/_nixrice.git
```

## license

this repo is under the [GPL-2.0](https://0x0.st/HNVH) license, i encourage you
to experiment, _fork_, _modify_, _share_, _etc_ this content
