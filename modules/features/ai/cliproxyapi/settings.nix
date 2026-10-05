{ stateDir }: {
  port = 8317;

  remote-management = {
    allow-remote = true;
    secret-key = "tailnet";
    disable-control-panel = false;
    disable-auto-update-panel = true;
  };

  auth-dir = "${stateDir}/auth";

  debug = false;
  logging-to-file = true;
  logs-max-total-size-mb = 100;
  usage-statistics-enabled = true;
  disable-image-generation = "chat";
  force-model-prefix = true;
  ws-auth = false;

  request-retry = 3;
  max-retry-credentials = 0;
  max-retry-interval = 30;
  disable-cooling = false;
  save-cooldown-status = false;
  transient-error-cooldown-seconds = -1;

  quota-exceeded.antigravity-credits = true;

  nonstream-keepalive-interval = 15;

  streaming = {
    keepalive-seconds = 15;
    bootstrap-retries = 1;
  };

  routing = {
    strategy = "weighted-round-robin";
    session-affinity = true;
    session-affinity-ttl = "1h";
    session-affinity-subagents = true;
  };

  codex = {
    disable-codex-cloaking = false;
    optimize-multi-agent-v2 = true;
    stream-bootstrap-buffering = true;
    model-level-cooling = true;
  };

  claude.model-level-cooling = true;

  antigravity = {
    connection-pool = {
      enabled = true;
    };
    sensitive-words = [
      "system-conventions"
      "system_conventions"
      "system-directive"
      "system_directive"
      "RFC 2119: MUST, REQUIRED, SHOULD, RECOMMENDED, MAY, OPTIONAL."
    ];
  };

  codex-api-key = [
    {
      x-credential-pool = "opencode-go";
      base-url = "https://opencode.ai/zen/go/v1";
      prefix = "opencode-go";
      headers = {
        x-opencode-session = "$CPA-SESSION-ID";
      };
      models = [
        {
          name = "muse-spark-1.2-contributor";
          display-name = "Muse Spark 1.2 Contributor";
          max-context-length = 1048576;
          thinking = {
            levels = [
              "minimal"
              "low"
              "medium"
              "high"
              "xhigh"
            ];
          };
        }
        {
          name = "muse-spark-1.3-contributor";
          display-name = "Muse Spark 1.3 Contributor";
          max-context-length = 1048576;
          thinking = {
            levels = [
              "minimal"
              "low"
              "medium"
              "high"
              "xhigh"
            ];
          };
        }
      ];
    }
  ];

  openai-compatibility = [
    {
      name = "opencode-go-custom";
      base-url = "https://opencode.ai/zen/go/v1";
      prefix = "opencode-go";
      x-credential-pool = "opencode-go";
      support-prompt-cache-key = true;
      headers = {
        x-opencode-session = "$CPA-SESSION-ID";
      };
      x-model-discovery = true;
      x-model-exclude = [
        "muse-spark-1.2-contributor"
        "muse-spark-1.3-contributor"
      ];
    }
    {
      name = "opencode-zen-custom";
      base-url = "https://opencode.ai/zen/v1";
      prefix = "opencode-zen";
      x-credential-pool = "opencode-zen";
      support-prompt-cache-key = true;
      headers = {
        x-opencode-session = "$CPA-SESSION-ID";
      };
      x-model-discovery = true;
    }
    {
      name = "cline-pass-custom";
      base-url = "https://api.cline.bot/api/v1";
      prefix = "cline-pass";
      x-credential-pool = "cline-pass";
      support-prompt-cache-key = true;
      x-model-discovery = true;
    }
    {
      name = "command-code-custom";
      base-url = "https://api.commandcode.ai/provider/v1";
      prefix = "command-code";
      x-credential-pool = "command-code";
      support-prompt-cache-key = true;
      x-model-discovery = true;
    }
    {
      name = "mimo-custom";
      base-url = "https://token-plan-sgp.xiaomimimo.com/v1";
      prefix = "mimo";
      x-credential-pool = "mimo";
      support-prompt-cache-key = true;
      models = [
        {
          name = "mimo-v2.6-flash";
          display-name = "MiMo-V2.6-Flash";
          max-context-length = 1048576;
          thinking = {
            levels = [ "high" ];
          };
        }
        {
          name = "mimo-v2.6-pro";
          display-name = "MiMo-V2.6-Pro";
          max-context-length = 1048576;
          thinking = {
            levels = [ "high" ];
          };
        }
      ];
    }
  ];
}
