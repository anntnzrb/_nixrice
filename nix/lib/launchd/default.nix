{ lib, ... }:
let
  mkDarwinAgent =
    {
      name,
      serviceConfig,
      managedBy ? null,
    }:
    {
      launchd.user.agents.${name} = {
        inherit serviceConfig;
      }
      // lib.optionalAttrs (managedBy != null) { inherit managedBy; };
    };

  mkDarwinGuiAppAgent =
    {
      name,
      app,
      managedBy ? null,
      keepAlive ? false,
      runAtLoad ? true,
      processType ? "Interactive",
      sessionTypes ? [ "Aqua" ],
      openArgs ? [ ],
      serviceConfig ? { },
    }:
    mkDarwinAgent {
      inherit name managedBy;
      serviceConfig = {
        ProgramArguments = [
          "/usr/bin/open"
          "-a"
          app
        ]
        ++ openArgs;
        RunAtLoad = runAtLoad;
        KeepAlive = keepAlive;
        ProcessType = processType;
        LimitLoadToSessionType = sessionTypes;
      }
      // serviceConfig;
    };

  mkHomeAgent =
    {
      name,
      serviceConfig,
      enable ? true,
    }:
    {
      launchd.agents.${name} = {
        inherit enable;
        config = serviceConfig;
      };
    };
in
{
  launchd = {
    darwin = {
      mkAgent = mkDarwinAgent;
      mkGuiAppAgent = mkDarwinGuiAppAgent;
    };

    home = {
      mkAgent = mkHomeAgent;
    };
  };
}
