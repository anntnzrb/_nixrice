{
  inputs,
  ...
}:
{
  imports = [ inputs.betterfox-nix.homeManagerModules.betterfox ];

  config.programs.firefox = {
    betterfox.enable = true;
    profiles.default = {
      betterfox = {
        enable = true;
        fastfox.enable = true;
        peskyfox.enable = true;
        securefox.enable = true;
        smoothfox.enable = true;
      };
    };
  };
}
