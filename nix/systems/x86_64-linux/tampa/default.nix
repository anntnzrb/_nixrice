{
  inputs,
  ...
}:
{
  imports = [ inputs.nixos-wsl.nixosModules.default ];

  time.timeZone = "America/Guayaquil";

  wsl.enable = true;
}
