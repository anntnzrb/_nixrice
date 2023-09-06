{config, ...}: let
  cfg = config.liberion.security.su;
in {
  config = {
    security = {
      sudo.enable = false;

      doas = {
        enable = true;
        extraRules = [
          {
            groups = ["wheel"];
            noPass = false;
            keepEnv = true;
            persist = true;
          }
        ];
      };
    };

    liberion.user.extraGroups = ["wheel"];
  };
}
