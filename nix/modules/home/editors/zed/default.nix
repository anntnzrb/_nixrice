# https://github.com/nix-community/home-manager/blob/master/modules/programs/zed-editor.nix
{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.editors.zed;
in
{
  options.${namespace}.editors.zed = with lib.${namespace}; {
    enable = mkOptBool';

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.zed-editor;
      description = "The Zed editor package";
    };

    extraPackages = lib.mkOption {
      type = with lib.types; listOf package;
      default = [
        pkgs.nixd
        pkgs.nixfmt-rfc-style
      ];
      description = "Extra packages available to Zed.";
    };
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
