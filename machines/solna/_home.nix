{ inputs, ... }: {
  imports = [
    (inputs.self + "/modules/base/core/home.nix")
    (inputs.self + "/modules/base/shells/home.nix")
  ]
  ++ (with inputs.self.homeModules; [
    ai-agents
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
