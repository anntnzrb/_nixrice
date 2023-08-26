{
  security = {
    sudo.enable = false;

    doas = {
      enable = true;
      extraRules = [{
        groups = [ "wheel" ];
        noPass = false;
        keepEnv = true;
        persist = true;
      }];
    };
  };
}
