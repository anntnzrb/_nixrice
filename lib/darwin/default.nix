{ lib, ... }:

{ darwin.programs = import ./programs { inherit lib; }; }
