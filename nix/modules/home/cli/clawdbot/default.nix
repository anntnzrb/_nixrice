{
  config,
  lib,
  namespace,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOpt' mkOptDisabled';
  inherit (lib.types)
    int
    listOf
    path
    str
    ;

  cfg = config.${namespace}.cli.clawdbot;

  homeDir = config.home.homeDirectory;
  telegramAllowFromDefault = [ 8518708886 ];
  providersData = import ./providers.nix { inherit homeDir; };
  inherit (providersData) providers defaultProvider;
  providerName = cfg.provider.name;
  selectedProvider = providers.${providerName};
  providerApiKeyFile =
    if cfg.provider.apiKeyFile != null then
      cfg.provider.apiKeyFile
    else
      selectedProvider.apiKeyFile;
  defaults = {
    documentsDir = ./documents;
    telegram = {
      botTokenFile = "${homeDir}/.secrets/clawdbot-telegram-bot-token";
      allowFrom = telegramAllowFromDefault;
    };
    config = {
      modelsMode = "merge";
    };
    launchd = {
      label = "com.steipete.clawdbot.gateway";
      domain = "gui/$UID";
      agentDir = "${homeDir}/Library/LaunchAgents";
      launchctlBin = "/bin/launchctl";
    };
  };

  clawdbot = {
    inherit (defaults) launchd;
    secrets = {
      providerKeyFile = providerApiKeyFile;
      telegramTokenFile = cfg.telegram.botTokenFile;
    };
    telegramAllowFrom = cfg.telegram.allowFrom;
  };
  clawdbotWrapperScript =
    lib.replaceStrings
      [ "@providerApiKeyEnv@" "@providerApiKeyFile@" ]
      [ selectedProvider.apiKeyEnv clawdbot.secrets.providerKeyFile ]
      (builtins.readFile ./clawdbot-wrapper.sh);
  clawdbotWrapperPackage = pkgs.writeShellApplication {
    name = "clawdbot";
    runtimeInputs = [ pkgs.clawdbot ];
    text = clawdbotWrapperScript;
  };
in
{
  imports = [ inputs.nix-clawdbot.homeManagerModules.clawdbot ];

  options.${namespace}.cli.clawdbot = {
    enable = mkOptDisabled';

    documents = mkOpt' path defaults.documentsDir;

    provider = {
      name = mkOpt' str defaultProvider;
      apiKeyFile = mkOpt' (lib.types.nullOr str) null;
    };

    telegram = {
      botTokenFile = mkOpt' str defaults.telegram.botTokenFile;
      allowFrom = mkOpt' (listOf int) defaults.telegram.allowFrom;
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.hasAttr providerName providers;
        message = "Unknown Clawdbot provider '${providerName}'. Add it in providers.nix.";
      }
    ];

    programs.clawdbot = {
      enable = true;
      inherit (cfg) documents;
      defaults.model = selectedProvider.model.primary;
      firstParty = {
        summarize.enable = false;
        peekaboo.enable = false;
        oracle.enable = false;
        poltergeist.enable = false;
        sag.enable = false;
        camsnap.enable = false;
        gogcli.enable = false;
        bird.enable = false;
        sonoscli.enable = false;
        imsg.enable = false;
      };

      instances.default = {
        enable = true;
        package = clawdbotWrapperPackage;

        launchd = {
          enable = true;
          inherit (clawdbot.launchd) label;
        };

        providers.telegram = {
          enable = true;
          botTokenFile = clawdbot.secrets.telegramTokenFile;
          allowFrom = clawdbot.telegramAllowFrom;
        };

        configOverrides = {
          agents.defaults.model.primary = selectedProvider.model.primary;
          models = {
            mode = defaults.config.modelsMode;
            providers.${providerName} = {
              inherit (selectedProvider.api) baseUrl;
              apiKey = selectedProvider.apiKeyRef;
              api = selectedProvider.api.transport;
              models = [
                {
                  inherit (selectedProvider.model) id name reasoning;
                  input = selectedProvider.model.inputs;
                  inherit (selectedProvider) cost;
                  inherit (selectedProvider.limits) contextWindow maxTokens;
                }
              ];
            };
          };
        };
      };
    };

    home.activation.clawdbotLaunchdRestart =
      config.lib.dag.entryAfter
        [
          "clawdbotLaunchdRelink"
        ]
        ''
          label="${clawdbot.launchd.label}"
          domain="${clawdbot.launchd.domain}"
          plist="${clawdbot.launchd.agentDir}/$label.plist"
          launchctl="${clawdbot.launchd.launchctlBin}"

          if [ -f "$plist" ]; then
            if "$launchctl" print "$domain/$label" >/dev/null 2>&1; then
              "$launchctl" bootout "$domain/$label" 2>/dev/null || true
              "$launchctl" remove "$label" 2>/dev/null || true
            fi

            "$launchctl" bootstrap "$domain" "$plist" 2>/dev/null || true
            "$launchctl" kickstart -k "$domain/$label" 2>/dev/null || true
          fi
        '';
  };
}
