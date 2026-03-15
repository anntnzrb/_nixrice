{ lib }:
let
  inherit (lib)
    concatMap
    genList
    ;

  numTags = 10;

  cmd = args: "yashiki ${args}";
  bind = key: action: cmd "bind ${key} ${action}";

  mkBindings = builtins.map (binding: bind binding.key binding.action);

  ruleAppId =
    appId: action: cmd "rule-add --app-id ${lib.escapeShellArg appId} ${action}";
  ruleAppName =
    appName: action:
    cmd "rule-add --app-name ${lib.escapeShellArg appName} ${action}";

  mkRules =
    rules:
    concatMap (
      rule:
      let
        emit =
          if rule ? appId then
            action: ruleAppId rule.appId action
          else
            action: ruleAppName rule.appName action;
      in
      builtins.map emit rule.actions
    ) rules;

  tagMasks = genList (
    i: if i == 0 then 1 else 2 * (builtins.elemAt tagMasks (i - 1))
  ) numTags;

  tagSpecs = genList (
    i:
    let
      number = i + 1;
    in
    {
      key = if number == numTags then "0" else toString number;
      mask = toString (builtins.elemAt tagMasks i);
    }
  ) numTags;

  mkTagBindings = concatMap (tag: [
    (bind "alt-${tag.key}" "tag-view ${tag.mask}")
    (bind "alt-shift-${tag.key}" "window-move-to-tag ${tag.mask}")
  ]);
in
{
  inherit
    cmd
    bind
    mkBindings
    mkRules
    tagSpecs
    mkTagBindings
    ;
}
