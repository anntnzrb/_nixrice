{ lib, self }:
let
  inherit (lib.liberion.identity) user;

  home = self.nixosConfigurations.oulu.config.home-manager.users.${user};
  homeOptions =
    self.nixosConfigurations.oulu.options.home-manager.users.valueMeta.attrs.${user}.configuration.options;
  fingerprint =
    config:
    import (self + "/scripts/ci/fingerprint.nix") {
      flake = self // {
        nixosConfigurations = { };
        darwinConfigurations = { };
        homeConfigurations.oulu = {
          inherit config;
          options = homeOptions;
        };
      };
    };
  fingerprintWithOptions =
    config: options:
    import (self + "/scripts/ci/fingerprint.nix") {
      flake = self // {
        nixosConfigurations = { };
        darwinConfigurations = { };
        homeConfigurations.oulu = { inherit config options; };
      };
    };
  before = fingerprint home;
  failures = lib.runTests {
    testReportSkipsObsoleteProgramOptions = {
      expr =
        builtins.elem "current"
          (fingerprintWithOptions
            (
              home
              // {
                programs = home.programs // {
                  obsolete = throw "obsolete program was forced";
                  obsoleteEnable.enable = throw "obsolete enable was forced";
                  current.enable = true;
                };
              }
            )
            (
              homeOptions
              // {
                programs = homeOptions.programs // {
                  obsolete = {
                    visible = false;
                    description = "Alias of {option}`programs.other`.";
                  };
                  obsoleteEnable.enable = {
                    visible = false;
                    description = "Alias of {option}`programs.other.enable`.";
                  };
                  current.enable = {
                    visible = false;
                    description = "An enabled program.";
                  };
                };
              }
            )
          )."home:oulu".programs;
      expected = true;
    };
    testReportUserServiceRestart = {
      expr =
        before != fingerprint (
          lib.recursiveUpdate home {
            systemd.user.services.amp-runner.Service.RestartSec = 99;
          }
        );
      expected = true;
    };
    testReportUserTimerSchedule = {
      expr =
        before != fingerprint (
          lib.recursiveUpdate home {
            systemd.user.timers.amp-runner-update.Timer.OnUnitInactiveSec = 99;
          }
        );
      expected = true;
    };
    testReportLaunchdAgent = {
      expr =
        fingerprint (home // { launchd.agents.runner.config.ThrottleInterval = 5; })
        != fingerprint (
          home // { launchd.agents.runner.config.ThrottleInterval = 99; }
        );
      expected = true;
    };
  };
in
map (
  t:
  "fingerprint: ${t.name}: expected ${builtins.toJSON t.expected}, got ${builtins.toJSON t.result}"
) failures
