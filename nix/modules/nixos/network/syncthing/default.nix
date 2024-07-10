{ config
, lib
, ...
}:
let
  cfg = config.liberion.network.syncthing;
in
{
  options.liberion.network.syncthing = with lib.liberion; {
    enable = mkOptBool';
  };

  config =
    let
      user = config.liberion.nixos.user.name;
      syncPath = "/home/${user}/lib/sync";
    in
    lib.mkIf cfg.enable {
      services.syncthing = {
        enable = true;
        systemService = true;

        # devices & folders will not persist if configured via UI
        overrideDevices = true;
        overrideFolders = true;

        inherit user;
        dataDir = "/home/${user}";
        guiAddress = "127.0.0.1:8384";

        settings = {
          gui.theme = "black";

          devices = {
            bergkamp = {
              id = "MSDOPIX-KG24CTY-PJVNQCC-NSDUVWT-MHB6D57-GHFO2FG-YT6MKCX-QBHQZQD";
              name = "bergkamp";
            };
          };

          folders =
            let
              devices = [ "bergkamp" ];
            in
            {
              notes = {
                enable = true;
                label = "notes";
                path = "${syncPath}/notes";
                versioning.type = "trashcan";
                inherit devices;
              };

              bergkamp = {
                enable = true;
                label = "bergkamp";
                path = "${syncPath}/bergkamp";
                versioning.type = "trashcan";
                inherit devices;
              };
            };

          options = {
            limitBandwidthInLan = false;
            localAnnounceEnabled = true;
            urAccepted = -1;
          };
        };
      };
    };
}
