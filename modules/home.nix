# Home Manager entrypoint: every `default.nix` under ./home.
{ lib, namespace, ... }: {
  imports = lib.${namespace}.fs.getDefaultFiles ./home;
}
