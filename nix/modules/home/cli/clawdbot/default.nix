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
  minimaxApiKeyEnv = "MINIMAX_API_KEY";
  minimaxApiKeyRef = "\${MINIMAX_API_KEY}";
  minimaxProviderName = "minimax";
  minimaxModelId = "MiniMax-M2.1";
  minimaxModelName = "MiniMax M2.1";
  minimaxModelInputs = [ "text" ];
  minimaxApi = {
    baseUrl = "https://api.minimax.io/v1";
    transport = "openai-completions";
  };
  minimaxLimits = {
    contextWindow = 200000;
    maxTokens = 8192;
  };
  minimaxCost = {
    input = 15;
    output = 60;
    cacheRead = 2;
    cacheWrite = 10;
  };
  defaults = {
    documentsDir = ./documents;
    telegram = {
      botTokenFile = "${homeDir}/.secrets/telegram-bot-token";
      allowFrom = telegramAllowFromDefault;
    };
    minimax = {
      keyFile = "${homeDir}/.secrets/minimax-api-key";
      apiKeyEnv = minimaxApiKeyEnv;
      apiKeyRef = minimaxApiKeyRef;
      providerName = minimaxProviderName;
      modelId = minimaxModelId;
      modelName = minimaxModelName;
      modelInputs = minimaxModelInputs;
      api = minimaxApi;
      limits = minimaxLimits;
      cost = minimaxCost;
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

  minimaxModelPrimary = "${minimaxProviderName}/${minimaxModelId}";
  minimax = {
    model = {
      id = minimaxModelId;
      name = minimaxModelName;
      primary = minimaxModelPrimary;
      inputs = minimaxModelInputs;
    };
    provider = {
      name = minimaxProviderName;
      api = minimaxApi;
      apiKeyRef = minimaxApiKeyRef;
    };
    limits = minimaxLimits;
    cost = minimaxCost;
  };

  clawdbot = {
    inherit (defaults) launchd;
    secrets = {
      minimaxKeyFile = cfg.minimax.keyFile;
      telegramTokenFile = cfg.telegram.botTokenFile;
    };
    telegramAllowFrom = cfg.telegram.allowFrom;
  };
  clawdbotWrapperScript =
    lib.replaceStrings
      [ "@minimaxApiKeyEnv@" "@minimaxKeyFile@" ]
      [ minimaxApiKeyEnv clawdbot.secrets.minimaxKeyFile ]
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

    telegram = {
      botTokenFile = mkOpt' str defaults.telegram.botTokenFile;
      allowFrom = mkOpt' (listOf int) defaults.telegram.allowFrom;
    };

    minimax = {
      keyFile = mkOpt' str defaults.minimax.keyFile;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.clawdbot = {
      enable = true;
      inherit (cfg) documents;
      defaults.model = minimax.model.primary;
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
          agents.defaults.model.primary = minimax.model.primary;
          models = {
            mode = defaults.config.modelsMode;
            providers.${minimax.provider.name} = {
              inherit (minimax.provider.api) baseUrl;
              apiKey = minimax.provider.apiKeyRef;
              api = minimax.provider.api.transport;
              models = [
                {
                  inherit (minimax.model) id name;
                  reasoning = false;
                  input = minimax.model.inputs;
                  inherit (minimax) cost;
                  inherit (minimax.limits) contextWindow maxTokens;
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
