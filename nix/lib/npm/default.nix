{ lib, ... }:
let
  /**
    Package the shared npm tool launcher script into a derivation.

    The script is copied to `$out/lib/npm/launch.sh` and made executable so
    `mkLauncher` can exec it.

    # Example

    ```nix
    launchScripts pkgs
    =>
    /nix/store/...-npm-launch-scripts
    ```

    # Type

    ```
    launchScripts :: Packages -> Derivation
    ```
  */
  launchScripts =
    pkgs:
    pkgs.runCommand "npm-launch-scripts" { } ''
      mkdir -p "$out/lib/npm"
      cp ${./launch.sh} "$out/lib/npm/launch.sh"
      chmod 755 "$out/lib/npm/launch.sh"
    '';

  /**
    Runtime dependencies required by `launch.sh` on the PATH.

    `nodejs` provides `npm`, `coreutils` provides the GNU `mv -T`, `mktemp`,
    and `readlink` utilities, `gnugrep` matches resolved versions, and
    `flock` guards the cache critical section.

    # Type

    ```
    runtimeInputs :: Packages -> [ Package ]
    ```
  */
  runtimeInputs = pkgs: [
    pkgs.nodejs
    pkgs.coreutils
    pkgs.gnugrep
    pkgs.flock
  ];

  /**
    Create a named launcher that runs an npm-distributed tool through the
    shared `launch.sh` entrypoint.

    The generated launcher resolves, installs, caches, rotates, prunes, and
    finally execs the tool binary; see `launch.sh` for the cache layout.

    # Example

    ```nix
    mkLauncher pkgs {
      name = "yq-launch";
      tool = "yq";
      package = "yq";
      bin = "yq";
      distTag = "latest";
      smokeCheck = "--version";
    }
    => «derivation /nix/store/...-yq-launch.drv»
    ```

    # Type

    ```
    mkLauncher :: Packages -> { name :: String, tool :: String, package :: String, bin :: String, distTag :: String, smokeCheck :: String } -> Derivation
    ```

    # Arguments

    name
    : Name of the generated launcher script

    tool
    : Safe cache directory component identifying the tool

    package
    : npm package specifier to install

    bin
    : Executable name inside the package's `node_modules/.bin`

    distTag
    : npm distribution tag to resolve (default: `"latest"`)

    smokeCheck
    : Single flag word passed to the freshly installed binary to verify it
      before symlink rotation; `"-"` skips the check (default: `"--version"`)
  */
  mkLauncher =
    pkgs:
    {
      name,
      tool,
      package,
      bin,
      distTag ? "latest",
      smokeCheck ? "--version",
    }:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = runtimeInputs pkgs;
      text = ''
        exec ${pkgs.runtimeShell} ${lib.escapeShellArg "${launchScripts pkgs}/lib/npm/launch.sh"} ${lib.escapeShellArg tool} ${lib.escapeShellArg package} ${lib.escapeShellArg bin} ${lib.escapeShellArg distTag} ${lib.escapeShellArg smokeCheck} -- "$@"
      '';
    };
in
{
  npm = { inherit launchScripts runtimeInputs mkLauncher; };
}
