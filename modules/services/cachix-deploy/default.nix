{ lib, ... }: {
  _class = "clan.service";
  manifest.name = "cachix-deploy";
  manifest.description = "Cachix Deploy agents that activate systems CI already built and cached";

  roles.agent = {
    description = "Runs a Cachix Deploy agent named after the machine";
    perInstance =
      { machine, ... }:
      let
        generators.cachix-agent = {
          prompts.token = {
            description = "Cachix Deploy agent token for ${machine.name}";
            type = "hidden";
          };
          files.env = { };
          script = ''
            printf 'CACHIX_AGENT_TOKEN=%s\n' "$(<"$prompts/token")" > "$out/env"
          '';
        };
        env = config: config.clan.core.vars.generators.cachix-agent.files.env.path;
      in
      {
        nixosModule = { config, ... }: {
          clan.core.vars = { inherit generators; };

          services.cachix-agent = {
            enable = true;
            inherit (machine) name;
            credentialsFile = env config;
          };
        };

        # nix-darwin's services.cachix-agent asserts nix.enable, which
        # Determinate Nix turns off. The agent's darwin profile defaults to
        # system-profiles/system; `system` keeps darwin-rebuild's profile.
        darwinModule = { config, pkgs, ... }: {
          clan.core.vars = { inherit generators; };

          launchd.daemons.cachix-agent = {
            script = ''
              /bin/wait4path ${lib.escapeShellArg (env config)}
              set -a
              . ${lib.escapeShellArg (env config)}
              set +a
              exec ${lib.getExe pkgs.cachix} deploy agent ${lib.escapeShellArg machine.name} system
            '';
            environment = {
              PATH = "/nix/var/nix/profiles/default/bin:/usr/bin:/bin:/usr/sbin:/sbin";
              NIX_SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
              USER = "root";
            };
            serviceConfig = {
              RunAtLoad = true;
              KeepAlive = true;
              StandardOutPath = "/var/log/cachix-agent.log";
              StandardErrorPath = "/var/log/cachix-agent.log";
            };
          };
        };
      };
  };
}
