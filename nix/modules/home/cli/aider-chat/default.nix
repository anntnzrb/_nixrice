{
  config,
  lib,
  system,
  namespace,
  inputs,
  ...
}:
let
  cfg = config.${namespace}.cli.aider-chat;
in
{
  options.${namespace}.cli.aider-chat = with lib.${namespace}; {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = [ inputs.nurpkgs.packages.${system}.aider-chat ];
      shellAliases.aider = "aider --cache-prompts --pretty --stream";
    };
  };
}
