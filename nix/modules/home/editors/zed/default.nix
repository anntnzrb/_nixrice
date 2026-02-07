# https://github.com/nix-community/home-manager/blob/master/modules/programs/zed-editor.nix
{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module)
    mkOpt'
    mkOptDisabled'
    off
    ;
  inherit (lib.types)
    listOf
    package
    ;

  cfg = config.${namespace}.editors.zed;
in
{
  options.${namespace}.editors.zed = {
    enable = mkOptDisabled';

    package = mkOpt' lib.types.package pkgs.zed-editor;

    extraPackages = mkOpt' (listOf package) [
      pkgs.nixd
      pkgs.nixfmt
    ];
  };

  config = lib.mkIf cfg.enable {
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
        zed = off // {
          source = ./${configFile};
          target = "zed/${configFile}";
          recursive = true;
        };
      };
  };
}
