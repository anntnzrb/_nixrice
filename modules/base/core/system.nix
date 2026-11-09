{
  inputs,
  lib,
  pkgs,
  self,
  ...
}:
let
  editor = inputs.neovim-annt.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  clan.core.enableRecommendedDefaults = lib.mkDefault false;

  system.configurationRevision = self.rev or self.dirtyRev or null;

  environment = {
    systemPackages = [ editor ];
    variables = {
      EDITOR = lib.getExe editor;
      VISUAL = lib.getExe editor;
    };
  };

  security.sudo.extraConfig = ''
    Defaults timestamp_type=global
  '';
}
