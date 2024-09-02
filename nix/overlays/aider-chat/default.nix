{ channels
, ...
}:
final: prev: {
  inherit (channels.nixpkgs-unstable) aider-chat;
}
