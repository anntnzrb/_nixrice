# Boot baseline (oulu opts out via disabledModules).
{
  boot = {
    consoleLogLevel = 3;
    tmp.cleanOnBoot = true;
    loader = {
      timeout = 10;
      efi.canTouchEfiVariables = true;
    };
  };
}
