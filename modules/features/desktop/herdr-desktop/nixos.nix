{ inputs, pkgs, ... }: {
  imports = [ inputs.self.nixosModules.herdr ];

  environment.systemPackages = [ pkgs.unstable.herdr-desktop ];
}
