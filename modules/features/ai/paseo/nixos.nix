{ inputs, lib, ... }: {
  imports = [ inputs.self.nixosModules.tailscale ];

  liberion.network.tailscale.expose.paseo = {
    port = 6767;
    target = "http://127.0.0.1:6767";
  };

  users.users.${lib.liberion.identity.user}.linger = true;
}
