{ inputs, ... }: {
  imports = with inputs.self.homeModules; [
    ai-agents
    amp-runner
    ghostty
    paseo
    ssh
    whatsapp
  ];

  liberion.cli.ssh = {
    identityFile = "~/.ssh/beirut";
    includes = [ "~/.orbstack/ssh/config" ];
  };
}
