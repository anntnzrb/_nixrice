{ config, lib, ... }:
let
  sync = lib.liberion.agentsSync config;
in
{
  imports = [
    (lib.liberion.gitCheckout {
      name = "ai-agents";
      description = "agents";
      repository = "https://github.com/anntnzrb/agents.git";
      destination = "src/agents";
      branch = "main";
      update =
        { pkgs, ... }:
        pkgs.writeShellApplication {
          name = "sync-ai-agents";
          runtimeInputs = [ pkgs.uv ];
          text = ''
            export PATH="$PATH:${lib.liberion.userPath config}"
            if [ -x ${lib.head sync} ]; then
              exec ${lib.escapeShellArgs sync} update
            fi
            exec uv run --quiet --project "$1/sync" sync update
          '';
        };
    })
  ];

  liberion.maintenance.tasks.npm.command = sync ++ [
    "job"
    "npm-cache-clean"
  ];
}
