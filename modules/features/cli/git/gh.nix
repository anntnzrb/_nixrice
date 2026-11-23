{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.liberion.module) mkOpt';
  inherit (lib.types) nullOr str;

  cfg = config.liberion.cli.git;
  tokenFile = lib.escapeShellArg cfg.githubTokenFile;
  gh = pkgs.symlinkJoin {
    name = "gh-with-token";
    paths = [ pkgs.gh ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/gh --run ${lib.escapeShellArg ''[ -n "''${GH_TOKEN:-}" ] || [ ! -r ${tokenFile} ] || export GH_TOKEN="$(<${tokenFile})"''}
    '';
    meta.mainProgram = "gh";
  };
in
{
  options.liberion.cli.git.githubTokenFile = mkOpt' (nullOr str) null;

  config.programs.gh = {
    enable = true;
    package = lib.mkIf (cfg.githubTokenFile != null) gh;
    settings = {
      git_protocol = "ssh";
      prompt = "enabled";
    };
  };
}
