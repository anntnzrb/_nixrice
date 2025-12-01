{
  lib,
  pkgs,
  inputs,
  namespace,
  ...
}:

let
  inherit (lib.${namespace}.module) on;

  login = {
    name = "nixos";
    initialPassword = "nixos";
  };
in
{
  services = {
    displayManager = on // {
      autoLogin = on // {
        user = login.name;
      };
    };

    xserver = on // {
      desktopManager.cinnamon = on;
    };
  };

  networking = {
    wireless.enable = lib.mkForce false;
  };

  environment.systemPackages = with pkgs; [
    # tools
    git
    arandr

    # terminal-emulators
    alacritty
    kitty
    xterm

    # editors
    inputs.neovim-annt.packages.${pkgs.stdenv.hostPlatform.system}.nvf # vi-like
    geany # gui

    # browsers
    firefox # gecko
    brave # blink

    # misc
    pcmanfm # file manager (gui)
  ];

  ${namespace} = {
    user = {
      inherit (login) name initialPassword;
    };

    boot.bootloader.systemd-boot = on;

    hardware.audio.pipewire = on;

    network = {
      networkmanager = on;
      ssh = on;
    };
  };
}
