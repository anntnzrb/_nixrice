{
  config,
  inputs,
  lib,
  ...
}:
let
  cfg = config.liberion.ai.t3;
  runtime = "${config.system.primaryUserHome}/.t3/runtime";
in
{
  imports = [ inputs.self.darwinModules.homebrew ];

  options.liberion.ai.t3.desktop = lib.liberion.module.mkOptDisabled';

  config = {
    liberion.darwin.homebrew.apps = lib.mkIf cfg.desktop [ "t3-code" ];

    liberion.darwin.owned = {
      files =
        lib.genAttrs
          (map (name: "${runtime}/${name}") [
            "stable"
            "stable.old"
            "stable.new"
          ])
          (_: {
            recursive = true;
          })
        // lib.genAttrs (map (name: "${runtime}/${name}") [
          "stable.enabled"
          "stable.restart"
        ]) (_: { });
      launchdDisabled = [ "com.t3tools.t3code.service" ];
    };
  };
}
