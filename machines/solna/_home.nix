{ inputs, ... }: {
  imports = [
    ../../modules/base/core/home.nix
    ../../modules/base/shells/home.nix
  ]
  ++ (with inputs.self.homeModules; [
    btop
    bun
    direnv
    git
    neovim
    node
    tmux
    uv
  ]);

  home = {
    stateVersion = "26.05";
    sessionVariables.EDITOR = "nvim";
  };

  liberion.cli.git = {
    gh.enable = false;
    lazygit.enable = false;
  };

  liberion.shells.tmux.layouts.cockpit.enable = false;
}
