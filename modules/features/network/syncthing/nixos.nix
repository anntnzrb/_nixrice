{ lib, ... }: {
  config =
    let
      user = lib.liberion.identity.user;
      syncPath = "/home/${user}/lib/sync";
    in
    {
      services.syncthing = {
        enable = true;
        systemService = true;

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

          folders = lib.genAttrs [ "notes" "bergkamp" ] (name: {
            enable = true;
            label = name;
            path = "${syncPath}/${name}";
            versioning.type = "trashcan";
            devices = [ "bergkamp" ];
          });

          options = {
            limitBandwidthInLan = false;
            localAnnounceEnabled = true;
            urAccepted = -1;
          };
        };
      };
    };
}
