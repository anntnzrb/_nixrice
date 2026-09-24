let
  liberionKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB45J5N5vAcQlF4kUHN8y12FMOzXhuav7bczaztcZHTq annt@liberion";

  # every machine is reachable over tailscale magicdns as annt@<name>:2222
  hosts = [
    "oulu"
    "munich"
    "solna"
    "tampa"
    "zadar"
    "beirut"
    "incheon"
  ];
in
{
  meta.name = "liberion";
  # tailscale magicdns domain used for inter-machine clan communication
  meta.domain = "trex-gamut.ts.net";

  inventory.machines = {
    oulu = {
      description = "Lenovo V15 G4 IRU - Intel i7-1355U Build Server";
      tags = [
        "physical"
        "workstation"
        "headless"
        "nixos"
      ];
    };
    munich = {
      description = "ASUS PRIME B660-PLUS D4 - Intel i5-12400 & NVIDIA GTX 1080 Pascal";
      tags = [
        "physical"
        "workstation"
        "nvidia"
        "nixos"
      ];
    };
    solna = {
      description = "Laptop Workstation (SSD)";
      tags = [
        "physical"
        "laptop"
        "workstation"
        "nixos"
      ];
    };
    tampa = {
      description = "NixOS-WSL";
      tags = [
        "wsl"
        "nixos"
      ];
    };
    zadar = {
      description = "Laptop Server (HDD / Headless)";
      tags = [
        "physical"
        "laptop"
        "headless"
        "nixos"
      ];
    };
    beirut = {
      description = "Apple M4 MacBook (Primary Mac)";
      machineClass = "darwin";
      tags = [
        "physical"
        "darwin"
        "laptop"
        "workstation"
      ];
    };
    incheon = {
      description = "Apple M1 MacBook (Secondary Mac)";
      machineClass = "darwin";
      tags = [
        "physical"
        "darwin"
        "laptop"
      ];
    };
  };

  inventory.instances = {
    # sshd + users are scoped to machines installed through clan: users sets
    # mutableUsers = false and a generated password, sshd rotates host keys.
    # extend a machine only after `clan vars` exist for it (munich/solna/zadar
    # already have them).
    sshd = {
      roles.server.machines.oulu = { };
      roles.server.settings.authorizedKeys.annt-liberion = liberionKey;
    };

    user-annt = {
      module.name = "users";
      roles.default.machines.oulu = { };
      roles.default.settings = {
        user = "annt";
        prompt = false;
      };
    };

    internet.roles.default.machines = builtins.listToAttrs (
      map (host: {
        name = host;
        value.settings = {
          inherit host;
          user = "annt";
          # openssh; 22 on the tailnet is tailscale ssh (no clan host keys)
          port = 2222;
        };
      }) hosts
    );
  };
}
