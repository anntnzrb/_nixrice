# Home Manager entrypoint: every `default.nix` under ./home.
{ lib, ... }: { imports = lib.liberion.fs.getDefaultFiles ./home; }
