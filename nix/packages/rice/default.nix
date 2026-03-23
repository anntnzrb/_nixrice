{
  lib,
  pkgs,
  ...
}:
let
  packageJson = builtins.fromJSON (builtins.readFile ./package.json);
  inherit (packageJson) version;
  pname = packageJson.name;

  fullSrc = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./src
      ./test
      ./package.json
      ./tsconfig.json
      ./bun.lock
    ];
  };

  runtimeSrc = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./src
      ./package.json
      ./tsconfig.json
    ];
  };

  nodeModules = pkgs.stdenvNoCC.mkDerivation {
    pname = "${pname}-node_modules";
    inherit version;
    src = fullSrc;

    impureEnvVars = lib.fetchers.proxyImpureEnvVars ++ [
      "GIT_PROXY_COMMAND"
      "SOCKS_SERVER"
    ];

    nativeBuildInputs = [
      pkgs.bun
      pkgs.writableTmpDirAsHomeHook
    ];

    dontConfigure = true;

    buildPhase = ''
      runHook preBuild

      export BUN_INSTALL_CACHE_DIR="$(mktemp -d)"
      bun install --frozen-lockfile --no-progress

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p "$out"
      cp -R node_modules "$out/"

      runHook postInstall
    '';

    dontFixup = true;
    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-OTRJqZtXPr0hrUnSgn+SdK6gHF+UywrG4dlqPPqtwTo=";
  };
in
pkgs.stdenvNoCC.mkDerivation {
  inherit pname version;
  src = fullSrc;

  nativeBuildInputs = [
    pkgs.bun
    pkgs.makeWrapper
    pkgs.writableTmpDirAsHomeHook
  ];

  dontBuild = true;
  doCheck = true;
  doInstallCheck = true;

  checkPhase = ''
    runHook preCheck

    ln -s ${nodeModules}/node_modules node_modules

    bun run typecheck
    bun test
    ${lib.getExe pkgs.bun} ./src/cli.ts --help >/dev/null

    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall

    runtime_dir="$out/libexec/${pname}"

    mkdir -p "$out/bin" "$runtime_dir"
    cp -R ${runtimeSrc}/. "$runtime_dir/"
    ln -s ${nodeModules}/node_modules "$runtime_dir/node_modules"

    makeWrapper ${lib.getExe pkgs.bun} "$out/bin/${pname}" \
      --add-flags "$runtime_dir/src/cli.ts"

    runHook postInstall
  '';

  installCheckPhase = ''
    runHook preInstallCheck

    wrapper="$out/bin/${pname}"

    "$wrapper" --help >/dev/null

    link_dir="$(mktemp -d)"
    ln -s "$wrapper" "$link_dir/${pname}"
    PATH="$link_dir:$PATH" "$link_dir/${pname}" --help >/dev/null

    runHook postInstallCheck
  '';

  passthru = {
    inherit nodeModules;
  };

  meta = {
    inherit (packageJson) description;
    mainProgram = pname;
    platforms = lib.platforms.unix;
  };
}
