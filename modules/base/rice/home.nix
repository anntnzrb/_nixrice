{ lib, ... }: {
  imports = [
    (lib.liberion.gitCheckout {
      name = "rice";
      description = "rice";
      repository = "https://github.com/anntnzrb/_nixrice";
      destination = "src/rice";
      branch = "dev";
    })
  ];
}
