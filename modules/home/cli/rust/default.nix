{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib.liberion.module) mkOptDisabled';

  cfg = config.liberion.cli.rust;
in
{
  options.liberion.cli.rust = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (
        inputs.fenix.packages.${pkgs.stdenv.hostPlatform.system}.complete.withComponents
          [
            "cargo"
            "rustc"
            "clippy"
            "rustfmt"
          ]
      )
    ];
  };
}
