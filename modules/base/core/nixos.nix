# NixOS baseline for every liberion host.
{ lib, ... }:
let
  defaultLocale = "en_US.UTF-8";
in
{
  time.timeZone = "America/Guayaquil";

  i18n = {
    inherit defaultLocale;
    extraLocaleSettings = lib.genAttrs [
      "LC_ADDRESS"
      "LC_IDENTIFICATION"
      "LC_MEASUREMENT"
      "LC_MONETARY"
      "LC_NAME"
      "LC_NUMERIC"
      "LC_PAPER"
      "LC_TELEPHONE"
      "LC_TIME"
    ] (_: defaultLocale);
  };

  system.stateVersion = lib.mkDefault "22.05";

  # liberion hosts own their defaults; clan-installed machines opt in
  clan.core.enableRecommendedDefaults = lib.mkDefault false;

  # the channel tarball behind clan-core/nixpkgs ships programs.sqlite, which
  # would switch command-not-found on; keep it off as before
  programs.command-not-found.enable = lib.mkDefault false;
}
