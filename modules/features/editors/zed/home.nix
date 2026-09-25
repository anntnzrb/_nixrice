# https://github.com/nix-community/home-manager/blob/master/modules/programs/zed-editor.nix
{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.liberion.module) mkOpt';
  inherit (lib.types) listOf package;

  cfg = config.liberion.editors.zed;
in
{
  options.liberion.editors.zed = {
    package = mkOpt' lib.types.package pkgs.zed-editor;

    extraPackages = mkOpt' (listOf package) [
      pkgs.nixd
      pkgs.nixfmt
    ];
  };

  config = {
    home.packages = [
      (pkgs.symlinkJoin {
        name = "${lib.getName cfg.package}-wrapped-${lib.getVersion cfg.package}";
        paths = [ cfg.package ];
        preferLocalBuild = true;
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/zeditor \
            --suffix PATH : ${lib.makeBinPath cfg.extraPackages}
        '';
      })
    ];

    xdg.configFile =
      let
        configFile = "settings.json";
      in
      {
        zed = {
          enable = false;
          source = ./${configFile};
          target = "zed/${configFile}";
          recursive = true;
        };
      };
  };
}
