rec {
  displays = {
    main = {
      port = "HDMI-1-1";
      fingerprint = "00ffffffffffff0006b3a124010101012e1a010380351e78ea0ef5a555509e26105054bfef00714f818081409500a940b300d1cf0101023a801871382d40582c4500132b2100001e000000fd00284b1e5a19000a202020202020000000fc0056473234350a20202020202020000000ff0047424c4d51533033303936330a011d020327f14b900504030201111213141f230907078301000065030c001000681a00000101284be6023a801871382d40582c4500132b2100001e662156aa51001e30468f3300132b2100001e011d007251d01e206e285500132b2100001e8c0ad08a20e02d10103e9600132b2100001800000000000000000000000000000000b7";
      resolution = "1920x1080";
      refreshRate = "65.00"; #FIXME: won't let go higher
      dpi = 96;
    };
    external = {
      port = "HDMI-3";
      fingerprint = "00ffffffffffff004c2d3c0c000000002e18010380351e780aee91a3544c99260f5054bdee0081c00101010101010101010101010101662156aa51001e30468f3300615b2100001e011d007251d01e206e285500615b2100001e000000fd00184b0f4417000a202020202020000000fc0053414d53554e470a20202020200121020325f14d841305140312101f20212207162309070783010000e2000f67030c001000b82d011d80d0721c1620102c2580615b2100009e011d8018711c1620582c2500615b2100009e011d00bc52d01e20b8285540615b2100001e8c0ad090204031200c405500615b210000188c0ad08a20e02d10103e9600615b21000018f2";
      resolution = "1366x768";
      refreshRate = "60.00";
      dpi = 112;
    };
  };

  profiles = with displays; {
    main = {
      fingerprint = {
        "${main.port}" = main.fingerprint;
      };

      config = {
        "${main.port}" = {
          enable = true;
          primary = true;
          position = "0x0";
          dpi = main.dpi;
          mode = "${main.resolution}";
          rate = "${main.refreshRate}";
        };
      };
    };

    external = {
      fingerprint = {
        "${external.port}" = external.fingerprint;
      };

      config = {
        "${external.port}" = {
          enable = true;
          primary = true;
          position = "0x0";
          dpi = external.dpi;
          mode = "${external.resolution}";
          rate = "${external.refreshRate}";
        };
      };
    };

    dual = {
      fingerprint = {
        "${main.port}" = main.fingerprint;
        "${external.port}" = external.fingerprint;
      };

      config = {
        "${main.port}" = {
          enable = true;
          primary = true;
          position = "0x0";
          dpi = main.dpi;
          mode = "${main.resolution}";
          rate = "${main.refreshRate}";
        };

        "${external.port}" = {
          enable = true;
          primary = true;
          position = "1920x0";
          dpi = external.dpi;
          mode = "${external.resolution}";
          rate = "${external.refreshRate}";
        };
      };
    };
  };
}
