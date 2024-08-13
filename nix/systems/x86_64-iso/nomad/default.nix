{ lib
, pkgs
, inputs
, system
, ...
}:

let
  user = "nixos";
  pass = "nixos";
in
with lib.liberion; {
  services = {
    displayManager = {
      autoLogin = {
        enable = true;
        inherit user;
      };
    };

    xserver = {
      enable = true;

      desktopManager.xfce = on;

      displayManager = {
        lightdm = {
          enable = true;
          greeters.slick = on;
        };
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
        initialPassword = pass;
        isNormalUser = true;
        extraGroups = [ "wheel" ];
      };

      variables = {
        EDITOR = "nvim";
      };

      systemPackages = with pkgs; [
        # tools
        git
        autorandr

        # terminal-emulators
        alacritty
        kitty
        xterm

        # editors
        inputs.neovim-annt.packages.${system}.neovim # vi-like
        geany # gui

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
