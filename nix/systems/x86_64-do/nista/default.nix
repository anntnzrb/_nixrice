{
  lib,
  pkgs,
  inputs,
  namespace,
  ...
}:

let
  inherit (lib.${namespace}.module) on;

  login = {
    name = "nixos";
    initialPassword = "nixos";
  };
in
{
  services.openssh = on;

  environment.systemPackages = with pkgs; [
    # tools
    git

    # editors
    inputs.neovim-annt.packages.${pkgs.stdenv.hostPlatform.system}.nvf # vi-like
  ];

  ${namespace} = {
    user = {
      inherit (login) name initialPassword;
    };

    network = {
      networkmanager = on;
    };
  };
}
