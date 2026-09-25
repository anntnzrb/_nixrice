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
}
