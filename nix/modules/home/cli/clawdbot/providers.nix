{ homeDir }:
let
  minimaxProviderName = "minimax";
  minimaxApiKeyEnv = "MINIMAX_API_KEY";
  minimaxApiKeyRef = "\${MINIMAX_API_KEY}";
  minimaxApi = {
    baseUrl = "https://api.minimax.io/v1";
    transport = "openai-completions";
  };
  minimaxModelId = "MiniMax-M2.1";
  minimaxModelPrimary = "${minimaxProviderName}/${minimaxModelId}";
  minimaxModel = {
    id = minimaxModelId;
    name = "MiniMax M2.1";
    primary = minimaxModelPrimary;
    inputs = [ "text" ];
    reasoning = false;
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
  minimaxKeyFile = "${homeDir}/.secrets/clawdbot-api-key";
in
{
  defaultProvider = minimaxProviderName;
  providers = {
    ${minimaxProviderName} = {
      apiKeyFile = minimaxKeyFile;
      apiKeyEnv = minimaxApiKeyEnv;
      apiKeyRef = minimaxApiKeyRef;
      api = minimaxApi;
      model = minimaxModel;
      limits = minimaxLimits;
      cost = minimaxCost;
    };
  };
}
