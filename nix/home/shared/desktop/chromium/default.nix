{
  programs.chromium = {
    enable = false;
    commandLineArgs = [
      "--force-dark-mode"
    ];
    extensions = [
      # Bitwarden
      { id = "nngceckbapebfimnlniiiahkandclblb"; }
      # mail.tm (disposable mail)
      { id = "agjpkjmkocciaibhfcgcindifhapckge"; }
      # 7TV
      { id = "ammjkodgmmoknidbanneddgankgfejfh"; }
      # JSON viewer
      { id = "bcjindcccaagfpapjjmafapmmgkkhgoa"; }

      # uBlock
      { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; }
      # Decentraleyes
      { id = "ldpochfccmkkmhdbclfhpagapcfdljkj"; }
      # Refined GitHub
      { id = "hlepfoohegkhhmjieoechaddaejaokhf"; }
      # BypassPayWalls
      {
        id = "dcpihecpambacapedldabdbpakmachpb";
        updateUrl = "https://raw.githubusercontent.com/iamadamdev/bypass-paywalls-chrome/master/src/updates/updates.xml";
      }

      # Wappalyzer 
      { id = "gppongmhjkpfnbhagpmjfkannfbllamg"; }
      # LanguageTool
      { id = "oldceeleldhonbafppcapldpdifcinji"; }
    ];
  };
}
