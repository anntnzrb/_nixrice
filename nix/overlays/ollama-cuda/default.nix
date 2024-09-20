{ channels, ... }: _final: _prev: { inherit (channels.nixpkgs-unstable) ollama-cuda; }
