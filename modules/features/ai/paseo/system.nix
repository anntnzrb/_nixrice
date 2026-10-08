{ inputs, ... }@args:
{
  imports = [ inputs.self."${args._class}Modules".tailscale ];

  liberion.network.tailscale.expose.paseo = {
    port = 6767;
    target = "http://127.0.0.1:6767";
  };
}
