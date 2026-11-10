{ inputs, ... }: {
  imports = with inputs.self.homeModules; [
    amp
    whatsapp
  ];

  liberion.cli.ssh.includes = [ "~/.orbstack/ssh/config" ];
}
