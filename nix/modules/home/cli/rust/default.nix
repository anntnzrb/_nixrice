{
  config,
  lib,
  pkgs,
  inputs,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.cli.rust;
in
{
  options.${namespace}.cli.rust = {
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
