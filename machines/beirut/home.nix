{ inputs, ... }: {
  imports = with inputs.self.homeModules; [
    ai-agents
    amp-runner
    ghostty
    whatsapp
  ];

  liberion.cli.ssh.includes = [ "~/.orbstack/ssh/config" ];
}
