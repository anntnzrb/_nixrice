# Who owns this fleet: account name, git identity and SSH public keys.
# Read by flake.nix, clan.nix and modules (as lib.liberion.identity).
{
  user = "annt";

  git = {
    name = "anntnzrb";
    email = "anntnzrb@proton.me";
  };

  keys = {
    # fleet-wide admin key
    admin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB45J5N5vAcQlF4kUHN8y12FMOzXhuav7bczaztcZHTq annt@liberion";

    # one key per device
    devices = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBEpmEC2zcNWEgNAdHDzFZnK7dfOeDVh+r0sasP5PclS annt@beirut"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHzBDSIjkAYW57NffyZkkKeFoA2YGqEKR7mzL5pgYYxV anntnzrb@munich"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJi5TwdwALl2Sw0/MuE+r0u4s35Xw8TftkUQZE2lW3Gr annt@oulu"
    ];
  };
}
