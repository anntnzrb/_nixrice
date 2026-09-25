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
