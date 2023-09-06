{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  inherit (lib.liberion) mkOptBool';

  cfg = config.liberion.desktop.browser.chromium;
in {
  options.liberion.desktop.browser.chromium = {
    enable = mkOptBool' false;
  };

  config = mkIf cfg.enable {
    programs.chromium = {
      enable = true;
      commandLineArgs = [
        "--force-dark-mode"
      ];
      extensions = [
        # Bitwarden
        {id = "nngceckbapebfimnlniiiahkandclblb";}
        # mail.tm (disposable mail)
        {id = "agjpkjmkocciaibhfcgcindifhapckge";}
        # 7TV
        {id = "ammjkodgmmoknidbanneddgankgfejfh";}
        # JSON viewer
        {id = "bcjindcccaagfpapjjmafapmmgkkhgoa";}

        # uBlock
        {id = "cjpalhdlnbpafiamejdnhcphjbkeiagm";}
        # Decentraleyes
        {id = "ldpochfccmkkmhdbclfhpagapcfdljkj";}
        # Refined GitHub
        {id = "hlepfoohegkhhmjieoechaddaejaokhf";}
        # BypassPayWalls
        {
          id = "dcpihecpambacapedldabdbpakmachpb";
          updateUrl = "https://raw.githubusercontent.com/iamadamdev/bypass-paywalls-chrome/master/src/updates/updates.xml";
        }

        # Wappalyzer
        {id = "gppongmhjkpfnbhagpmjfkannfbllamg";}
        # LanguageTool
        {id = "oldceeleldhonbafppcapldpdifcinji";}
      ];
    };
  };
}
