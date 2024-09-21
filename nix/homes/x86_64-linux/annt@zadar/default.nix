{ lib, namespace, ... }:

with lib.${namespace};
{
  liberion = {
    shells = {
      aliases.defaults = on;
      sessionVariables = {
        EDITOR = "nvim";
      };

      bash = {
        enable = true;
        prompt.starship = on;
        zellij = on;
      };
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
      simple-mtpfs = on;
      zoxide = on;
    };

    editors = {
      neovim = on;
    };
  };
}
