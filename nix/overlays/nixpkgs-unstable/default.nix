{
  channels,
  inputs,
  ...
}:
_final: prev: {
  bun = inputs.llm-agents-nix.packages.${prev.stdenv.hostPlatform.system}.bun-bin;

  inherit (channels.nixpkgs-unstable)
    aider-chat
    emacs-macport
    vscode
    zed-editor
    ;
}
