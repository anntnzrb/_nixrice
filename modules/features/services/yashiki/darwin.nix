{
  lib,
  pkgs,
  config,
  ...
}:
let
  cmd = args: "yashiki ${args}";
  bind = key: action: cmd "bind ${key} ${action}";
  ruleWith =
    matchers: actions:
    map (
      a:
      cmd "rule-add ${
        lib.concatStringsSep " " (
          lib.mapAttrsToList (
            flag: value: "--${flag} ${lib.escapeShellArg value}"
          ) matchers
        )
      } ${a}"
    ) actions;
  rule = flag: value: ruleWith { ${flag} = value; };

  mask = n: toString (lib.foldl' (acc: _: acc * 2) 1 (lib.range 2 n));
  tags = n: "tags ${mask n}";

  tagBindings = lib.concatMap (
    n:
    let
      key = toString (lib.mod n 10);
    in
    [
      (bind "alt-${key}" "tag-view ${mask n}")
      (bind "alt-shift-${key}" "window-move-to-tag ${mask n}")
    ]
  ) (lib.range 1 10);

  settings = map cmd [
    "layout-set-default tatami"
    "set-outer-gap 8"
    "layout-cmd --layout tatami set-inner-gap 8"
    "set-cursor-warp on-output-change"
    "retile"
  ];

  mainDisplay = [
    ''main="$(yashiki list-outputs | ${lib.getExe pkgs.gawk} 'index($0, "(main)") { sub(":", "", $1); print $1 }')"''
    ''[ -z "$main" ] || yashiki rule-add --app-name '*' output "$main"''
  ];

  bindings = tagBindings ++ [
    (bind "alt-tab" "tag-view-last")
    (bind "alt-comma" "output-focus prev")
    (bind "alt-period" "output-focus next")
    (bind "alt-shift-comma" "output-send prev")
    (bind "alt-shift-period" "output-send next")
    (bind "alt-h" "window-focus left")
    (bind "alt-j" "window-focus down")
    (bind "alt-k" "window-focus up")
    (bind "alt-l" "window-focus right")
    (bind "alt-shift-h" "window-swap left")
    (bind "alt-shift-j" "window-swap down")
    (bind "alt-shift-k" "window-swap up")
    (bind "alt-shift-l" "window-swap right")
    (bind "alt-shift-f" "window-toggle-fullscreen")
    (bind "alt-shift-space" "window-toggle-float")
    (bind "alt-shift-t" "layout-set tatami")
    (bind "alt-shift-b" "layout-set byobu")
    (bind "alt-shift-r" ''exec "yashiki quit"'')
  ];

  rules = lib.concatLists [
    (rule "app-name" "*" [ "float" ])
    (rule "app-id" "org.mozilla.firefox" [ (tags 1) ])
    (rule "app-id" "com.apple.Safari" [ (tags 1) ])
    (rule "app-id" "com.mitchellh.ghostty" [
      (tags 2)
      "no-float"
    ])
    (rule "app-id" "com.brave.Browser" [
      (tags 1)
      "no-float"
    ])
    (ruleWith {
      app-id = "com.brave.Browser";
      subrole = "AXUnknown";
    } [ "ignore" ])
    (rule "app-id" "org.alacritty" [ (tags 2) ])
    (rule "app-id" "com.raphaelamorim.rio" [ (tags 2) ])
    (rule "app-id" "com.apple.systempreferences" [ "float" ])
    (rule "app-name" "System Settings" [ "float" ])
    (rule "app-name" "System Preferences" [ "float" ])
  ];

  initScript = pkgs.writeShellScript "yashiki-init" (
    lib.concatMapStringsSep "\n\n" (lib.concatStringsSep "\n") [
      settings
      bindings
      mainDisplay
      rules
    ]
  );

  wm = import ../_wm-handoff.nix {
    inherit lib;
    user = config.system.primaryUser;
  };

  evacuateAerospace = pkgs.writeShellApplication {
    name = "evacuate-aerospace";
    runtimeInputs = [
      pkgs.aerospace
      pkgs.gnugrep
    ];
    text = ''
      visible="$(aerospace list-workspaces --monitor all --visible)"
      target="$(aerospace list-workspaces --focused)"
      aerospace list-windows --all --format '%{window-id} %{workspace}' | while read -r id ws; do
        grep -Fxq -- "$ws" <<<"$visible" ||
          aerospace move-node-to-workspace --window-id "$id" -- "$target"
      done
    '';
  };
in
{
  config = {
    assertions = [
      {
        assertion = !config.services.aerospace.enable;
        message = "the yashiki feature cannot be imported together with the aerospace feature.";
      }
    ];

    system.activationScripts.preActivation.text = lib.mkAfter (
      wm.stop {
        label = "org.nixos.aerospace";
        evacuate = lib.getExe evacuateAerospace;
      }
    );

    environment.systemPackages = [ pkgs.yashiki ];

    home-manager.users.${config.system.primaryUser}.xdg.configFile."yashiki/init" =
      {
        source = initScript;
        executable = true;
      };

    launchd.user.agents.yashiki = {
      managedBy = "modules/features/services/yashiki";
      command = "${lib.escapeShellArg "/Applications/Nix Apps/Yashiki.app/Contents/MacOS/yashiki"} start";
      serviceConfig = {
        RunAtLoad = true;
        KeepAlive = true;
        ThrottleInterval = 60;
        ProcessType = "Interactive";
        LimitLoadToSessionType = [ "Aqua" ];
        EnvironmentVariables = {
          PATH = "${pkgs.yashiki}/bin:${config.environment.systemPath}";
        };
      };
    };
  };
}
