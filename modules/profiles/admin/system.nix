{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.clan.core.vars) generators;
  userName = lib.liberion.identity.user;
  ageKeyFile = generators.admin-age.files.key.path;
in
{
  clan.core.vars.generators = {
    user-ssh = {
      files.id_ed25519.owner = userName;
      files."id_ed25519.pub".secret = false;
      runtimeInputs = [ pkgs.openssh ];
      script = ''
        ssh-keygen -q -t ed25519 -N "" -C "${userName}@${config.clan.core.settings.machine.name}" -f "$out/id_ed25519"
      '';
    };

    admin-age = {
      files.key.owner = userName;
      files."key.pub".secret = false;
      runtimeInputs = [ pkgs.age ];
      script = ''
        age-keygen -o "$out/key" 2>/dev/null
        age-keygen -y "$out/key" > "$out/key.pub"
      '';
    };
  };

  home-manager.users.${userName} = {
    liberion.cli.ssh.identityFile = generators.user-ssh.files.id_ed25519.path;
    home.sessionVariables.SOPS_AGE_KEY_FILE = ageKeyFile;
    systemd.user.sessionVariables = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      SOPS_AGE_KEY_FILE = ageKeyFile;
    };
  };
}
