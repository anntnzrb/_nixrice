{ lib, self }:
let
  inherit (lib.liberion) identity load;

  fixtures = ./fixtures;
  tree = load {
    base = fixtures + "/base";
    features = fixtures + "/features";
    profiles = fixtures + "/profiles";
  };
  svc = fixtures + "/features/net/svc";
  tool = fixtures + "/features/cli/tool/home.nix";
  routed = home: { home-manager.users.${identity.user}.imports = [ home ]; };
  throws = x: !(builtins.tryEval (builtins.deepSeq x x)).success;
  fixtureLib = import (self + "/lib") {
    inherit lib;
    root = fixtures;
  };

  libFailures = lib.runTests {
    testRouteHome = {
      expr = lib.liberion.routeHome [ tool ];
      expected = routed tool;
    };
    testMkReq = {
      expr =
        let
          option = lib.liberion.module.mkReq' lib.types.str;
        in
        option ? type
        && option.type.name == "str"
        && !(option ? default)
        && !(option ? description);
      expected = true;
    };
    testTailscaleExposeServe = {
      expr = lib.liberion.tailscaleExpose "/bin/tailscale" "paseo" {
        funnel = false;
        port = 6767;
        target = "http://127.0.0.1:6767";
      };
      expected = {
        description = "Tailscale Serve mapping paseo";
        start = "/bin/tailscale serve --bg --https=6767 http://127.0.0.1:6767";
        stop = "/bin/tailscale serve --https=6767 off";
      };
    };
    testTailscaleExposeFunnel = {
      expr = lib.liberion.tailscaleExpose "/bin/tailscale" "web" {
        funnel = true;
        port = 443;
        target = "http://localhost:8080/app";
      };
      expected = {
        description = "Tailscale Funnel mapping web";
        start = "/bin/tailscale funnel --bg --https=443 http://localhost:8080/app";
        stop = "/bin/tailscale funnel --https=443 off";
      };
    };
    testFleetPeers = {
      expr = lib.attrNames (
        lib.liberion.fleetPeers {
          self.tags = [ ];
          peer.tags = [ "server" ];
          retired.tags = [ "archived" ];
        } "self"
      );
      expected = [ "peer" ];
    };
    testDarwinHomebrewApps = {
      expr = lib.liberion.darwin.homebrewApps [ "firefox" "brave" ] {
        inputs.self.darwinModules.homebrew = "homebrew-module";
      };
      expected = {
        imports = [ "homebrew-module" ];
        liberion.darwin.homebrew.apps = [
          "firefox"
          "brave"
        ];
      };
    };
    testHomeNames = {
      expr = lib.attrNames tree.modules.home;
      expected = [
        "default"
        "svc"
        "tool"
      ];
    };
    testNixosNames = {
      expr = lib.attrNames tree.modules.nixos;
      expected = [
        "default"
        "svc"
      ];
    };
    testDarwinNames = {
      expr = lib.attrNames tree.modules.darwin;
      expected = [
        "default"
        "desktop"
        "svc"
      ];
    };
    testSystemFeature = {
      expr = tree.modules.nixos.svc;
      expected = {
        key = "liberion/nixos/svc";
        imports = [
          (svc + "/system.nix")
          (svc + "/nixos.nix")
          (routed (svc + "/home.nix"))
        ];
      };
    };
    testSystemFileFeedsDarwin = {
      expr = tree.modules.darwin.svc.imports;
      expected = [
        (svc + "/system.nix")
        (routed (svc + "/home.nix"))
      ];
    };
    testHomeFeatureIsItsFile = {
      expr = tree.modules.home.tool;
      expected = tool;
    };
    testBaseNotRouted = {
      expr = tree.modules.nixos.default.imports;
      expected = [
        {
          key = "liberion/nixos/core";
          imports = [ (fixtures + "/base/core/nixos.nix") ];
        }
      ];
    };
    testMachineTagsAndHome = {
      expr = (tree.machineModule "darwin" [ "desktop" "laptop" ] tool).imports;
      expected = [
        tree.modules.darwin.default
        {
          home-manager.users.${identity.user}.imports = [
            tree.modules.home.default
            tool
          ];
        }
        tree.modules.darwin.desktop
      ];
    };
    testMachineWithoutHome = {
      expr =
        (tree.machineModule "nixos" [ "desktop" ] (fixtures + "/missing.nix")).imports;
      expected = [ tree.modules.nixos.default ];
    };
    testDuplicateNamesThrow = {
      expr = throws (
        lib.attrNames
          (load {
            base = fixtures + "/base";
            features = fixtures + "/dup";
            profiles = fixtures + "/profiles";
          }).modules.home
      );
      expected = true;
    };
    testDarwinWriteDefaultCurrentHost = {
      expr = lib.liberion.darwin.writeDefault {
        domain = "-g";
        key = "a key";
        value = true;
        currentHost = true;
      };
      expected = "defaults -currentHost write -g 'a key' ${
        lib.escapeShellArg (lib.generators.toPlist { escape = true; } true)
      }";
    };
    testDarwinWriteDefaultUserDomain = {
      expr = lib.hasPrefix "defaults write com.example n " (
        lib.liberion.darwin.writeDefault {
          domain = "com.example";
          key = "n";
          value = 1;
        }
      );
      expected = true;
    };
    testDarwinWriteDefaultsSkipsNull = {
      expr = lib.liberion.darwin.writeDefaults "u" {
        domain = "d";
        settings = {
          a = 1;
          b = null;
        };
        currentHost = true;
      };
      expected = [
        "${lib.liberion.darwin.asUser "u"} ${
          lib.liberion.darwin.writeDefault {
            domain = "d";
            key = "a";
            value = 1;
            currentHost = true;
          }
        }"
      ];
    };
    testDarwinAquaAgentMergesServiceConfig = {
      expr = lib.liberion.darwin.aquaAgent "m" {
        command = "c";
        serviceConfig.KeepAlive = true;
      };
      expected = {
        managedBy = "m";
        command = "c";
        serviceConfig = {
          RunAtLoad = true;
          KeepAlive = true;
          ProcessType = "Interactive";
          LimitLoadToSessionType = [ "Aqua" ];
        };
      };
    };
    testIsArchived = {
      expr = map lib.liberion.isArchived [
        { tags = [ "archived" ]; }
        { tags = [ "server" ]; }
      ];
      expected = [
        true
        false
      ];
    };
    testVarValueStripsNewline = {
      expr = fixtureLib.varValue "per-machine/m/gen/key.pub";
      expected = "ssh-ed25519 AAAA m";
    };
    testVarValueTrimsTrailingSpace = {
      expr = fixtureLib.varValue "per-machine/m/gen/host.pub";
      expected = "ssh-ed25519 AAAA";
    };
    testVarValueMissingIsNull = {
      expr = fixtureLib.varValue "per-machine/m/gen/absent";
      expected = null;
    };
    testFeatureProfileClashThrows = {
      expr = throws (
        lib.attrNames
          (load {
            base = fixtures + "/base";
            features = fixtures + "/features";
            profiles = fixtures + "/features";
          }).modules.home
      );
      expected = true;
    };
  };

  admins =
    let
      keyFile = self + "/sops/users/${identity.user}/key.json";
      expected = lib.liberion.adminAgeKeys self.clan.inventory.machines;
      actual = map (key: key.publickey) (lib.importJSON keyFile);
    in
    lib.optional (lib.sort lib.lessThan expected != lib.sort lib.lessThan actual)
      "admins: sops/users/${identity.user} keys are not identity.keys.adminAge plus every admin machine's admin-age key; run `just admins`";

  layout = lib.concatLists (
    lib.mapAttrsToList (
      name: machine:
      let
        entries = builtins.readDir (self + "/machines/${name}");
        has = file: entries ? ${file};
        darwin = (machine.machineClass or "nixos") == "darwin";
        problems = {
          "has no configuration.nix" = !has "configuration.nix";
          "has no readme.md" = !has "readme.md";
          "has a subdirectory" = lib.any (type: type == "directory") (
            lib.attrValues entries
          );
          "has a file name with uppercase letters" = lib.any (
            file: lib.toLower file != file
          ) (lib.attrNames entries);
          "has both facter.json and hardware.nix" =
            has "facter.json" && has "hardware.nix";
          "is darwin but has facter.json, hardware.nix or disk.nix" =
            darwin
            && lib.any has [
              "facter.json"
              "hardware.nix"
              "disk.nix"
            ];
        };
      in
      lib.mapAttrsToList (what: _: "layout: machines/${name} ${what}") (
        lib.filterAttrs (_: bad: bad) problems
      )
    ) self.clan.inventory.machines
  );

  access =
    name: config:
    let
      port = identity.sshPort;
      ssh = config.services.openssh;
      checks = {
        "sshd is enabled" = ssh.enable;
        "admin key is authorized for ${identity.user}" =
          builtins.elem identity.keys.admin
            config.users.users.${identity.user}.openssh.authorizedKeys.keys;
      }
      // (
        if config ? launchd then
          {
            "sshd listens on ${toString port}" =
              config.launchd.daemons ? "sshd-${toString port}";
            "password login is off" =
              lib.hasInfix "PasswordAuthentication no" ssh.extraConfig;
          }
        else
          {
            "sshd listens on ${toString port}" = builtins.elem port ssh.ports;
            "password login is off" = ssh.settings.PasswordAuthentication == false;
            "firewall opens ${toString port}" =
              builtins.elem port config.networking.firewall.allowedTCPPorts;
          }
      );
    in
    lib.mapAttrsToList (what: _: "fleet: ${name}: ${what}") (
      lib.filterAttrs (_: ok: !ok) checks
    );
in
map (
  t:
  "lib: ${t.name}: expected ${builtins.toJSON t.expected}, got ${builtins.toJSON t.result}"
) libFailures
++ admins
++ layout
++ import ./fingerprint.nix { inherit lib self; }
++ lib.concatLists (
  lib.mapAttrsToList (name: c: access name c.config) (
    self.nixosConfigurations // self.darwinConfigurations
  )
)
