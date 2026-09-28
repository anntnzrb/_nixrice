{ inputs, ... }: {
  imports = [
    inputs.nix-index-database.homeModules.nix-index
  ]
  ++ (with inputs.self.homeModules; [
    btop
    direnv
    fastfetch
    fzf
    git
    janet
    tldr
    yazi
    yt-dlp
    zoxide

    bun
    husky
    node
    omnix
    repomix
    uv

    neovim
    starship
    tmux
  ]);

  programs = {
    command-not-found.enable = false;
    nix-index-database.comma.enable = true;
  };

  home.sessionVariables.EDITOR = "nvim";
}
