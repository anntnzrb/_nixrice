{ config, lib, ... }:
let
  runtime = "${config.system.primaryUserHome}/.t3/runtime";
in
{
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
}
