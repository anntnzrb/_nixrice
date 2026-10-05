{ lib, ... }: {
  imports = [
    (lib.liberion.gitCheckout {
      name = "rice";
      description = "rice";
      repository = "https://github.com/anntnzrb/_nixrice";
      destination = "repos/rice";
      branch = "dev";
    })
  ];
}
