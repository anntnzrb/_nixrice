{
  lib,
  pkgs,
  inputs,
  ...
}:

{
  # TODO: refactor when ollama is off unstable
  disabledModules = [ "services/misc/ollama.nix" ];
  imports = [
    ./hardware
  ] ++ [ (import (inputs.nixpkgs-unstable + "/nixos/modules/services/misc/ollama.nix")) ];

  liberion = with lib.liberion; {
    nixos = {
      user = {
        name = "annt";
        isNormalUser = true;
        extraGroups = [ "wheel" ];

        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHoPWVoRBmvoWF445a0vTnV2ASk+5Gy/XDTEPPjEDd8/ git"
        ];
      };

      time.timeZone = "America/Guayaquil";
    };

    # no dual-boot. systemd-boot suffices
    boot.bootloader.systemd-boot = on;

    hardware = {
      keyboard.keyd = on;
    };

    network = {
      networkmanager = on;
      ssh = on;
    };
  };

  console.font = "${pkgs.terminus_font}/share/fonts/consolefonts/ter-v8n.psf.gz";

  services = {
    logind = {
      lidSwitch = "ignore";
      lidSwitchDocked = "ignore";
      lidSwitchExternalPower = "ignore";
    };

    ollama = {
      enable = true;
      package = pkgs.ollama-cuda;

      acceleration = "cuda";
      port = 11434;
      loadModels = [ "llama3.1:8b" ];
    };
  };
}
