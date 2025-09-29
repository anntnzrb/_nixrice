{
  lib,
  ...
}:
{
  imports = [
    (lib.snowfall.fs.get-file "modules/shared/network/ssh/default.nix")
  ];

  config = { };
}
