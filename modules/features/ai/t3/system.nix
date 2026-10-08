{ inputs, ... }@args:
{
  imports = [ inputs.self."${args._class}Modules".tailscale ];

  liberion.network.tailscale.expose.t3 = {
    port = 8443;
    target = "http://127.0.0.1:3773";
  };
}
