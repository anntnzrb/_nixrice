# `liberion.programs.<name>.enable` for every Homebrew app; apps needing more
# than the install (aldente, raycast) add it in their own module.
{ lib, config, ... }:
let
  inherit (lib.liberion.module) mkOptDisabled';

  casks = {
    aldente = "aldente";
    obs = "obs";
    # OrbStack updates itself and installs a privileged helper, so it lives in
    # /Applications as a cask rather than in the read-only Nix store.
    orbstack = "orbstack";
    raycast = "raycast";
    rustdesk = "rustdesk";
    vlc = "vlc";
    vscode = "visual-studio-code";
  };

  masApps = {
    bitwarden.Bitwarden = 1352778147;
    whatsapp."WhatsApp Messenger" = 310633997;
  };

  enabled = lib.filterAttrs (name: _: config.liberion.programs.${name}.enable);
in
{
  options.liberion.programs = lib.mapAttrs (_: _: { enable = mkOptDisabled'; }) (
    casks // masApps
  );

  config.liberion.homebrew.packages = {
    # reversed to keep the list-merge order these had as separate modules
    casks = lib.reverseList (lib.attrValues (enabled casks));
    masApps = lib.mergeAttrsList (lib.attrValues (enabled masApps));
  };
}
