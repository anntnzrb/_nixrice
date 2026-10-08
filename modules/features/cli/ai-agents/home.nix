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
    (lib.liberion.userJob {
      name = "agents-refresh-packages";
      description = "Install newer agent harness and tool releases";
      schedule = 900;
      startup = 300;
      command = sync ++ [
        "job"
        "refresh-packages"
      ];
    })
  ];

  liberion.maintenance.tasks.npm.command = sync ++ [
    "job"
    "npm-cache-clean"
  ];
}
