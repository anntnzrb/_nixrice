import ../../../toggle.nix "cli.repomix" (
  { lib, pkgs, ... }: {
    home.shellAliases.repomix = "${lib.getExe' pkgs.bun "bun"} x repomix@latest --";
  }
)
