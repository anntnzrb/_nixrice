# \*nixrice

![GitHub last commit (branch)](https://img.shields.io/github/last-commit/anntnzrb/_nixrice/master?style=flat-square)
![GitHub](https://img.shields.io/github/license/anntnzrb/_nixrice?style=flat-square)

(wip)

**dotfiles**;

_or i'd say, literally my home folder..._

## table of contents

- [\*nixrice](#nixrice)
  - [intro](#intro)
  - [software](#software)
  - [installation](#installation)
  - [license](#license)

## intro

these files are meant to work across multiple
[\*nix distributions](https://0x0.st/HNfM), therefore most scripts are written
with the goal of not being [os/distro/software]-dependant

i mainly use [Arch](https://0x0.st/oGEz) nowadays, but i've lived in the
[Void](https://0x0.st/HNff) for a while in the past; i plan on returning tho

i tend to re-install my os a lot, this leads me not only to have everything
pre-configured already but also to have a way of installing all the software
i normally use with their corresponding configuration files as soon as possible

because of this, [uarbs](https://0x0.st/i3U-) was created, with this, i'm able
to install a completely functional operating system within a few minutes
whether i wake up in the morning with a zero-filled storage drive or anyone
erases my whole drive, i can just run named program in order to have everything
once again; i don't mind loosing local content, as i normally keep everything
online anyways (not because of this reason obviously, but because i can access
this content from different devices)

see [installation](#installation)

## software

this table displays _most_ of the programs i have configuration files for

| software           | name                        | :first_quarter_moon: |
| ------------------ | --------------------------- | -------------------- |
| terminal emulator  | _st_                        | :large_blue_circle:  |
| :arrow_up:         | _alacritty_                 | :red_circle:         |
| shell              | _zsh_                       | :large_blue_circle:  |
|                    | **graphical**               |
| window manager     | _dwm_                       | :large_blue_circle:  |
| :arrow_up:         | _i3_                        | :red_circle:         |
| :arrow_up:         | _spectrwm_                  | :red_circle:         |
| compositor         | _picom/compton_             | :large_blue_circle:  |
| notifications      | _dunst_                     | :large_blue_circle:  |
|                    | **files/text/docs/editors** |
| text editor        | _[n]vim_                    | :large_blue_circle:  |
| :arrow_up:         | _vscod[e/ium]_              | :red_circle:         |
| file manager       | _PCManFM_                   | :large_blue_circle:  |
| pdf viewer         | _zathura_                   | :large_blue_circle:  |
| language formatter | _uncrustify_                | :large_blue_circle:  |
|                    | **miscellaneous**           |
| key-binds          | _sxhkd_                     | :large_blue_circle:  |
| sys-info tool      | _neofetch_                  | :large_blue_circle:  |

**note**: names described above are just the official given names of the
software; package names varies depending on the `GNU/Linux` distribution

- :first_quarter_moon: represents the status of the program

  - :large_blue_circle: the program's [config] **is** currently being:
    - used
    - updated
  - :red_circle: the program's [config] **is not** currently being used:

    - _may_ be outdated \*
    - _may_ not be installed on my system anymore

  - not because i'm not using [_x_] program anymore means the configuration
    files will not work; if i'm leaving the configuration file is most likely
    because i may return to use mentioned software

## installation

as described @ [intro](#intro), this dotfiles may be installed using
[uarbs](https://0x0.st/i3U-), please refer to linked repo for instructions

you can also `git clone` (alternatively manually download) this repo and
copy the contents you're interested in

```sh
git clone https://github.com/anntnzrb/_nixrice.git
```

## license

**_everything_** inside this repo is under the [GPL-2.0](https://0x0.st/HNVH)
license, you're free to _fork_, _modify_, _share_, _etc_ these files

i encourage you to experiment with this content;
