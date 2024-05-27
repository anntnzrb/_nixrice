{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.liberion.desktop.browsers.chromium;
in
{
  options.liberion.desktop.browsers.chromium = with lib.liberion; {
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
