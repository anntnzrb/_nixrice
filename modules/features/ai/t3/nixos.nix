{ inputs, lib, ... }: {
  imports = [ inputs.self.nixosModules.tailscale ];

  liberion.network.tailscale.expose.t3 = {
    port = 8443;
    target = "http://127.0.0.1:3773";
  };

  users.users.${lib.liberion.identity.user}.linger = true;
}
