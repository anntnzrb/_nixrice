# Repository helpers exposed as `lib.liberion`.
{ lib }:
lib.foldl' (acc: path: acc // import path { inherit lib; }) { } [
  ./darwin
  ./fs
  ./module
  ./xorg
]
