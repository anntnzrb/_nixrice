# The toolset every liberion home gets.
{ inputs, ... }: {
  imports = with inputs.self.homeModules; [
    # cli
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

    # dev
    bun
    husky
    node
    omnix
    repomix
    uv

    # shell and editor
    neovim
    starship
    tmux
  ];

  home.sessionVariables.EDITOR = "nvim";
}
