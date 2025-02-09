{
  lib,
  config,
  inputs,
  namespace,
  ...
}:
let
  inherit (lib)
    mkIf
    optionalAttrs
    ;
  inherit (inputs) yazi-plugins-githead;

  cfg = config.${namespace}.cli.yazi;
in
{
  config.programs.yazi = {
    plugins = optionalAttrs cfg.plugin.githead.enable {
      githead = yazi-plugins-githead;
    };

    initLua = mkIf cfg.plugin.githead.enable ''require("githead"):setup()'';
  };
}
