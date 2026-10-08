{ inputs, ... }: {
  imports = [ inputs.self.darwinModules.tailscale ];

  liberion.network.tailscale.expose.paseo = {
    port = 6767;
    target = "http://127.0.0.1:6767";
  };
}
