{
  pkgs,
  config,
  namespace,
  ...
}:
let
  _cfg = config.${namespace}.environment;
in
{
  config = {
    environment.systemPackages = with pkgs; [
      # tools
      git
      curl
      wget

      # archiving
      atool
      rar
      unrar-wrapper
      unzip
      zip
    ];
  };
}
