{ self, lib, ... }: {
  clan.core.enableRecommendedDefaults = lib.mkDefault false;

  system.configurationRevision = self.rev or self.dirtyRev or null;

  security.sudo.extraConfig = ''
    Defaults timestamp_type=global
  '';
}
