{
  lib,
  config,
  inputs,
  host,
  namespace,
  ...

}:
let
  inherit (lib.${namespace}.module) mkOpt' mkOptDisabled';

  cfg = config.${namespace}.network.ssh;

  name = host;

  nixosConfigurations = inputs.self.nixosConfigurations or { };
  darwinConfigurations = inputs.self.darwinConfigurations or { };

  ## NOTE This is the cause of evaluating all configurations per system
  ## TODO: Find a more elegant way that doesn't require bloating eval complications
  other-hosts =
    lib.filterAttrs (
      key: host: key != name && (host.config.${namespace}.user.name or null) != null
    ) nixosConfigurations
    // darwinConfigurations;

  other-hosts-config = lib.concatMapStringsSep "\n" (
    name:
    let
      remote = other-hosts.${name};
      remote-user-name = remote.config.${namespace}.user.name;
      port-expr =
        if builtins.hasAttr name inputs.self.nixosConfigurations then
          "Port ${builtins.toString cfg.port}"
        else
          "";
    in
    ''
      Host ${name}
        Hostname ${name}.local
        User ${remote-user-name}
        ForwardAgent yes
        ${port-expr}
    ''
  ) (builtins.attrNames other-hosts);
in
{
  options.${namespace}.network.ssh = with lib.types; {
    enable = mkOptDisabled';
    extraConfig = mkOpt' str "";
    port = mkOpt' port 2222;
  };

  config = lib.mkIf cfg.enable {
    programs.ssh = {
      extraConfig = ''
        ${other-hosts-config}


        ${cfg.extraConfig}
      '';

      knownHosts = lib.mapAttrs (_: lib.mkForce) {
        github-rsa = {
          hostNames = [ "" ];
          publicKey = "";
        };
      };
    };
  };
}
