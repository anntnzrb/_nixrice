# Baseline captured from /tmp/rice-r0a-evidence.6QxJBA/current.r0a-eval-probe.json,
# evaluated against commit 0f4a56eb before the Snowfall-to-local-composition refactor.
# The check output is normalized by removing this check's own key before comparing
# checks.<system> children. Values are names and type tags only; no store paths.
{
  topLevel = [
    "checks"
    "darwinConfigurations"
    "darwinModules"
    "devShells"
    "doConfigurations"
    "formatter"
    "homeConfigurations"
    "homeModules"
    "isoConfigurations"
    "lib"
    "nixosConfigurations"
    "nixosModules"
    "overlays"
    "packages"
    "pkgs"
    "snowfall"
    "templates"
  ];

  topLevelTypes = {
    checks = "set";
    darwinConfigurations = "set";
    darwinModules = "set";
    devShells = "set";
    doConfigurations = "set";
    formatter = "set";
    homeConfigurations = "set";
    homeModules = "set";
    isoConfigurations = "set";
    lib = "set";
    nixosConfigurations = "set";
    nixosModules = "set";
    overlays = "set";
    packages = "set";
    pkgs = "set";
    snowfall = "set";
    templates = "set";
  };

  configurations = {
    darwin = {
      keys = [
        "beirut"
        "incheon"
      ];
      valueType = "set";
    };
    nixos = {
      keys = [
        "munich"
        "solna"
        "tampa"
        "zadar"
      ];
      valueType = "set";
    };
    do = {
      keys = [ "nista" ];
      valueType = "derivation";
    };
    iso = {
      keys = [ "nomad" ];
      valueType = "derivation";
    };
    homes = {
      keys = [
        "annt@beirut"
        "annt@incheon"
        "annt@wsl"
        "annt@zadar"
      ];
      valueType = "set";
    };
  };

  moduleMaps = {
    nixos = [
      ""
      "boot"
      "boot/bootloader"
      "boot/bootloader/grub"
      "boot/bootloader/systemd-boot"
      "common/desktop"
      "common/xorg"
      "environment"
      "hardware/audio"
      "hardware/keyboard/keyd"
      "network/dhcp"
      "network/networkmanager"
      "network/ssh"
      "network/syncthing"
      "network/vpn/mullvad"
      "nix"
      "suites/desktop"
      "user"
      "virtualisation/docker"
      "virtualisation/virt-manager"
      "virtualisation/virtualbox"
      "wsl"
    ];
    darwin = [
      ""
      "environment"
      "homebrew"
      "network/ssh"
      "nix"
      "programs/aldente"
      "programs/bitwarden"
      "programs/brave"
      "programs/obs"
      "programs/orbstack"
      "programs/rustdesk"
      "programs/vlc"
      "programs/vscode"
      "programs/whatsapp"
      "services/aerospace"
      "services/skhd"
      "services/yabai"
      "services/yashiki"
      "suites/desktop"
      "system/bar"
      "system/dock"
      "system/finder"
      "system/keyboard"
      "system/trackpad"
      "system/ui"
      "user"
    ];
    home = [
      ""
      "cli/aider-chat"
      "cli/btop"
      "cli/bun"
      "cli/direnv"
      "cli/espanso"
      "cli/fastfetch"
      "cli/fzf"
      "cli/git"
      "cli/husky"
      "cli/janet"
      "cli/llm-agents"
      "cli/neofetch"
      "cli/omnix"
      "cli/repomix"
      "cli/rust"
      "cli/simple-mtpfs"
      "cli/tldr"
      "cli/uv"
      "cli/yazi"
      "cli/yt-dlp"
      "cli/zoxide"
      "desktop/bitwarden"
      "desktop/browsers/brave"
      "desktop/browsers/chromium"
      "desktop/browsers/firefox"
      "desktop/browsers/qutebrowser"
      "desktop/browsers/zen"
      "desktop/discord"
      "desktop/feh"
      "desktop/file-managers/pcmanfm"
      "desktop/flameshot"
      "desktop/gammastep"
      "desktop/launchers/bemenu"
      "desktop/launchers/wofi"
      "desktop/mpv"
      "desktop/notesnook"
      "desktop/obs"
      "desktop/sxhkd"
      "desktop/terminal-emulators/alacritty"
      "desktop/terminal-emulators/ghostty"
      "desktop/terminal-emulators/rio"
      "desktop/ui/themes"
      "desktop/whatsapp"
      "desktop/window-managers/wayland/hyprland"
      "desktop/window-managers/wayland/sway"
      "desktop/window-managers/xorg/awesomewm"
      "desktop/window-managers/xorg/herbstluftwm"
      "desktop/window-managers/xorg/xmonad"
      "desktop/zathura"
      "editors/emacs"
      "editors/neovim"
      "editors/vscode"
      "editors/zed"
      "services/t3"
      "shared/darwin"
      "shared/xorg"
      "shared/xorg/picom"
      "shells"
      "shells/bash"
      "shells/fish"
      "shells/starship"
      "shells/tmux"
      "shells/zellij"
      "shells/zsh"
      "suites/cli"
      "suites/common"
      "suites/core"
      "suites/desktop"
      "suites/dev"
      "suites/llm-agents"
      "xdg"
    ];
  };

  realSystems = [
    "aarch64-darwin"
    "aarch64-linux"
    "x86_64-darwin"
    "x86_64-linux"
  ];

  pkgs = {
    type = "set";
    systems = {
      "aarch64-darwin" = [
        "nixpkgs"
        "nixpkgs-stable"
        "nixpkgs-unstable"
      ];
      "aarch64-linux" = [
        "nixpkgs"
        "nixpkgs-stable"
        "nixpkgs-unstable"
      ];
      "x86_64-darwin" = [
        "nixpkgs"
        "nixpkgs-stable"
        "nixpkgs-unstable"
      ];
      "x86_64-linux" = [
        "nixpkgs"
        "nixpkgs-stable"
        "nixpkgs-unstable"
      ];
    };
    systemType = "set";
    channelType = "set";
  };

  perSystem = {
    packages = {
      type = "set";
      systemType = "set";
      valueType = "derivation";
      keys = {
        "aarch64-darwin" = [
          "default"
          "homeConfigurations-annt@beirut"
          "homeConfigurations-annt@incheon"
          "rice"
        ];
        "aarch64-linux" = [
          "default"
          "rice"
        ];
        "x86_64-darwin" = [
          "default"
          "rice"
        ];
        "x86_64-linux" = [
          "default"
          "homeConfigurations-annt@wsl"
          "homeConfigurations-annt@zadar"
          "rice"
        ];
      };
    };
    devShells = {
      type = "set";
      systemType = "set";
      valueType = "derivation";
      keys = {
        "aarch64-darwin" = [ "default" ];
        "aarch64-linux" = [ "default" ];
        "x86_64-darwin" = [ "default" ];
        "x86_64-linux" = [ "default" ];
      };
    };
    checks = {
      type = "set";
      systemType = "set";
      valueType = "derivation";
      keys = {
        "aarch64-darwin" = [ "pre-commit-hooks" ];
        "aarch64-linux" = [ "pre-commit-hooks" ];
        "x86_64-darwin" = [ "pre-commit-hooks" ];
        "x86_64-linux" = [ "pre-commit-hooks" ];
      };
    };
    formatter = {
      type = "derivation";
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
    };
  };

  overlays = {
    type = "set";
    keys = [
      "default"
      "nixpkgs-unstable"
      "package/default"
      "package/rice"
    ];
    valueType = "lambda";
  };

  lib = {
    type = "set";
    keys = [
      "darwin"
      "fs"
      "launchd"
      "mkOneCaskProgram"
      "mkOneMasAppProgram"
      "module"
      "override"
      "overrideDerivation"
      "xorg"
    ];
  };

  snowfall = {
    type = "set";
    keys = [
      "config"
      "raw-config"
      "user-lib"
    ];
  };

  templates = {
    type = "set";
    keys = [ ];
  };
}
