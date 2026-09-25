# Eval-time tests, run by `nix flake check` (checks.<system>.tests): module
# discovery and wiring in lib/ against tests/fixtures, and access invariants
# of every real machine. Evaluates to the list of failures; empty = pass.
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

  libFailures = lib.runTests {
    testHomeNames = {
      expr = lib.attrNames tree.modules.home;
      expected = [
        "default"
        "svc"
        "tool"
      ];
    };
    # a home-only feature is no system module; a darwin-only profile no nixos one
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
    # class file + system.nix, and home.nix routed to the owner; `/_` skipped
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
    # base modules never create a Home Manager user
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

  # Every machine stays reachable over fleet SSH: the owner's admin key, the
  # fleet port, and (NixOS) no password logins and the port open.
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
++ lib.concatLists (
  lib.mapAttrsToList (name: c: access name c.config) (
    self.nixosConfigurations // self.darwinConfigurations
  )
)
