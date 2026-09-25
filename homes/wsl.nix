{ inputs, ... }: {
  imports = with inputs.self.homeModules; [
    default
    bash
  ];
}
