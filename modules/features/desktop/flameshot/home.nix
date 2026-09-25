{ config, ... }: {
  services.flameshot = {
    enable = true;
    settings = {
      General = {
        autoCloseIdleDaemon = true;
        saveAsFileExtension = "png";
        savePath = "${config.xdg.userDirs.pictures}";
        savePathFixed = true;
        showMagnifier = true;
        uploadHistoryMax = 50;
        uploadWithoutConfirmation = true;
      };
    };
  };

  services.sxhkd = {
    keybindings = {
      "Print" = "flameshot gui";
    };
  };
}
