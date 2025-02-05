# https://github.com/nix-community/home-manager/blob/master/modules/programs/zed-editor.nix
{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace})
    mkOpt'
    mkOptBool'
    ;
  inherit (lib.types)
    listOf
    package
    ;

  cfg = config.${namespace}.editors.zed;
in
{
  options.${namespace}.editors.zed = {
    enable = mkOptBool';

    package = mkOpt' lib.types.package pkgs.zed-editor;

    extraPackages = mkOpt' listOf package [
      pkgs.nixd
      pkgs.nixfmt-rfc-style
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
        cfg = "settings.json";
      in
      {
        zed = {
          enable = false;
          source = ./${cfg};
          target = "${config.xdg.configHome}/zed/${cfg}";
          recursive = true;
        };
      };
  };
}
