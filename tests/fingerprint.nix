{ lib, self }:
let
  home =
    self.nixosConfigurations.oulu.config.home-manager.users.${lib.liberion.identity.user};
  fingerprint =
    config:
    import (self + "/scripts/ci/fingerprint.nix") {
      flake = self // {
        nixosConfigurations = { };
        darwinConfigurations = { };
        homeConfigurations.oulu = { inherit config; };
      };
    };
  before = fingerprint home;
  failures = lib.runTests {
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
