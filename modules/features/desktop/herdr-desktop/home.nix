{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  json = pkgs.formats.json { };
  palettes = import ./palettes.nix;
  modDir =
    name: dir:
    lib.mapAttrs' (
      file: _:
      lib.nameValuePair "herdr-app/mods/${name}/${file}" {
        source = dir + "/${file}";
      }
    ) (builtins.readDir dir);
  theme =
    variant:
    let
      palette = palettes.${variant};
    in
    (removeAttrs palette [ "secondary" ])
    // {
      colors =
        palette.colors // lib.genAttrs [ "muted" "dim" "idle" ] (_: palette.secondary);
    };
in
{
  imports = [ inputs.self.homeModules.herdr ];

  xdg.configFile =
    modDir "kindred" ./kindred
    // modDir "reviewer" (inputs.herdr-reviewer + "/mods/reviewer")
    // {
      "herdr-app/layouts/kindred.json".source = json.generate "kindred-layout.json" (
        import ./layout.nix { inherit palettes; }
      );
    }
    // lib.mapAttrs' (
      variant: _:
      lib.nameValuePair "herdr-app/themes/kindred-${variant}.json" {
        source = json.generate "kindred-${variant}.json" (theme variant);
      }
    ) palettes;
}
