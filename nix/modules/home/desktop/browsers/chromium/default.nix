{
  pkgs,
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) mkOptBool';

  cfg = config.${namespace}.desktop.browsers.chromium;
in
{
  options.${namespace}.desktop.browsers.chromium = {
    enable = mkOptBool';
  };
  config = lib.mkIf cfg.enable {
    programs.chromium = {
      enable = true;

      dictionaries = [ pkgs.hunspellDictsChromium.en_US ];
      extensions = [
        { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # uBlock Origin
        { id = "eanggfilgoajaocelnaflolkadkeghjp"; } # Harpa AI
        { id = "nngceckbapebfimnlniiiahkandclblb"; } # Bitwarden

        # streaming
        { id = "ammjkodgmmoknidbanneddgankgfejfh"; } # 7TV
        { id = "ajopnjidmegmdimjlfnijceegpefgped"; } # BetterTTV
      ];
    };
  };
}
