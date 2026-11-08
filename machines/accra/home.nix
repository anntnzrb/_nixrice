{ lib, ... }: {
  programs = {
    nix-index.enable = false;
    nix-index-database.comma.enable = lib.mkForce false;
    yt-dlp.enable = lib.mkForce false;
  };
}
