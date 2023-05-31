{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    ansible
  ];

  shellHook = ''
    export BW_SESSION="`bw unlock --raw`"

    printf '=> nix-shell: set-up for dotfiles management\n'
  '';
}
