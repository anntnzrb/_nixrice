{
  config,
  lib,
  pkgs,
  ...
}:
let
  home = config.home.homeDirectory;
  root = "${home}/src/vendored";
  command = "${home}/.local/bin/vendored-update";
  updater = import ./package.nix { inherit pkgs; };
in
{
  imports = [
    (lib.liberion.userJob {
      name = "vendored-update";
      description = "Refresh disposable upstream source checkouts";
      command = [
        command
        root
      ];
      schedule = 28800;
      startup = 60;
    })
  ];

  home.file.".local/bin/vendored-update".source = lib.getExe updater;

  home.activation.vendoredDirectories =
    lib.hm.dag.entryAfter [ "writeBoundary" ]
      ''
        run mkdir -p ${lib.escapeShellArg root} ${lib.optionalString pkgs.stdenv.hostPlatform.isDarwin (lib.escapeShellArg "${home}/Library/Logs")}
      '';
}
