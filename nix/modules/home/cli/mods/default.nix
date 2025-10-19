{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.cli.mods;

  package = pkgs.writeShellApplication {
    name = "mods";
    runtimeInputs = with pkgs; [
      gh
      mods
    ];
    text = ''
      token="$(gh auth token 2>/dev/null || printf "")"
      export GITHUB_PERSONAL_ACCESS_TOKEN="$token"
      exec mods "$@"
    '';
  };
in
{
  options.${namespace}.cli.mods = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    programs.mods = {
      inherit (cfg) enable;
      inherit package;

      settings = {
        default-api = "github-models";
        default-model = "openai/gpt-5-mini";
        apis.github-models = {
          base-url = "https://models.github.ai/inference";
          api-key-env = "GITHUB_PERSONAL_ACCESS_TOKEN";
          models = {
            "openai/gpt-5-mini".max-input-chars = 800000;
          };
        };
      };
    };
  };
}
