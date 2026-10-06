{ inputs, ... }: {
  imports = with inputs.self.homeModules; [ ai-agents ];

  home = {
    stateVersion = "26.05";
    sessionVariables.EDITOR = "nvim";
  };

}
