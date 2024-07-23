{ channels
, ...
}:
final: prev: {
  inherit (channels.nixpkgs-unstable) whatsapp-for-mac;
}
