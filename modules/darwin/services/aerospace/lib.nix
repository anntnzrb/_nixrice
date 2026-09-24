{ lib }:
let
  mkDirectionalBindings =
    command: modifier: keyMap:
    lib.listToAttrs (
      lib.mapAttrsToList (key: dir: {
        name = "${modifier}-${key}";
        value = "${command} ${dir}";
      }) keyMap
    );

  vimBindings = {
    h = "left";
    j = "down";
    k = "up";
    l = "right";
  };

  mkWorkspaceBindings =
    workspaceRange: cmd: prefix:
    lib.listToAttrs (
      map (num: {
        name = "${prefix}-${toString num}";
        value = "${cmd} ${toString num}";
      }) workspaceRange
    );

  mkRule =
    {
      appId ? null,
      appName ? null,
      windowTitle ? null,
      workspace ? null,
      duringStartup ? null,
      furtherCallbacks ? true,
      run,
    }:
    {
      "if" = lib.filterAttrs (_: v: v != null) {
        "app-id" = appId;
        "app-name-regex-substring" = appName;
        "window-title-regex-substring" = windowTitle;
        "during-aerospace-startup" = duringStartup;
        inherit workspace;
      };
      inherit run;
      "check-further-callbacks" = furtherCallbacks;
    };

  mkRules = rules: map mkRule rules;
  mkLayout = name: "layout ${name}";
  mvNodeToWorkspace = n: "move-node-to-workspace ${builtins.toString n}";
in
{
  inherit
    mkDirectionalBindings
    vimBindings
    mkWorkspaceBindings
    mkRule
    mkRules
    mkLayout
    mvNodeToWorkspace
    ;
}
