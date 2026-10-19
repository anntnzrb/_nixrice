{ pkgs, ... }:
let
  module = type: key: { inherit type key; };
  text = format: {
    type = "custom";
    inherit format;
  };
  gap = text "\n";
in
{
  programs.fastfetch = {
    enable = true;
    package =
      if pkgs.stdenv.hostPlatform.isDarwin then
        pkgs.fastfetch.overrideAttrs (old: {
          # makeLibraryPath adds this nonexistent directory and retains the entire SDK.
          postInstall =
            builtins.replaceStrings [ ":${pkgs.apple-sdk_15}/lib" ] [ "" ]
              old.postInstall;
        })
      else
        pkgs.fastfetch;

    settings = {
      display.separator = "  :: ";
      modules = [
        (text "├── hardware")
        (module "host" "  ")
        (module "cpu" "  ")
        (module "disk" "  ")
        (module "memory" "  󰑭")
        (module "swap" "  󰓡")
        gap
        (module "battery" "  ")
        (module "poweradapter" "  ")
        (module "sound" "  ")
        (module "bluetooth" "  ")
        (module "display" "  󰍹")
        (module "brightness" "  󰃞")
        (module "gpu" "  ")
        gap
        (text "├── software")
        (module "title" "  " // { format = "{1}@{2}"; })
        (module "os" "  ")
        (module "kernel" "  " // { format = "{1} {2}"; })
        (module "shell" "  ")
        (module "terminal" "  ")
        (module "packages" "  󰏖")
        (module "uptime" "  󰅐")
        (module "media" "  󰝚")
        gap
        (text "├── ui")
        (module "lm" "  󰧨")
        (module "de" "  ")
        (module "wm" "  ")
        (module "theme" "  󰉼")
        (module "icons" "  󰀻")
        gap
        (text "├── misc")
        (module "localip" "  󰩟")
        (module "locale" "  ")
        (text " ───────────────────────────────")
        {
          type = "colors";
          paddingLeft = 8;
          symbol = "circle";
        }
      ];
    };
  };
}
