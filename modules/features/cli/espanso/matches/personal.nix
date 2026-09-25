{ lib, ... }: {
  services.espanso.matches.default.matches = [
    {
      trigger = ">!mail";
      replace = lib.liberion.identity.git.email;
    }
    {
      trigger = ">!mail";
      replace = "juangonz@espol.edu.ec";
    }
  ];
}
