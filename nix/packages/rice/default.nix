{
  lib,
  pkgs,
  ...
}:
let
  pname = "rice";
  version = "0.1.0";

  src = ./.;
in
pkgs.buildGoModule {
  inherit pname version src;

  vendorHash = null;

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];

  nativeCheckInputs = [
    pkgs.golangci-lint
    pkgs.gofumpt
  ];

  checkPhase = ''
    runHook preCheck
    export GOLANGCI_LINT_CACHE="''${TMPDIR:-/tmp}/golangci-lint-cache"
    mkdir -p "$GOLANGCI_LINT_CACHE"
    golangci-lint run ./...
    go vet ./...
    gofmt_files="$(gofumpt -l .)"
    test -z "$gofmt_files"
    go test -race -count=1 -shuffle=on ./...
    runHook postCheck
  '';

  doInstallCheck = true;

  installCheckPhase = ''
    runHook preInstallCheck

    wrapper="$out/bin/${pname}"

    "$wrapper" --help >/dev/null

    link_dir="$(mktemp -d)"
    ln -s "$wrapper" "$link_dir/${pname}"
    PATH="$link_dir:$PATH" "$link_dir/${pname}" --help >/dev/null

    runHook postInstallCheck
  '';

  meta = {
    description = "NixOS/Darwin configuration management CLI";
    mainProgram = pname;
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
