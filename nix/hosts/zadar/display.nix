let
  displays = {
    builtin = {
      fingerprint = "";
      resolution = "1920x1080";
      refreshRate = "60.00";
    };
  };
in
{
  services.xserver = {
    enable = true;
    autorun = false;
    displayManager.sx.enable = true;

    layout = "us";
    xkbVariant = "altgr-intl";
    xkbOptions = "caps:none";
  };

  services.autorandr = {
    enable = true;
  };
}
