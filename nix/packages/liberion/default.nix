{ writeShellApplication
, ...
}:
writeShellApplication {
  name = "liberion";
  text = builtins.readFile ./src/liberion.sh;
}
