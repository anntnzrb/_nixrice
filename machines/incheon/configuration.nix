{
  nixpkgs.hostPlatform = "aarch64-darwin";

  nix.settings = {
    max-jobs = 8;
    cores = 4;
  };
}
