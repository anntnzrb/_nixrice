{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  cfg =
    lib.attrByPath
      [
        "home-manager"
        "users"
        config.${namespace}.user.name
        namespace
        "desktop"
        "browsers"
        "brave"
      ]
      {
        enable = false;
        "brave-ai".enable = false;
        news.enable = false;
        rewards.enable = false;
        vpn.enable = false;
        wallet.enable = false;
      }
      config;

  bravePolicyPlist = pkgs.writeText "com.brave.Browser.plist" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>BraveAIChatEnabled</key>
      <${if cfg."brave-ai".enable then "true" else "false"}/>
      <key>BraveNewsDisabled</key>
      <${if cfg.news.enable then "false" else "true"}/>
      <key>BraveRewardsDisabled</key>
      <${if cfg.rewards.enable then "false" else "true"}/>
      <key>BraveVPNDisabled</key>
      <${if cfg.vpn.enable then "false" else "true"}/>
      <key>BraveWalletDisabled</key>
      <${if cfg.wallet.enable then "false" else "true"}/>
    </dict>
    </plist>
  '';
in
{
  config.system.activationScripts.postActivation.text = lib.mkAfter ''
    brave_policy_dir="/Library/Managed Preferences"
    brave_policy_target="$brave_policy_dir/com.brave.Browser.plist"

    ${lib.optionalString cfg.enable ''
      brave_policy_source="${bravePolicyPlist}"

      mkdir -p "$brave_policy_dir"

      if [ ! -e "$brave_policy_target" ] || ! cmp -s "$brave_policy_source" "$brave_policy_target"; then
          install -m 0644 "$brave_policy_source" "$brave_policy_target"
          chown root:wheel "$brave_policy_target"
          killall cfprefsd >/dev/null 2>&1 || :
      fi
    ''}

    ${lib.optionalString (!cfg.enable) ''
      if [ -e "$brave_policy_target" ]; then
        rm -f "$brave_policy_target"
        killall cfprefsd >/dev/null 2>&1 || :
      fi
    ''}
  '';
}
