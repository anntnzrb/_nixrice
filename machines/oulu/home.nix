{ lib, ... }:
let
  inherit (lib.liberion.module) on;
in
{
  imports = [ ../../modules/home.nix ];

  home.stateVersion = "26.05";

  liberion = {
    suites.common = on;
    shells.fish = on;
  };

  programs = {
    fish.interactiveShellInit = ''
      bind \cf forward-char
    '';

    gh.settings = {
      git_protocol = "ssh";
      prompt = "enabled";
    };

    direnv.config.global = {
      load_dotenv = true;
      strict_env = true;
      hide_env_diff = true;
    };
  };
}
