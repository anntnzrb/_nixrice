{ inputs, ... }: {
  imports = with inputs.self.homeModules; [ whatsapp ];

  liberion.cli.ssh.includes = [ "~/.orbstack/ssh/config" ];
}
