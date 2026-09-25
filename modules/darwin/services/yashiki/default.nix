{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.liberion.module) mkOptDisabled';

  cfg = config.liberion.services.yashiki;

  cmd = args: "yashiki ${args}";
  bind = key: action: cmd "bind ${key} ${action}";
  rule =
    flag: value: actions:
    map (a: cmd "rule-add --${flag} ${lib.escapeShellArg value} ${a}") actions;

  # tag N (key N, 0 for the tenth) is bitmask 2^(N-1)
  tagBindings = lib.concatLists (
    lib.imap0
      (
        i: mask:
        let
          key = toString (lib.mod (i + 1) 10);
        in
        [
          (bind "alt-${key}" "tag-view ${toString mask}")
          (bind "alt-shift-${key}" "window-move-to-tag ${toString mask}")
        ]
      )
      [
        1
        2
        4
        8
        16
        32
        64
        128
        256
        512
      ]
  );

  layout = map cmd [
    "layout-set-default tatami"
    "set-outer-gap 8"
    "layout-cmd --layout tatami set-inner-gap 8"
    "retile"
  ];

  bindings = tagBindings ++ [
    (bind "alt-h" "window-focus left")
    (bind "alt-j" "window-focus down")
    (bind "alt-k" "window-focus up")
    (bind "alt-l" "window-focus right")
    (bind "alt-shift-h" "window-swap left")
    (bind "alt-shift-j" "window-swap down")
    (bind "alt-shift-k" "window-swap up")
    (bind "alt-shift-l" "window-swap right")
    (bind "alt-shift-f" "window-toggle-float")
    (bind "alt-shift-space" "window-toggle-float")
    (bind "alt-shift-t" "layout-set tatami")
    (bind "alt-shift-b" "layout-set byobu")
    (bind "alt-shift-r" ''exec "yashiki quit"'')
  ];

  rules = lib.concatLists [
    (rule "app-name" "*" [ "float" ])
    (rule "app-id" "org.gnu.Emacs" [ "no-float" ])
    (rule "app-id" "org.mozilla.firefox" [ "tags 1" ])
    (rule "app-id" "com.apple.Safari" [ "tags 1" ])
    (rule "app-id" "com.mitchellh.ghostty" [ "tags 2" ])
    (rule "app-id" "com.microsoft.VSCode" [ "tags 4" ])
    (rule "app-id" "com.openai.chat" [
      "tags 8"
      "float"
    ])
    (rule "app-id" "com.apple.systempreferences" [ "float" ])
    (rule "app-name" "System Settings" [ "float" ])
    (rule "app-name" "System Preferences" [ "float" ])
  ];

  initScript = pkgs.writeShellScript "yashiki-init" (
    lib.concatMapStringsSep "\n\n" (lib.concatStringsSep "\n") [
      layout
      bindings
      rules
    ]
  );
in
{
  options.liberion.services.yashiki.enable = mkOptDisabled';

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.liberion.services.aerospace.enable;
        message = "liberion.services.yashiki cannot be enabled together with liberion.services.aerospace.";
      }
    ];

    environment.systemPackages = [ pkgs.yashiki ];

    home-manager.users.${config.system.primaryUser}.xdg.configFile."yashiki/init" =
      {
        source = initScript;
        executable = true;
      };

    launchd.user.agents.yashiki = {
      managedBy = "liberion.services.yashiki.enable";
      serviceConfig = {
        ProgramArguments = [
          "/Applications/Nix Apps/Yashiki.app/Contents/MacOS/yashiki"
          "start"
        ];
        RunAtLoad = true;
        KeepAlive = true;
        ProcessType = "Interactive";
        LimitLoadToSessionType = [ "Aqua" ];
        EnvironmentVariables = {
          PATH = "${pkgs.yashiki}/bin:${config.environment.systemPath}";
        };
      };
    };
  };
}
