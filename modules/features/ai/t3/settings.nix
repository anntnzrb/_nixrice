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
  branchNamingMode = "custom";
  branchNameInstructions = "Follow repository branch-naming rules; otherwise use `work/<8-lowercase-hex>`";
  sourceControlWritingStyle = {
    mode = "repo_conventions";
    followChangeRequestTemplates = true;
  };
  sourceControlWriterModelSelection = null;

  defaultModelSelection = {
    instanceId = "codex";
    model = "gpt-6.1-sol";
    options = [
      {
        id = "reasoningEffort";
        value = "medium";
      }
    ];
  };
  # Titles, branch names, and commit messages. T3 runs Pi's background text
  # with --no-extensions, which drops the cliproxy provider, and it falls back
  # only when this provider is disabled, not when a call fails. Codex reaches
  # the gateway through its own config.
  textGenerationModelSelection = {
    instanceId = "codex";
    model = "gpt-6-luna";
    options = [
      {
        id = "reasoningEffort";
        value = "low";
      }
    ];
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
