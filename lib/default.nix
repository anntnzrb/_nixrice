{ lib }:
let
  identity = import ../identity.nix;

  mkOpt' =
    type: default:
    lib.mkOption {
      inherit type default;
      description = null;
    };

  classes = [
    "nixos"
    "darwin"
    "home"
    "system"
  ];

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

  load =
    roots:
    let
      base = discover roots.base;
      features = discover roots.features;
      profiles = discover roots.profiles;

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
      inherit modules;

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
    };

  fleet = load {
    base = ../modules/base;
    features = ../modules/features;
    profiles = ../modules/profiles;
  };
in
{
  inherit identity load;
  inherit (fleet) modules machineModule;

  module = {
    inherit mkOpt';
    mkOptEnabled' = mkOpt' lib.types.bool true;
    mkOptDisabled' = mkOpt' lib.types.bool false;
  };

  darwin = {
    asUser =
      user:
      ''launchctl asuser "$(id -u -- ${lib.escapeShellArg user})" sudo --user=${lib.escapeShellArg user} --'';

    activateSettings = "/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u";

    writeDefault =
      {
        domain,
        key,
        value,
        currentHost ? false,
      }:
      lib.concatStringsSep " " (
        [ "defaults" ]
        ++ lib.optional currentHost "-currentHost"
        ++ [
          "write"
          (lib.escapeShellArg domain)
          (lib.escapeShellArg key)
          (lib.escapeShellArg (lib.generators.toPlist { escape = true; } value))
        ]
      );

    openAtLogin = app: managedBy: {
      inherit managedBy;
      serviceConfig = {
        ProgramArguments = [
          "/usr/bin/open"
          "-a"
          "/Applications/${app}.app"
        ];
        RunAtLoad = true;
        KeepAlive = false;
        ProcessType = "Interactive";
        LimitLoadToSessionType = [ "Aqua" ];
      };
    };
  };

  xorg.mkAutostartScript = xs: lib.concatStringsSep "\n" (map (x: x + " &") xs);
}
