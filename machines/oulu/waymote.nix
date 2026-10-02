{
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  libxkbcommon,
  wayland,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "waymote";
  version = "0.1.6";

  src = fetchurl {
    url = "https://github.com/rockorager/waymote/releases/download/v${finalAttrs.version}/waymote-server-${finalAttrs.version}-linux-x86_64.tar.gz";
    hash = "sha256-feSa7xBKS/rSvO9ln3M2GyTyic/epUM1DCNBl70mENI=";
  };

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [
    libxkbcommon
    wayland
  ];

  installPhase = ''
    runHook preInstall
    install -Dm755 -t $out/bin bin/waymote-gateway bin/waymote-streamd
    runHook postInstall
  '';

  meta.platforms = [ "x86_64-linux" ];
})
