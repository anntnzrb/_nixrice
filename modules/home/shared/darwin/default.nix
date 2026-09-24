{
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = [ inputs.nix-spotlight.homeManagerModules.default ];

  config = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    programs.nix-spotlight.enable = true;

    # Formula binaries live under Homebrew's Apple
    # Silicon prefix; expose them on PATH without /opt paths.
    home.sessionPath = [ "/opt/homebrew/bin" ];
  };
}
