# Repository helpers exposed as `lib.liberion`.
{ lib }:
let
  identity = import ../identity.nix;

  # Description-free option (no generated option docs).
  mkOpt' =
    type: default:
    lib.mkOption {
      inherit type default;
      description = null;
    };

  # Class files: nixos.nix, darwin.nix, home.nix, and system.nix (NixOS and
  # nix-darwin alike).
  classes = [
    "nixos"
    "darwin"
    "home"
    "system"
  ];

  # Every directory below `root` holding class files, keyed by the directory
  # name: { <name> = { <class> = path; }; }. Paths containing `/_` are skipped.
  discover =
    root:
    let
      isClassFile =
        path:
        let
          rel = lib.removePrefix (toString root) (toString path);
        in
        !(lib.hasInfix "/_" rel)
        && builtins.elem (baseNameOf rel) (map (c: "${c}.nix") classes);
      byDir = lib.groupBy (path: toString (dirOf path)) (
        builtins.filter isClassFile (lib.filesystem.listFilesRecursive root)
      );
      named = lib.mapAttrs' (
        dir: paths:
        lib.nameValuePair (baseNameOf dir) (
          lib.listToAttrs (
            map (p: lib.nameValuePair (lib.removeSuffix ".nix" (baseNameOf p)) p) paths
          )
        )
      ) byDir;
    in
    assert lib.assertMsg (
      lib.length (lib.attrNames named) == lib.length (lib.attrNames byDir)
    ) "two module directories below ${toString root} share a name";
    named;

  base = discover ../modules/base;
  features = discover ../modules/features;
  profiles = discover ../modules/profiles;

  # The `class` module of every entry that has one. A NixOS or nix-darwin
  # module is its class file plus system.nix and, when `route`, hands its
  # home.nix to the fleet user's Home Manager configuration.
  forClass =
    class: route:
    lib.concatMapAttrs (
      name: files:
      let
        own =
          lib.optional (class != "home" && files ? system) files.system
          ++ lib.optional (files ? ${class}) files.${class};
      in
      lib.optionalAttrs (own != [ ]) {
        ${name} =
          if class == "home" then
            files.home
          else
            {
              key = "liberion/${class}/${name}";
              imports =
                own
                ++ lib.optional (route && files ? home) {
                  home-manager.users.${identity.user}.imports = [ files.home ];
                };
            };
      }
    );

  # Flake modules per class: every feature and profile by name, plus
  # `default` = the class's base.
  modules = lib.genAttrs [ "nixos" "darwin" "home" ] (
    class:
    assert lib.assertMsg (
      lib.intersectLists (lib.attrNames features) (lib.attrNames profiles) == [ ]
    ) "a feature and a profile share a name";
    forClass class true (features // profiles)
    // {
      default.imports = lib.attrValues (forClass class false base);
    }
  );
in
{
  inherit identity modules;

  # What clan.nix gives a machine: its class's base, the profile named after
  # each of its tags (modules/profiles/<tag>), and its home.nix, if any, as the
  # fleet user's Home Manager configuration on top of the home base.
  machineModule = class: tags: home: {
    imports = [
      modules.${class}.default
    ]
    ++ lib.optional (builtins.pathExists home) {
      home-manager.users.${identity.user}.imports = [
        modules.home.default
        home
      ];
    }
    ++ map (tag: modules.${class}.${tag}) (
      builtins.filter (tag: profiles ? ${tag} && modules.${class} ? ${tag}) tags
    );
  };

  module = {
    inherit mkOpt';
    mkOptEnabled' = mkOpt' lib.types.bool true; # default-on knob
    mkOptDisabled' = mkOpt' lib.types.bool false; # opt-in knob
  };

  xorg.mkAutostartScript = xs: lib.concatStringsSep "\n" (map (x: x + " &") xs);
}
