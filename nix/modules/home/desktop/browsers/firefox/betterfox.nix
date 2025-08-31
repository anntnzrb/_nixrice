{
  inputs,
  ...
}:
{
  imports = [ inputs.betterfox-nix.homeModules.betterfox ];

  config.programs.firefox = {
    betterfox = {
      enable = true;

      profiles.default = {
        enableAllSections = true;
      };
    };
  };
}
