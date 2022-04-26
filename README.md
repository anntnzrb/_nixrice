## intro

these *.files* have accompanied me since *2019*ish (under VC since 2020), the
files (scripts) are written with portability in mind, meaning they're meant to
work across multiple [*nix distrubutions](https://0x0.st/HNfM).

## installation

somewhere around early *2022* i switched from a bare git repo to using
[GNU Stow](https://www.gnu.org/software/stow/) to properly sync **.files**.

get the repo and cd into it:

```shell
git clone --depth 1 'https://gitlab.com/anntnzrb/_nixrice.git' '/tmp/annt-rice'

cd '/tmp/annt-rice'
```

**OPTIONAL**: *you may take a look at the `Makefile` and add/remove the folders
to sync*

install:

```shell
make install
```

**NOTE**: *if an existing file is found `make` will throw an error and abort.*

uninstall:

```shell
make clean
```

update (re-link):

```shell
make reload
```

## disclaimer

this repository serves as a laboratory. it's meant for experimentation and
should be considered *unstable*, *biased* and sometimes even *untested*.

nevertheless feel free to take a look and learn from it, experimenting and
sharing is always encouraged.

## copying

refer to the [COPYING](./COPYING) file for licensing information.

unless otherwise noted, all code herein is distributed under the terms of the
[GNU General Public License Version 3 or later](https://www.gnu.org/licenses/gpl-3.0.en.html).
