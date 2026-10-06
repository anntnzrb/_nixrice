{ lib, ... }: {
  imports = [
    (lib.liberion.gitCheckout {
      name = "ai-agents";
      description = "agents";
      repository = "https://github.com/anntnzrb/agents.git";
      destination = "src/agents";
      branch = "main";
      update =
        { config, pkgs }:
        let
          home = config.home.homeDirectory;
          user = config.home.username;
        in
        pkgs.writeShellApplication {
          name = "sync-ai-agents";
          runtimeInputs = [ pkgs.uv ];
          text = ''
            export PATH="$PATH:${
              lib.concatStringsSep ":" [
                "${home}/.local/bin"
                "${home}/.bun/bin"
                "${home}/.nix-profile/bin"
                "/etc/profiles/per-user/${user}/bin"
                "/run/current-system/sw/bin"
                "/nix/var/nix/profiles/default/bin"
                "/usr/bin"
                "/bin"
                "/usr/sbin"
                "/sbin"
              ]
            }"
            runtime="${home}/.local/share/agents/sync-current/.venv/bin/python"
            if [ -x "$runtime" ]; then
              exec "$runtime" -m sync.cli update
            fi
            exec uv run --quiet --project "$1/sync" sync update
          '';
        };
    })
  ];
}
