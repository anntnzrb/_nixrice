{ inputs, ... }: {
  imports = with inputs.self.homeModules; [
    ghostty
    ssh
    whatsapp
    zsh
  ];

  liberion.cli.ssh = {
    identityFile = "~/.ssh/beirut";
    includes = [ "~/.orbstack/ssh/config" ];
  };
}
