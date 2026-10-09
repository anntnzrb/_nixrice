{ inputs, lib, ... }:
let
  defaultLocale = "en_US.UTF-8";
in
{
  imports = [ inputs.self.nixosModules.sshd ];

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

  documentation.nixos.enable = false;

  programs.command-not-found.enable = lib.mkDefault false;
}
