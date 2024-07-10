{ lib, pkgs, ... }:

let
  user = "guest";
in
with lib.liberion;
{
  services.xserver = {
    enable = true;

    desktopManager.lxqt = on;

    displayManager = {
      autoLogin = {
        enable = true;
        user = user;
      };

      sessionCommands = ''
        nm-applet &
        pasystray &
      '';

      lightdm = {
        enable = true;
        greeters.slick = on;
      };
    };
  };

  liberion = {
    boot.bootloader.systemd-boot = on;

    hardware.audio.pipewire = on;

    network = {
      ssh = on;
      networkmanager = on;
    };

    nixos = {
      user = {
        name = user;
        initialPassword = "pass";
        isNormalUser = true;
        extraGroups = [ "wheel" ];
      };

      variables = {
        EDITOR = "nvim";
        VISUAL = "emacs";

        TERMINAL = "alacritty";
        FILE = "pcmanfm";
      };

      systemPackages = with pkgs; [
        # tools
        git
        gnumake

        # terminal-emulators
        alacritty
        xterm # fallback

        # editors
        emacs
        neovim
        geany

        # browsers
        firefox # gecko
        brave # blink

        # misc
        pcmanfm # file manager (gui)
      ];
    };
  };

  networking.wireless.enable = lib.mkForce false;
}
