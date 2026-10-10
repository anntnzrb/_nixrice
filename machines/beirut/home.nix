{ inputs, ... }: {
  imports = with inputs.self.homeModules; [
    amp-runner
    whatsapp
  ];

  liberion.cli.ssh.includes = [ "~/.orbstack/ssh/config" ];
}
