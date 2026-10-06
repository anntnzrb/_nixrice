# T3 server settings merged into ~/.t3/userdata/settings.json on every update
# run. Keys not set here keep whatever a client chose. Schema and defaults:
# packages/contracts/src/settings.ts upstream.
let
  disabled = driver: {
    inherit driver;
    enabled = false;
  };
in
{
  defaultThreadEnvMode = "worktree";
  addProjectBaseDirectory = "~/repos";
  defaultAutoPull = true;
  defaultRuntimeMode = "full-access";
  continueThreadsAfterServerUpdate = true;
  # A thread that hits a provider quota pauses instead of failing, then resumes
  # when the quota resets.
  snoozeLimitedThreads = true;
  autoResumeLimitedThreads = true;
  pullRequestMergeMethod = "squash";
  sourceControlWritingStyle.mode = "conventional_commits";

  defaultModelSelection = {
    instanceId = "pi";
    model = "cliproxy/gpt-6.1-sol";
    options = [
      {
        id = "thinking";
        value = "medium";
      }
    ];
  };
  # Background text runs Pi without extensions, so it needs a built-in provider
  # rather than the cliproxy extension.
  textGenerationModelSelection = {
    instanceId = "pi";
    model = "openai-codex/gpt-6.1-sol";
    options = [ ];
  };

  backgroundActivity = {
    profile = "custom";
    baseProfile = "performance";
    overrides.pauseWhenHostLocked = false;
  };

  storageCleanup = {
    worktreeOnMerge = true;
    worktreeOnDelete = true;
    worktreeAfterDays = 30;
    logsAfterDays = 14;
    browserArtifactsAfterDays = 14;
  };

  providerInstances = {
    pi = {
      driver = "pi";
      enabled = true;
    };
    codex = {
      driver = "codex";
      enabled = true;
    };
    claudeAgent = {
      driver = "claudeAgent";
      enabled = true;
    };
    cursor = disabled "cursor";
    grok = disabled "grok";
    opencode = disabled "opencode";
    antigravity = disabled "antigravity";
  };
}
