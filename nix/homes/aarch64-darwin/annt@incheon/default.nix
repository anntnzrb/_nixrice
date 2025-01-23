{
  lib,
  pkgs,
  inputs,
  namespace,
  ...
}:

{
  imports = [ inputs.mac-app-util.homeManagerModules.default ];

  home = {
    sessionVariables.EDITOR = "nvim";

    packages = with pkgs; [
      aldente
      czkawka
    ];
  };

  liberion = with lib.${namespace}; {
    ssh = {
      enable = true;
      hosts = {
        incheon = {
          keys.public = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM/EtC7o13JI6meAvX4RZrh7dUlch5Jzv5rU2KrKhe+X incheon";
        };
        git = {
          hostname = "github.com";
          user = "git";
          keys.public = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG+2YoDrSYPW7ucDqCz/lpNvFzLo4ZY3I1Afg/SV5N3P git";
        };
        sops = {
          keys.public = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM3ljZSRJAutWneaqwajNnvntyZIUWKpWy82AL3hsIjT sops";
        };
      };
    };

    shells = {
      aliases.defaults = on;
      zsh = {
        enable = true;
        prompt.starship = on;
      };
      preliminaryMessage.disable = true;

      zellij = on;
    };

    cli = {
      git = {
        enable = true;
        lazygit = on;
      };

      btop = on;
      direnv = on;
      fastfetch = on;
      fzf = on;
      omnix = on;
      tldr = on;
      yt-dlp = on;
      zoxide = on;
    };

    editors = {
      emacs = on;
      neovim = on;
      zed = on;
    };

    desktop = {
      terminal-emulators = {
        alacritty = {
          enable = true;
          font.size = 14.0;
        };
        ghostty = {
          enable = false;
          font.size = 16;
        };
      };
      ui = {
        fonts = on;
      };

      browsers.firefox = {
        enable = true;
        package.install = false;
      };
    };
  };
}
