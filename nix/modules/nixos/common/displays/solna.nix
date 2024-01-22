rec {
  displays = {
    main = {
      port = "eDP-1";
      fingerprint = "00ffffffffffff0009e56f0700000000011b01049522137802f700965754922823505400000001010101010101010101010101010101ce1d56e250001e303020360058c21000001ace1d56a953003c303020360058c21000001a00000000000000000000000000000000000000000002000c49ff0a3c6e13111f6e00000000bb";
      resolution = "1366x768";
      refreshRate = "60.00";
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
          dpi = 104;
          mode = "${main.resolution}";
          rate = "${main.refreshRate}";
        };
      };
    };
  };
}
