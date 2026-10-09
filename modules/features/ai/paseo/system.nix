{ inputs, ... }@args:
let
  port = import ./port.nix;
in
{
  imports = [ inputs.self."${args._class}Modules".tailscale ];

  liberion.network.tailscale.expose.paseo = {
    inherit port;
    target = "http://127.0.0.1:${toString port}";
  };
}
