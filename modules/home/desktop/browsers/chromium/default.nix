{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib.liberion.module) mkOptDisabled';

  cfg = config.liberion.desktop.browsers.chromium;
in
{
  options.liberion.desktop.browsers.chromium = {
    enable = mkOptDisabled';
  };
  config = lib.mkIf cfg.enable {
    programs.chromium = {
      inherit (cfg) enable;

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
