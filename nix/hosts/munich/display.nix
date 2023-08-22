let
  displays = {
    asusVG245H = {
      fingerprint = "00ffffffffffff0006b3a124010101012e1a010380351e78ea0ef5a555509e26105054bfef00714f818081409500a940b300d1cf0101023a801871382d40582c4500132b2100001e000000fd00284b1e5a19000a202020202020000000fc0056473234350a20202020202020000000ff0047424c4d51533033303936330a011d020327f14b900504030201111213141f230907078301000065030c001000681a00000101284be6023a801871382d40582c4500132b2100001e662156aa51001e30468f3300132b2100001e011d007251d01e206e285500132b2100001e8c0ad08a20e02d10103e9600132b2100001800000000000000000000000000000000b7";
      resolution = "1920x1080";
      refreshRate = "75.00";
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

    profiles = {
      "single" = {
        fingerprint = {
          HDMI-0 = "${displays.asusVG245H.fingerprint}";
        };
        config = {
          HDMI-0 = {
            enable = true;
            primary = true;
            position = "0x0";
            dpi = 96;
            mode = "${displays.asusVG245H.resolution}";
            rate = "${displays.asusVG245H.refreshRate}";
          };
        };
      };
    };
  };
}
