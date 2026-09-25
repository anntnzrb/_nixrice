import ../../../toggle.nix "cli.aider-chat" (
  { lib, pkgs, ... }: {
    home = {
      packages = [ pkgs.aider-chat ];
      shellAliases.aider = "${lib.getExe pkgs.aider-chat} --cache-prompts --pretty --stream";
    };
  }
)
