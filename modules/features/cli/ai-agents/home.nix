{ lib, ... }: {
  imports = [
    (lib.liberion.gitCheckout {
      name = "ai-agents";
      description = "agents";
      repository = "https://github.com/anntnzrb/agents.git";
      destination = "src/agents";
      branch = "main";
    })
  ];
}
