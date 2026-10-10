{ pkgs, ... }: {
  programs.bun.enable = true;

  liberion.maintenance.tasks.bun.command = [
    "${pkgs.writeShellScript "bun-cache-clean" ''
      ${pkgs.findutils}/bin/find "$HOME/.bun/install/cache" "''${XDG_CACHE_HOME:-$HOME/.cache}/.bun/install/cache" -mindepth 1 -delete 2>/dev/null || true
    ''}"
  ];
}
