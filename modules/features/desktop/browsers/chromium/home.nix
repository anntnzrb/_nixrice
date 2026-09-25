{ pkgs, ... }: {
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
}
