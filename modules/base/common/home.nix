{ inputs, ... }: {
  imports = with inputs.self.homeModules; [
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
  ];

  home.sessionVariables.EDITOR = "nvim";
}
