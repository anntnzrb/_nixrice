# Machines tagged `archived`: retired, kept as history. Only fleet ssh
# access on top of base; no CI builds (scripts/ci/targets.nix) and no
# ssh peer entry on live machines (network/sshd).
{ inputs, ... }: {
  imports = with inputs.self.nixosModules; [
    sshd
    user
  ];
}
