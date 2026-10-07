{ inputs, ... }: {
  imports = with inputs.self.homeModules; [
    ai-agents
    amp-runner
    whatsapp
  ];

  liberion.cli.ssh.includes = [ "~/.orbstack/ssh/config" ];
}
