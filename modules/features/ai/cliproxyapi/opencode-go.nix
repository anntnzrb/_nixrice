{
  buildGoModule,
  fetchFromGitHub,
  lib,
}:
buildGoModule {
  pname = "opencode-go-quota";
  version = "0.4.1";

  src = fetchFromGitHub {
    owner = "duu261";
    repo = "opencode-go-pool";
    rev = "e40c7a052f5111d8459c0b139d4523013f38291d";
    hash = "sha256-pG6a04+S5nM/pQzw76aalZkvwxU2ocfEBctbRNJK9Yc=";
  };
  vendorHash = "sha256-g+yaVIx4jxpAQ/+WrGKxhVeliYx7nLQe/zsGpxV4Fn4=";

  patches = [ ./native-quota.patch ];

  env.CGO_ENABLED = 1;

  buildPhase = ''
    runHook preBuild
    go build -trimpath -buildmode=c-shared -ldflags="-s -w" -o opencode-go-quota.so .
    runHook postBuild
  '';

  checkPhase = ''
    runHook preCheck
    go test ./...
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 opencode-go-quota.so $out/lib/opencode-go-quota.so
    runHook postInstall
  '';

  meta = {
    description = "OpenCode Go provider for native CLIProxyAPI quota management";
    homepage = "https://github.com/duu261/opencode-go-pool";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
