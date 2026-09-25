# Lists the liberion toggles a machine turns on, for the system and each Home
# Manager user; subtrees under a disabled toggle are skipped.
{ flake, machine }:
let
  f = builtins.getFlake flake;
  inherit (f.inputs.nixpkgs) lib;
  config = (f.nixosConfigurations // f.darwinConfigurations).${machine}.config;

  enabled =
    prefix: v:
    let
      on = v.enable or null;
      here = lib.optional (on == true) (lib.concatStringsSep "." prefix);
      below = lib.concatLists (
        lib.mapAttrsToList (
          n: x:
          let
            r = builtins.tryEval x;
          in
          if
            n != "enable"
            && r.success
            && builtins.isAttrs r.value
            && !lib.isDerivation r.value
          then
            enabled (prefix ++ [ n ]) r.value
          else
            [ ]
        ) v
      );
    in
    if on == false then [ ] else here ++ below;

  show = scope: tree: map (p: "${scope} ${p}\n") (enabled [ ] tree);
in
lib.concatStrings (
  show "system" config.liberion
  ++ lib.concatLists (
    lib.mapAttrsToList (
      user: hm: show "home:${user}" (hm.liberion or { })
    ) config.home-manager.users
  )
)
