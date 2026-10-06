{ lib, self, ... }: {
  perSystem =
    {
      config,
      inputs',
      pkgs,
      ...
    }:
    {
      treefmt = {
        programs = {
          nixfmt = {
            enable = true;
            strict = true;
            width = 80;
          };
          shfmt = {
            enable = true;
            indent_size = 4;
            excludes = [ ".envrc" ];
          };
          just.enable = true;
        };
        settings.formatter.shfmt.options = [
          "-ln"
          "posix"
          "-bn"
          "-ci"
        ];
      };

      pre-commit.settings.hooks = {
        treefmt.enable = true;

        deadnix = {
          enable = true;
          args = [ "--warn-used-underscore" ];
          settings.edit = true;
        };

        statix.enable = true;

        no-parent-paths = {
          enable = true;
          name = "no-parent-paths";
          description = "Reach other directories from the repo root (self, inputs.self, root), never through parent directories";
          files = "\\.(nix|sh)$";
          entry = toString (
            pkgs.writeShellScript "no-parent-paths" ''
              if ${pkgs.gnugrep}/bin/grep -nE '\.\./|/\.\.(["/)]|$)' "$@"; then
                echo "parent-relative paths are not allowed; anchor them at the repo root" >&2
                exit 1
              fi
            ''
          );
        };

        shellcheck = {
          enable = true;
          args = [
            "--enable=all"
            "-a"
            "-x"
            "-P"
            "SCRIPTDIR"
          ];
        };

        actionlint.enable = true;

        zizmor = {
          enable = true;
          args = [ "--no-exit-codes" ];
        };
      };

      checks.tests =
        let
          failures = import "${self}/tests" { inherit lib self; };
          vendoredUpdater = import (self + "/modules/base/vendored/package.nix") {
            inherit pkgs;
          };
        in
        if failures == [ ] then
          pkgs.runCommand "liberion-tests"
            {
              nativeBuildInputs = [
                pkgs.jq
                pkgs.git
                pkgs.flock
              ];
            }
            ''
              bash ${self}/tests/reconcile.sh ${self}/modules/base/reconcile/reconcile.sh
              bash ${self}/tests/vendored.sh ${lib.getExe vendoredUpdater}
              touch $out
            ''
        else
          throw "tests failed:\n${lib.concatStringsSep "\n" failures}";

      devShells.default = pkgs.mkShellNoCC {
        name = "liberion-shell";
        inherit (config.pre-commit) shellHook;
        nativeBuildInputs = config.pre-commit.settings.enabledPackages ++ [
          inputs'.clan-core.packages.clan-cli
          pkgs.just
        ];
      };
    };
}
